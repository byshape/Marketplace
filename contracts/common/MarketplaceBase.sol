//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Base contract to store addresses of tokens and auction ducration
/// @author Xenia Shape
contract MarketplaceBase {
    address public token721;
    address public token1155;
    address public token20;

    uint256 public auctionDuration;
}