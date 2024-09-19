// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Web3Token is ERC20("Web3Bridge Cohort XI", "WEB3CXI") {
    address public owner;

    constructor() {
        _mint(msg.sender, 1000000e18);
    }
}
