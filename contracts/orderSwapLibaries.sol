// SPDX-License-Identifier: MIT

pragma solidity 0.8.27;

library OrderSwapError {
    error TokenTransferFailed();
    error InvalidAmount();
    error ZeroAddressDetected();
    error OrderDoesNotExit();
    error InvalidDeadline();
    error DeadlineHasPassed();
    error NotOrderOwner();
}

library OrderSwapEvent {
    event DepositForSwap(string, uint, string, uint, uint);
    event TradeSuccessful(string, uint, string, uint);
    event OrderCancled(string, uint);
}
