//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMarketplaceBase {
    error NotOwner();
    error DoesNotExist();
    error InsufficientBalance();
    error InvalidValue();
    error WrongPeriod();
}