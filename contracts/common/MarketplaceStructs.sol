//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct Listing721 {
    address owner;
    uint256 price;
}

struct ListingAuction721 {
    address owner;
    uint256 price;
    uint256 startTimestamp;
    address lastBidder;
    uint256 bidsCounter;
}

struct Listing1155 {
    uint256 amount;
    address owner;
    uint256 price;
}

struct ListingAuction1155 {
    uint256 amount;
    address owner;
    uint256 price;
    uint256 startTimestamp;
    address lastBidder;
    uint256 bidsCounter;
}
