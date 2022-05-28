//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "./interfaces/IMarketplace721.sol";

import "./Token721.sol";
import "./common/MarketplaceStructs.sol";
import "./common/MarketplaceBase.sol";

/// @title Marketplace contract to sell and buy ERC721 tokens
/// @author Xenia Shape
/// @notice This contract can be used for only the most basic marketplace test experiments
contract Marketplace721 is ERC721Holder, IMarketplace721, MarketplaceBase, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // tokenId => Listing
    mapping(uint256 => Listing721) internal _listings721;
    // tokenId => ListingAuction
    mapping(uint256 => ListingAuction721) internal _listingsAuction721;

    /// @notice Function for minting token to the caller
    /// @param tokenId Token's id to mint
    /// @dev Function does not allow to mint zero tokens
    /// @dev Function emits Transfer event
    function createItem721(uint256 tokenId) external override nonReentrant {
        IToken721(token721).mint(msg.sender, tokenId);
    }

    /// @notice Function for listing token on the marketplace
    /// @param tokenId Token's id to list
    /// @param price Listing price
    /// @dev Function does not allow to list token by the non-owner
    /// @dev Function emits Transfer and Item721Listed events
    function listItem721(uint256 tokenId, uint256 price) external override nonReentrant {
        // check owner
        if (IERC721(token721).ownerOf(tokenId) != msg.sender) revert NotOwner();
        // 1. add to listings
        _listings721[tokenId] = Listing721({owner: msg.sender, price: price});
        // 2. transferFrom(user, this)
        IERC721(token721).safeTransferFrom(msg.sender, address(this), tokenId);
        emit Item721Listed(tokenId, price);
    }

    /// @notice Function for cancelling listing
    /// @param tokenId Token's id to cancel
    /// @dev Function does not allow to cancel listing by the non-owner
    /// @dev Function emits Transfer and Item721Cancelled events
    function cancelItem721(uint256 tokenId) external override  nonReentrant{
        if (_listings721[tokenId].owner != msg.sender) revert NotOwner();
        IERC721(token721).safeTransferFrom(address(this), msg.sender, tokenId);
        delete _listings721[tokenId];
        emit Item721Cancelled(tokenId);
    }

    /// @notice Function for buying listing
    /// @param tokenId Token's id to buy
    /// @dev Function does not allow to buy non-existent listing
    /// @dev Function does not allow to buy listing if unsufficient funds
    /// @dev Function emits Transfer and Item721Sold events
    function buylItem721(uint256 tokenId) external override nonReentrant {
        if (_listings721[tokenId].owner == address(0)) revert DoesNotExist();
        uint256 cost = _listings721[tokenId].price;
        if(IERC20(token20).balanceOf(msg.sender) < cost) revert InsufficientBalance();
        
        IERC20(token20).safeTransferFrom(msg.sender, _listings721[tokenId].owner, cost);
        IERC721(token721).safeTransferFrom(address(this), msg.sender, tokenId);
        delete _listings721[tokenId];
        emit Item721Sold(tokenId, msg.sender, cost);
    }

    /// @notice Function for listing token on the auction
    /// @param tokenId Token's id to list
    /// @param startPrice Listing start price
    /// @dev Function does not allow to list token by the non-owner
    /// @dev Function emits Transfer and Item721ListedAuction events
    function listItemOnAuction721(uint256 tokenId, uint256 startPrice) external override nonReentrant {
        // check owner
        if (IERC721(token721).ownerOf(tokenId) != msg.sender) revert NotOwner();
        // 1. add to listings
        ListingAuction721 memory listing;
        listing.owner = msg.sender;
        listing.price = startPrice;
        _listingsAuction721[tokenId] = listing;
        // 2. transferFrom(user, this)
        IERC721(token721).safeTransferFrom(msg.sender, address(this), tokenId);
        emit Item721ListedAuction(tokenId, startPrice);
    }

    /// @notice Function for bidding on listing
    /// @param tokenId Token's id to bid
    /// @param bid Amount to bid
    /// @dev Function does not allow to bid after auction ends
    /// @dev Function does not allow to bid non-existent listing
    /// @dev Function does not allow to bid if unsufficient funds
    /// @dev Function does not allow to bid less or equal previous bid or start price
    /// @dev Function returns bid to the previos bidder
    /// @dev Function emits Transfer and Item721BiddedAuction events
    function makeBid721(uint256 tokenId, uint256 bid) external override nonReentrant {
        ListingAuction721 memory listing = _listingsAuction721[tokenId];

        /* solhint-disable not-rely-on-time*/
        if (listing.startTimestamp == 0) {
            _listingsAuction721[tokenId].startTimestamp = block.timestamp;
        } else if (block.timestamp - listing.startTimestamp >= auctionDuration) revert WrongPeriod();
        /* solhint-enable not-rely-on-time*/

        if (listing.owner == address(0)) revert DoesNotExist();
        uint256 previousBid = listing.price;
        if (bid <= previousBid) revert InvalidValue();
        if(IERC20(token20).balanceOf(msg.sender) < bid) revert InsufficientBalance();
        
        _listingsAuction721[tokenId].price = bid;
        IERC20(token20).safeTransferFrom(msg.sender, address(this), bid);

        address previousBidder = listing.lastBidder;
        _listingsAuction721[tokenId].lastBidder = msg.sender;
        _listingsAuction721[tokenId].bidsCounter++;

        if (previousBidder != address(0)) {
            IERC20(token20).safeTransfer(previousBidder,  previousBid);
        }
        
        emit Item721BiddedAuction(tokenId, msg.sender, bid);
    }

    /// @notice Function for finishing auction
    /// @param tokenId Token's id to finish
    /// @dev Function does not allow to finisg before auction ends
    /// @dev Function does not allow to bid non-existent listing
    /// @dev Auction is successful if there are more than two bids
    /// @dev In this case, function sends the token to the last bidder
    /// @dev Otherwise, token returns to the owner and it returns bid to the last bidder
    /// @dev Function emits Transfer and Item721FinishedAuction events
    function finishAuction721(uint256 tokenId) external override nonReentrant {
        ListingAuction721 memory listing =  _listingsAuction721[tokenId];

        if (listing.owner == address(0)) revert DoesNotExist();

        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp - listing.startTimestamp < auctionDuration) revert WrongPeriod();
        if (listing.bidsCounter <= 2) {
            IERC721(token721).safeTransferFrom(address(this), listing.owner, tokenId);
            emit Item721FinishedAuction(tokenId, listing.owner, listing.price);
        } else {
            IERC721(token721).safeTransferFrom(address(this), listing.lastBidder, tokenId);
            IERC20(token20).safeTransfer(listing.owner, listing.price);
            emit Item721FinishedAuction(tokenId, listing.lastBidder, listing.price);
        }

        delete _listingsAuction721[tokenId];
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}