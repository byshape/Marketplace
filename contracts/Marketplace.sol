//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./Token721.sol";
import "./Token1155.sol";
import "./interfaces/IMarketplace.sol";

/// @title Marketplace contract to sell and buy ERC721 and ERC1155 tokens
/// @author Xenia Shape
/// @notice This contract can be used for only the most basic marketplace test experiments
contract Marketplace is IMarketplace, ERC721Holder, ERC1155Receiver, AccessControl, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;

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
        uint256 id;
        uint256 amount;
        address owner;
        uint256 price;
    }

    struct ListingAuction1155 {
        uint256 id;
        uint256 amount;
        address owner;
        uint256 price;
        uint256 startTimestamp;
        address lastBidder;
        uint256 bidsCounter;
    }

    address public token721;
    address public token1155;
    address public token20;
    uint256 public auctionDuration;

    // tokenId => Listing
    mapping(uint256 => Listing721) internal _listings721;
    // tokenId => ListingAuction
    mapping(uint256 => ListingAuction721) internal _listingsAuction721;

    Counters.Counter internal counter1155;
    // listing id => Listing
    mapping(uint256 => Listing1155) internal _listings1155;
    // listing id => ListingAuction
    mapping(uint256 => ListingAuction1155) internal _listingsAuction1155;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Function for checking interface support
    /// @param interfaceId The ID of the interface to check
    function supportsInterface(bytes4 interfaceId) public view override(ERC1155Receiver, AccessControl) returns (bool) {
        return
            interfaceId == type(IMarketplace).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Function for setting up the marketplace contract
    /// @param token721_ Token721 address
    /// @param token1155_ Token1155 address
    /// @param token20_ ERC20 token address
    /// @param auctionDuration_ Duration of the auction in seconds
    function setUpConfig(
        address token721_,
        address token1155_,
        address token20_,
        uint256 auctionDuration_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        token721 = token721_;
        token1155 = token1155_;
        token20 = token20_;
        auctionDuration = auctionDuration_;
    }

    /// @notice Function for minting token to the caller
    /// @param tokenId Token's id to mint
    /// @dev Function does not allow to mint zero tokens
    /// @dev Function emits Transfer event
    function createItem721(uint256 tokenId) external override {
        IToken721(token721).mint(msg.sender, tokenId);
    }

    /// @notice Function for listing token on the marketplace
    /// @param tokenId Token's id to list
    /// @param price Listing price
    /// @dev Function does not allow to list token by the non-owner
    /// @dev Function emits Transfer and Item721Listed events
    function listItem721(uint256 tokenId, uint256 price) external override {
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
    function cancelItem721(uint256 tokenId) external override {
        if (_listings721[tokenId].owner != msg.sender) revert NotOwner();
        IERC721(token721).safeTransferFrom(address(this), msg.sender, tokenId);
        _listings721[tokenId].owner = address(0);
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

        _listings721[tokenId].owner = address(0);
        
        emit Item721Sold(tokenId, msg.sender, cost);
    }

    /// @notice Function for listing token on the auction
    /// @param tokenId Token's id to list
    /// @param startPrice Listing start price
    /// @dev Function does not allow to list token by the non-owner
    /// @dev Function emits Transfer and Item721ListedAuction events
    function listItemOnAuction721(uint256 tokenId, uint256 startPrice) external override {
        // 1. add to listings
        ListingAuction721 storage listing = _listingsAuction721[tokenId];
        listing.owner = msg.sender;
        listing.price = startPrice;
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
    function makeBid721(uint256 tokenId, uint256 bid) external override {
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

        _listingsAuction721[tokenId].owner = address(0);
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
    function listItem1155(uint256 tokenId, uint256 amount, uint256 price) external override {
        // check if enough tokens
        if (IERC1155(token1155).balanceOf(msg.sender, tokenId) < amount) revert InsufficientBalance();
        // 1. add to listings
        _listings1155[counter1155._value] = Listing1155({id: tokenId, owner: msg.sender, price: price, amount: amount});
        // 2. transferFrom(user, this)
        IERC1155(token1155).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        emit Item1155Listed(counter1155._value, tokenId, price, amount);
        counter1155.increment();
    }

    /// @notice Function for cancelling listing
    /// @param listingId Listing's id to cancel
    /// @param amount Amount to cancel
    /// @dev Function does not allow to cancel listing by the non-owner
    /// @dev Function emits TransferSingle and Item1155Cancelled events
    function cancelItem1155(uint256 listingId, uint256 amount) external override nonReentrant {
        if (_listings1155[listingId].owner != msg.sender) revert NotOwner();
        IERC1155(token1155).safeTransferFrom(address(this), msg.sender, _listings1155[listingId].id, amount, "");
        unchecked {
            _listings1155[listingId].amount -= amount;
        }
        emit Item1155Cancelled(listingId, amount);
    }

    /// @notice Function for buying listing
    /// @param listingId Token's id to buy
    /// @param amount Amount to buy
    /// @dev Function does not allow to buy non-existent listing
    /// @dev Function does not allow to buy listing if unsufficient funds
    /// @dev Function emits Transfer, TransferSingle and Item1155Sold events
    function buylItem1155(uint256 listingId, uint256 amount) external override nonReentrant {
        if (_listings1155[listingId].owner == address(0)) revert DoesNotExist();
        uint256 cost = _listings1155[listingId].price * amount;
        if(IERC20(token20).balanceOf(msg.sender) < cost) revert InsufficientBalance();
        
        IERC20(token20).safeTransferFrom(msg.sender, _listings1155[listingId].owner, cost);
        IERC1155(token1155).safeTransferFrom(address(this), msg.sender, _listings1155[listingId].id, amount, "");
        if (amount > _listings1155[listingId].amount) revert InvalidValue();
        unchecked {
            _listings1155[listingId].amount -= amount;
        }
        emit Item1155Sold(listingId, amount, msg.sender, cost);
    }

    /// @notice Function for listing token on the auction
    /// @param tokenId Token's id to list
    /// @param startPrice Listing start price
    /// @param amount Amount to list
    /// @dev Function does not allow to list tokens more than balance
    /// @dev Function emits TransferSingle and Item1155ListedAuction events
    function listItemOnAuction1155(uint256 tokenId, uint256 startPrice, uint256 amount) external override {
        // check if enough tokens
        if (IERC1155(token1155).balanceOf(msg.sender, tokenId) < amount) revert InsufficientBalance();
        // 1. add to listings
        ListingAuction1155 storage listing = _listingsAuction1155[counter1155._value];
        listing.id = tokenId;
        listing.owner = msg.sender;
        listing.price = startPrice * amount;
        listing.amount = amount;
        // 2. transferFrom(user, this)
        IERC1155(token1155).safeTransferFrom(msg.sender, address(this), tokenId, amount, "");
        emit Item1155ListedAuction(counter1155._value, tokenId, startPrice, amount);
        counter1155.increment();
    }

    /// @notice Function for bidding on listing
    /// @param listingId Token's id to bid
    /// @param bid Amount to bid
    /// @dev Function does not allow to bid after auction ends
    /// @dev Function does not allow to bid non-existent listing
    /// @dev Function does not allow to bid if unsufficient funds
    /// @dev Function does not allow to bid less or equal previous bid or start price
    /// @dev Function returns bid to the previos bidder
    /// @dev Function emits Transfer and Item1155BiddedAuction events
    function makeBid1155(uint256 listingId, uint256 bid) external override {
        ListingAuction1155 memory listing = _listingsAuction1155[listingId];

        /* solhint-disable not-rely-on-time*/
        if (listing.startTimestamp == 0) {
            _listingsAuction1155[listingId].startTimestamp = block.timestamp;
        } else if (block.timestamp - listing.startTimestamp >= auctionDuration) revert WrongPeriod();
        /* solhint-enable not-rely-on-time*/

        if (listing.owner == address(0)) revert DoesNotExist();
        uint256 previousBid = listing.price;
        if (bid <= previousBid) revert InvalidValue();
        if(IERC20(token20).balanceOf(msg.sender) < bid) revert InsufficientBalance();
        
        _listingsAuction1155[listingId].price = bid;
        IERC20(token20).safeTransferFrom(msg.sender, address(this), bid);

        address previousBidder = listing.lastBidder;
        _listingsAuction1155[listingId].lastBidder = msg.sender;
        _listingsAuction1155[listingId].bidsCounter++;

        if (previousBidder != address(0)) {
            IERC20(token20).safeTransfer(previousBidder,  previousBid);
        }
        
        emit Item1155BiddedAuction(listingId, msg.sender, bid);
    }

    /// @notice Function for finishing auction
    /// @param listingId Token's id to finish
    /// @dev Function does not allow to finisg before auction ends
    /// @dev Function does not allow to bid non-existent listing
    /// @dev Auction is successful if there are more than two bids
    /// @dev In this case, function sends the token to the last bidder
    /// @dev Otherwise, token returns to the owner and it returns bid to the last bidder
    /// @dev Function emits Transfer, TransferSingle and Item1155FinishedAuction events
    function finishAuction1155(uint256 listingId) external override nonReentrant {
        ListingAuction1155 memory listing =  _listingsAuction1155[listingId];

        if (listing.owner == address(0)) revert DoesNotExist();

        // solhint-disable-next-line not-rely-on-time
        if (block.timestamp - listing.startTimestamp < auctionDuration) revert WrongPeriod();
        if (listing.bidsCounter <= 2) {
            IERC1155(token1155).safeTransferFrom(address(this), listing.owner, _listingsAuction1155[listingId].id, listing.amount, "");
            emit Item1155FinishedAuction(listingId, listing.owner, listing.price);
        } else {
            IERC1155(token1155).safeTransferFrom(address(this), listing.lastBidder, _listingsAuction1155[listingId].id, listing.amount, "");
            IERC20(token20).safeTransfer(listing.owner, listing.price);
            emit Item1155FinishedAuction(listingId, listing.lastBidder, listing.price);
        }

        _listingsAuction1155[listingId].owner = address(0);
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