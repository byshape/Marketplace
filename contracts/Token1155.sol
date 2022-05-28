//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./interfaces/IToken1155.sol";

/// @title ERC1155 contract with mint, burn and setURI functions
/// @author Xenia Shape
/// @notice This contract can be used for only the most basic ERC1155 test experiments
contract Token1155 is AccessControl, ERC1155, IToken1155 {

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(string memory uri_) ERC1155(uri_) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    /// @notice Function for minting tokens to account
    /// @param to Address of the account to mint tokens
    /// @param tokenId Token id for mint
    /// @param amount Amount of tokens to mint
    /// @dev Function does not allow to mint zero tokens
    /// @dev Function does not allow to mint to the zero address
    /// @dev Function emits TransferSingle event
    function mint(address to, uint256 tokenId, uint256 amount) external override onlyRole(MINTER_ROLE) {
        if(amount == 0) revert InvalidData();
        _mint(to, tokenId, amount, "");
    }

    /// @notice Function for burning tokens by the account
    /// @param id The ID of the token to burn
    /// @param amount Amount of tokens to burn
    /// @dev Function does not allow to burn zero tokens
    /// @dev Function does not allow to burn from the zero address
    /// @dev Function does not allow to burn tokens more than balance
    /// @dev Function emits TransferSingle event
    function burn(uint256 id, uint256 amount) external override {
        if(amount == 0) revert InvalidData();
        _burn(msg.sender, id, amount);
    }

    /// @notice Function for setting up the base tokens URI
    /// @param newuri The new base URI
    /// @dev Function does not allow to set up empty URI
    /// @dev Function emits UpdateURI event
    function setURI(string memory newuri) external override onlyRole(DEFAULT_ADMIN_ROLE) {
         // check string not empty
        if(bytes(newuri).length == 0) revert InvalidData();
        _setURI(newuri);

        emit UpdateURI(newuri);
    }

    /// @notice Function for checking interface support
    /// @param interfaceId The ID of the interface to check
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC1155) returns (bool) {
        return
            interfaceId == type(IToken1155).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Function for returning the token's URI
    /// @param _tokenid The ID of the token
    /// @dev Function adds dynamically the token's ID to the base URI
    function uri(uint256 _tokenid) override public view returns (string memory) {
        return string(
            abi.encodePacked(
                super.uri(_tokenid),
                Strings.toString(_tokenid)
            )
        );
    }
}