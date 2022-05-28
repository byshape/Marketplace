//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IMarketplaceBase.sol";

interface IMarketplace1155 is IMarketplaceBase {
    /// @dev Emits when item is listed on the marletplace
    event Item1155Listed(uint256 indexed tokenId, uint256 price, uint256 amount);

    /// @dev Emits when item is listed on the auction
    event Item1155ListedAuction(uint256 indexed tokenId, uint256 price, uint256 amount);

    /// @dev Emits when the listing is cancelled
    event Item1155Cancelled(uint256 indexed tokenId, uint256 amount);

    /// @dev Emits when item is bought
    event Item1155Sold(uint256 indexed tokenId, uint256 amount, address indexed buyer, uint256 price);

    /// @dev Emits when bid is made
    event Item1155BiddedAuction(uint256 indexed tokenId, address indexed bidder, uint256 bid);

    /// @dev Emits when auction is finished
    event Item1155FinishedAuction(uint256 indexed tokenId, address indexed owner, uint256 price);

    /// @notice Function for minting token to the caller
    /// @param tokenId Token's id to mint
    /// @param amount Amount to mint
    /// @dev Function does not allow to mint zero tokens
    /// @dev Function does not allow to mint to the zero address
    /// @dev Function emits TransferSingle event
    function createItem1155(uint256 tokenId, uint256 amount) external;

    /// @notice Function for listing token on the marketplace
    /// @param tokenId Token's id to list
    /// @param amount Amount to list
    /// @param price Listing price per item
    /// @dev Function does not allow to list tokens more than balance
    /// @dev Function emits TransferSingle and Item1155Listed events
    function listItem1155(uint256 tokenId, uint256 amount, uint256 price) external;

    /// @notice Function for cancelling listing
    /// @param tokenId Token's id to cancel
    /// @param amount Amount to cancel
    /// @dev Function does not allow to cancel listing by the non-owner
    /// @dev Function emits TransferSingle and Item1155Cancelled events
    function cancelItem1155(uint256 tokenId, uint256 amount) external;

    /// @notice Function for buying listing
    /// @param tokenId Token's id to buy
    /// @param amount Amount to buy
    /// @dev Function does not allow to buy non-existent listing
    /// @dev Function does not allow to buy listing if unsufficient funds
    /// @dev Function emits Transfer, TransferSingle and Item1155Sold events
    function buylItem1155(uint256 tokenId, uint256 amount) external;

    /// @notice Function for listing token on the auction
    /// @param tokenId Token's id to list
    /// @param startPrice Listing start price
    /// @param amount Amount to list
    /// @dev Function does not allow to list tokens more than balance
    /// @dev Function emits TransferSingle and Item1155ListedAuction events
    function listItemOnAuction1155(uint256 tokenId, uint256 startPrice, uint256 amount) external;

    /// @notice Function for bidding on listing
    /// @param tokenId Token's id to bid
    /// @param bid Amount to bid
    /// @dev Function does not allow to bid after auction ends
    /// @dev Function does not allow to bid non-existent listing
    /// @dev Function does not allow to bid if unsufficient funds
    /// @dev Function does not allow to bid less or equal previous bid or start price
    /// @dev Function returns bid to the previos bidder
    /// @dev Function emits Transfer and Item1155BiddedAuction events
    function makeBid1155(uint256 tokenId, uint256 bid) external;

    /// @notice Function for finishing auction
    /// @param tokenId Token's id to finish
    /// @dev Function does not allow to finisg before auction ends
    /// @dev Function does not allow to bid non-existent listing
    /// @dev Auction is successful if there are more than two bids
    /// @dev In this case, function sends the token to the last bidder
    /// @dev Otherwise, token returns to the owner and it returns bid to the last bidder
    /// @dev Function emits Transfer, TransferSingle and Item1155FinishedAuction events
    function finishAuction1155(uint256 tokenId) external;
}