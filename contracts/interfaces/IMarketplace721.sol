//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IMarketplaceBase.sol";

interface IMarketplace721 is IMarketplaceBase {
    /// @dev Emits when item is listed on the marletplace
    event Item721Listed(uint256 indexed tokenId, uint256 price);

    /// @dev Emits when item is listed on the auction
    event Item721ListedAuction(uint256 indexed tokenId, uint256 price);

    /// @dev Emits when the listing is cancelled
    event Item721Cancelled(uint256 indexed tokenId);

    /// @dev Emits when item is bought
    event Item721Sold(uint256 indexed tokenId, address indexed buyer, uint256 price);

    /// @dev Emits when bid is made
    event Item721BiddedAuction(uint256 indexed tokenId, address indexed bidder, uint256 bid);

    /// @dev Emits when auction is finished
    event Item721FinishedAuction(uint256 indexed tokenId, address indexed owner, uint256 price);

    /// @notice Function for minting token to the caller
    /// @param tokenId Token's id to mint
    /// @dev Function does not allow to mint zero tokens
    /// @dev Function emits Transfer event
    function createItem721(uint256 tokenId) external;

    /// @notice Function for listing token on the marketplace
    /// @param tokenId Token's id to list
    /// @param price Listing price
    /// @dev Function does not allow to list token by the non-owner
    /// @dev Function emits Transfer and Item721Listed events
    function listItem721(uint256 tokenId, uint256 price) external;

    /// @notice Function for listing token on the auction
    /// @param tokenId Token's id to list
    /// @param startPrice Listing start price
    /// @dev Function does not allow to list token by the non-owner
    /// @dev Function emits Transfer and Item721ListedAuction events
    function listItemOnAuction721(uint256 tokenId, uint256 startPrice) external;

    /// @notice Function for cancelling listing
    /// @param tokenId Token's id to cancel
    /// @dev Function does not allow to cancel listing by the non-owner
    /// @dev Function emits Transfer and Item721Cancelled events
    function cancelItem721(uint256 tokenId) external;

    /// @notice Function for buying listing
    /// @param tokenId Token's id to buy
    /// @dev Function does not allow to buy non-existent listing
    /// @dev Function does not allow to buy listing if unsufficient funds
    /// @dev Function emits Transfer and Item721Sold events
    function buylItem721(uint256 tokenId) external;

    /// @notice Function for bidding on listing
    /// @param tokenId Token's id to bid
    /// @param bid Amount to bid
    /// @dev Function does not allow to bid after auction ends
    /// @dev Function does not allow to bid non-existent listing
    /// @dev Function does not allow to bid if unsufficient funds
    /// @dev Function does not allow to bid less or equal previous bid or start price
    /// @dev Function returns bid to the previos bidder
    /// @dev Function emits Transfer and Item721BiddedAuction events
    function makeBid721(uint256 tokenId, uint256 bid) external;

    /// @notice Function for finishing auction
    /// @param tokenId Token's id to finish
    /// @dev Function does not allow to finisg before auction ends
    /// @dev Function does not allow to bid non-existent listing
    /// @dev Auction is successful if there are more than two bids
    /// @dev In this case, function sends the token to the last bidder
    /// @dev Otherwise, token returns to the owner and it returns bid to the last bidder
    /// @dev Function emits Transfer and Item721FinishedAuction events
    function finishAuction721(uint256 tokenId) external;
}