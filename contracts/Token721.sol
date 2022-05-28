//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

import "./interfaces/IToken721.sol";

/// @title ERC721 contract with mint, burn and setTokenURI functions
/// @author Xenia Shape
/// @notice This contract can be used for only the most basic ERC721 test experiments
contract Token721 is AccessControl, ERC721, IToken721 {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    string private _uri;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    /// @notice Function for minting tokens to account
    /// @param to Address of the account to mint tokens
    /// @param tokenId Token id for mint
    /// @dev Function does not allow to mint zero tokens
    /// @dev Function emits Transfer event
    function mint(address to, uint256 tokenId) external override onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenId);
    }

    /// @notice Function for burning tokens by the account
    /// @param tokenId The ID of the token to burn
    /// @dev Function does not allow to burn non-existent token
    /// @dev Function does not allow to burn not owned or approved tokens
    /// @dev Function emits Transfer and Approval events
    function burn(uint256 tokenId) external override{
        // check that token exists
        if (!_exists(tokenId)) revert DoesNotExist();
        // check that it is token's owner
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotAuthorized();
        _burn(tokenId);
    }

    /// @notice Function for setting up the base URI
    /// @param uri Base URI to set
    /// @dev Function does not allow to set up empty URI
    /// @dev Function emits UpdateURI event
    function setBaseURI(string calldata uri) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        // check string not empty
        if(bytes(uri).length == 0) revert InvalidData();
        _uri = uri;

        emit UpdateURI(uri);
    }

    /// @notice Function for checking interface support
    /// @param interfaceId The ID of the interface to check
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC721) returns (bool) {
        return
            interfaceId == type(IToken721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Function for getting the base URI
    function _baseURI() internal view virtual override returns (string memory) {
        return _uri;
    }
}