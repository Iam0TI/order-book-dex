// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

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
    error TokenTransferFailed();
    error InvalidAmount();
    error ZeroAddressDetected();
    error OrderDoesNotExit();
    error InvalidDeadline();
    error DeadlineHasPassed();
    error NotOrderOwner();

    event DepositForSwap(string, uint, string, uint, uint);
    event TradeSuccessful(string, uint, string, uint);
    event UserWithdrawFunds(string, uint);

    struct UserOrder {
        address userAddress;
        address tokenAAddress;
        address tokenBAddress;
        uint256 tokenAAmount;
        uint256 tokenBAmount;
        uint256 deadline;
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
        require(msg.sender != address(0), ZeroAddressDetected());

        require(_tokenAAddress != address(0), ZeroAddressDetected());

        require(_tokenBAddress != address(0), ZeroAddressDetected());

        require(_tokenAAmount > 0, InvalidAmount());

        require(_tokenBAmount > 0, InvalidAmount());

        require(_deadline > block.timestamp + 10 minutes, InvalidDeadline());
        bool success = IERC20(_tokenAAddress).transferFrom(
            msg.sender,
            address(this),
            _tokenAAmount
        );

        require(success, TokenTransferFailed());
        orders[_tokenBAddress] = UserOrder(
            msg.sender,
            _tokenAAddress,
            _tokenBAddress,
            _tokenAAmount,
            _tokenBAmount,
            _deadline
        );

        orderCounts = orderCounts + 1;
        emit DepositForSwap(
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
            OrderDoesNotExit()
        );
        require(
            orders[_tokenBAddress].deadline < block.timestamp,
            DeadlineHasPassed()
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

        require(success, TokenTransferFailed());

        success = IERC20(tokenAAddress).transferFrom(
            address(this),
            msg.sender,
            tokenAAmount
        );

        require(success, TokenTransferFailed());

        emit TradeSuccessful(
            IERC20(_tokenBAddress).symbol(),
            tokenBAmount,
            IERC20(tokenAAddress).symbol(),
            tokenAAmount
        );
    }

    function UserWithdraw(address _tokenBAddress) external {
        require(msg.sender != address(0), ZeroAddressDetected());
        require(
            orders[_tokenBAddress].userAddress == msg.sender,
            NotOrderOwner()
        );
        require(
            orders[_tokenBAddress].deadline < block.timestamp,
            DeadlineHasPassed()
        );

        address tokenAAddress = orders[_tokenBAddress].tokenAAddress;
        uint256 tokenAAmount = orders[_tokenBAddress].tokenAAmount;
        delete orders[_tokenBAddress];

        bool success = IERC20(tokenAAddress).transferFrom(
            address(this),
            msg.sender,
            tokenAAmount
        );
        require(success, TokenTransferFailed());

        emit UserWithdrawFunds(IERC20(tokenAAddress).symbol(), tokenAAmount);
    }
}
