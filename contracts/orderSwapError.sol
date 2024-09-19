// SPDX-License-Identifier: MIT

pragma solidity 0.8.27;

contract OrderSwapError {
    error TokenTransferFailed();
    error InvalidAmount();
    error ZeroAddressDetected();
    error OrderDoesNotExit();
    error InvalidDeadline();
    error DeadlineHasPassed();
    error NotOrderOwner();
}
