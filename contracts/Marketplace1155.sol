//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";

import "./interfaces/IMarketplace1155.sol";

import "./Token1155.sol";
import "./common/MarketplaceStructs.sol";
import "./common/MarketplaceBase.sol";

/// @title Marketplace contract to sell and buy ERC1155 tokens
/// @author Xenia Shape
/// @notice This contract can be used for only the most basic marketplace test experiments
contract Marketplace1155 is ERC1155Receiver, IMarketplace1155, MarketplaceBase, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // tokenId => Listing
    mapping(uint256 => Listing1155) internal _listings1155;
    // tokenId => ListingAuction
    mapping(uint256 => ListingAuction1155) internal _listingsAuction1155;

    /// @notice Function for minting token to the caller
    /// @param tokenId Token's id to mint
    /// @param amount Amount to mint
    /// @dev Function does not allow to mint zero tokens
    /// @dev Function does not allow to mint to the zero address
    /// @dev Function emits TransferSingle event
    function createItem1155(uint256 tokenId, uint256 amount) external override nonReentrant {
        IToken1155(token1155).mint(msg.sender, tokenId, amount);
    }

    /// @notice Function for listing token on the marketplace
    /// @param tokenId Token's id to list
    /// @param amount Amount to list
    /// @param price Listing price per item
    /// @dev Function does not allow to list tokens more than balance
    /// @dev Function emits TransferSingle and Item1155Listed events
    function listItem1155(uint256 tokenId, uint256 amount, uint256 price) external override nonReentrant {
        // check if enough tokens
        if (IERC1155(token1155).balanceOf(msg.sender, tokenId) < amount) revert InsufficientBalance();
        // 1. add to listings
        _listings1155[tokenId] = Listing1155({owner: msg.sender, price: price, amount: amount});
        // 2. transferFrom(user, this)
        IERC1155(token1155).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        emit Item1155Listed(tokenId, price, amount);
    }

    /// @notice Function for cancelling listing
    /// @param tokenId Token's id to cancel
    /// @param amount Amount to cancel
    /// @dev Function does not allow to cancel listing by the non-owner
    /// @dev Function emits TransferSingle and Item1155Cancelled events
    function cancelItem1155(uint256 tokenId, uint256 amount) external override nonReentrant {
        if (_listings1155[tokenId].owner != msg.sender) revert NotOwner();
        IERC1155(token1155).safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
        _listings1155[tokenId].amount -= amount;
        emit Item1155Cancelled(tokenId, amount);
    }

    /// @notice Function for buying listing
    /// @param tokenId Token's id to buy
    /// @param amount Amount to buy
    /// @dev Function does not allow to buy non-existent listing
    /// @dev Function does not allow to buy listing if unsufficient funds
    /// @dev Function emits Transfer, TransferSingle and Item1155Sold events
    function buylItem1155(uint256 tokenId, uint256 amount) external override nonReentrant {
        if (_listings1155[tokenId].owner == address(0)) revert DoesNotExist();
        uint256 cost = _listings1155[tokenId].price * amount;
        if(IERC20(token20).balanceOf(msg.sender) < cost) revert InsufficientBalance();
        
        IERC20(token20).safeTransferFrom(msg.sender, _listings1155[tokenId].owner, cost);
        IERC1155(token1155).safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
        _listings1155[tokenId].amount -= amount;
        emit Item1155Sold(tokenId, amount, msg.sender, cost);
    }

    /// @notice Function for listing token on the auction
    /// @param tokenId Token's id to list
    /// @param startPrice Listing start price
    /// @param amount Amount to list
    /// @dev Function does not allow to list tokens more than balance
    /// @dev Function emits TransferSingle and Item1155ListedAuction events
    function listItemOnAuction1155(uint256 tokenId, uint256 startPrice, uint256 amount) external override nonReentrant {
        // check if enough tokens
        if (IERC1155(token1155).balanceOf(msg.sender, tokenId) < amount) revert InsufficientBalance();
        // 1. add to listings
        ListingAuction1155 memory listing;
        listing.owner = msg.sender;
        listing.price = startPrice * amount;
        listing.amount = amount;
        _listingsAuction1155[tokenId] = listing;
        // 2. transferFrom(user, this)
        IERC1155(token1155).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        emit Item1155ListedAuction(tokenId, startPrice, amount);
    }

    /// @notice Function for bidding on listing
    /// @param tokenId Token's id to bid
    /// @param bid Amount to bid
    /// @dev Function does not allow to bid after auction ends
    /// @dev Function does not allow to bid non-existent listing
    /// @dev Function does not allow to bid if unsufficient funds
    /// @dev Function does not allow to bid less or equal previous bid or start price
    /// @dev Function returns bid to the previos bidder
    /// @dev Function emits Transfer and Item1155BiddedAuction events
    function makeBid1155(uint256 tokenId, uint256 bid) external override nonReentrant {
        ListingAuction1155 memory listing = _listingsAuction1155[tokenId];

        /* solhint-disable not-rely-on-time*/
        if (listing.startTimestamp == 0) {
            _listingsAuction1155[tokenId].startTimestamp = block.timestamp;
        } else if (block.timestamp - listing.startTimestamp >= auctionDuration) revert WrongPeriod();
        /* solhint-enable not-rely-on-time*/

        if (listing.owner == address(0)) revert DoesNotExist();
        uint256 previousBid = listing.price;
        if (bid <= previousBid) revert InvalidValue();
        if(IERC20(token20).balanceOf(msg.sender) < bid) revert InsufficientBalance();
        
        _listingsAuction1155[tokenId].price = bid;
        IERC20(token20).safeTransferFrom(msg.sender, address(this), bid);

        address previousBidder = listing.lastBidder;
        _listingsAuction1155[tokenId].lastBidder = msg.sender;
        _listingsAuction1155[tokenId].bidsCounter++;

        if (previousBidder != address(0)) {
            IERC20(token20).safeTransfer(previousBidder,  previousBid);
        }
        
        emit Item1155BiddedAuction(tokenId, msg.sender, bid);
    }

    /// @notice Function for finishing auction
    /// @param tokenId Token's id to finish
    /// @dev Function does not allow to finisg before auction ends
    /// @dev Function does not allow to bid non-existent listing
    /// @dev Auction is successful if there are more than two bids
    /// @dev In this case, function sends the token to the last bidder
    /// @dev Otherwise, token returns to the owner and it returns bid to the last bidder
    /// @dev Function emits Transfer, TransferSingle and Item1155FinishedAuction events
    function finishAuction1155(uint256 tokenId) external override nonReentrant {
        ListingAuction1155 memory listing =  _listingsAuction1155[tokenId];

        if (listing.owner == address(0)) revert DoesNotExist();

        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp - listing.startTimestamp < auctionDuration) revert WrongPeriod();
        if (listing.bidsCounter <= 2) {
            IERC1155(token1155).safeTransferFrom(address(this), listing.owner, tokenId, listing.amount, "");
            emit Item1155FinishedAuction(tokenId, listing.owner, listing.price);
        } else {
            IERC1155(token1155).safeTransferFrom(address(this), listing.lastBidder, tokenId, listing.amount, "");
            IERC20(token20).safeTransfer(listing.owner, listing.price);
            emit Item1155FinishedAuction(tokenId, listing.lastBidder, listing.price);
        }

        delete _listingsAuction1155[tokenId];
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}