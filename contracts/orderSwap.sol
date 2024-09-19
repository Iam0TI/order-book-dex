// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {OrderSwapError, OrderSwapEvent} from "./orderSwapLibaries.sol";
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
    function symbol() external view returns (string memory);
}

contract OrderSwap {
    // this limitation are due to time contraint
    //Single Order per Token: The contract only allows one active order per token B address.
    //This limits the number of concurrent orders for the same token pair.
    // No Partial Fills: Orders must be filled completely. There's no support for partial order execution.
    // Fixed Exchange Rate: Once an order is created, the exchange rate cannot be modified. Users must create a new order to change the rate.
    // No Order Cancellation: Users cannot cancel an order before the deadline. They must wait for the deadline to pass to withdraw their funds.

    // enum Status {
    //     Pending,
    //     Filled,
    //     Canceled
    // }
    struct UserOrder {
        address userAddress;
        address tokenAAddress;
        address tokenBAddress;
        uint256 tokenAAmount;
        uint256 tokenBAmount;
        uint256 deadline;
        bool active;
    }

    // mapping of token B to user order
    mapping(address => UserOrder) orders;

    // total order  p
    uint256 orderCounts;

    function deposit(
        address _tokenAAddress,
        address _tokenBAddress,
        uint256 _tokenAAmount,
        uint256 _tokenBAmount,
        uint256 _deadline
    ) external {
        // returns (address, uint256)
        require(msg.sender != address(0), OrderSwapError.ZeroAddressDetected());

        require(
            _tokenAAddress != address(0),
            OrderSwapError.ZeroAddressDetected()
        );

        require(
            _tokenBAddress != address(0),
            OrderSwapError.ZeroAddressDetected()
        );

        require(_tokenAAmount > 0, OrderSwapError.InvalidAmount());

        require(_tokenBAmount > 0, OrderSwapError.InvalidAmount());

        require(
            _deadline > block.timestamp + 10 minutes,
            OrderSwapError.InvalidDeadline()
        );
        bool success = IERC20(_tokenAAddress).transferFrom(
            msg.sender,
            address(this),
            _tokenAAmount
        );

        require(success, OrderSwapError.TokenTransferFailed());
        orders[_tokenBAddress] = UserOrder(
            msg.sender,
            _tokenAAddress,
            _tokenBAddress,
            _tokenAAmount,
            _tokenBAmount,
            _deadline,
            true
        );

        orderCounts = orderCounts + 1;
        emit OrderSwapEvent.DepositForSwap(
            IERC20(_tokenAAddress).symbol(),
            _tokenAAmount,
            IERC20(_tokenBAddress).symbol(),
            _tokenBAmount,
            _deadline
        );
    }

    function trade(address _tokenBAddress) external {
        require(
            orders[_tokenBAddress].userAddress != address(0),
            OrderSwapError.OrderDoesNotExit()
        );
        require(
            orders[_tokenBAddress].deadline > block.timestamp,
            OrderSwapError.DeadlineHasPassed()
        );

        address userAddress = orders[_tokenBAddress].userAddress;
        address tokenAAddress = orders[_tokenBAddress].tokenAAddress;
        uint256 tokenBAmount = orders[_tokenBAddress].tokenBAmount;
        uint256 tokenAAmount = orders[_tokenBAddress].tokenAAmount;

        delete orders[_tokenBAddress];
        bool success = IERC20(_tokenBAddress).transferFrom(
            msg.sender,
            userAddress,
            tokenBAmount
        );

        require(success, OrderSwapError.TokenTransferFailed());

        success = IERC20(tokenAAddress).transfer(msg.sender, tokenAAmount);

        require(success, OrderSwapError.TokenTransferFailed());

        emit OrderSwapEvent.TradeSuccessful(
            IERC20(_tokenBAddress).symbol(),
            tokenBAmount,
            IERC20(tokenAAddress).symbol(),
            tokenAAmount
        );
    }

    function cancle(address _tokenBAddress) external {
        require(msg.sender != address(0), OrderSwapError.ZeroAddressDetected());
        require(orders[_tokenBAddress].active == true);
        require(
            orders[_tokenBAddress].userAddress == msg.sender,
            OrderSwapError.NotOrderOwner()
        );

        address tokenAAddress = orders[_tokenBAddress].tokenAAddress;
        uint256 tokenAAmount = orders[_tokenBAddress].tokenAAmount;
        delete orders[_tokenBAddress];

        bool success = IERC20(tokenAAddress).transferFrom(
            address(this),
            msg.sender,
            tokenAAmount
        );
        require(success, OrderSwapError.TokenTransferFailed());

        emit OrderSwapEvent.OrderCancled(
            IERC20(tokenAAddress).symbol(),
            tokenAAmount
        );
    }
}
