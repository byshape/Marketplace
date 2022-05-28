//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IMarketplace.sol";

import "./Marketplace721.sol";
import "./Marketplace1155.sol";

/// @title Marketplace contract to sell and buy ERC721 and ERC1155 tokens
/// @author Xenia Shape
/// @notice This contract can be used for only the most basic marketplace test experiments
contract Marketplace is IMarketplace, Marketplace1155, Marketplace721, AccessControl {

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Function for checking interface support
    /// @param interfaceId The ID of the interface to check
    function supportsInterface(bytes4 interfaceId) public view override(ERC1155Receiver, AccessControl) returns (bool) {
        return
            interfaceId == type(IMarketplace).interfaceId ||
            interfaceId == type(IMarketplace1155).interfaceId ||
            interfaceId == type(IMarketplace721).interfaceId ||
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
}