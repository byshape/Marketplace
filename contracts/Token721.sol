//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./interfaces/IToken721.sol";

/// @title ERC721 contract with mint, burn and setTokenURI functions
/// @author Xenia Shape
/// @notice This contract can be used for only the most basic ERC721 test experiments
contract Token721 is AccessControl, ERC721, IToken721 {
    using Counters for Counters.Counter;

    error DoesNotExist();
    error InvalidData();
    error NotAuthorized();

    event UpdateURI(uint256 tokenId, string uri);
    
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    Counters.Counter private _tokenIdTracker;

    // token id => URI
    mapping(uint256 => string) public _tokenURI;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(MINTER_ROLE, msg.sender);
    }

    /// @notice Function for minting tokens to account
    /// @param to Address of the account to mint tokens
    /// @param amount Amount of tokens to mint
    /// @dev Function does not allow to mint zero tokens
    function mint(address to, uint256 amount) external override onlyRole(MINTER_ROLE) {
        if(amount == 0) revert InvalidData();
        for (uint256 i=0; i < amount; i++) {
            _safeMint(to, _tokenIdTracker.current());
            _tokenIdTracker.increment();
        }
    }

    /// @notice Function for burning tokens by the account
    /// @param tokenId The ID of the token to burn
    /// @dev Function does not allow to burn non-existent token
    /// @dev Function does not allow to burn not owned or approved tokens
    function burn(uint256 tokenId) external override{
        // check that token exists
        if (!_exists(tokenId)) revert DoesNotExist();
        // check that it is token's owner
        if (!_isApprovedOrOwner(msg.sender, tokenId)) revert NotAuthorized();
        _burn(tokenId);
    }

    /// @notice Function for setting up the token's URI
    /// @param tokenId The ID of the token
    /// @dev Function does not allow to set up URI for non-existent token
    /// @dev Function does not allow to set up empty URI
    function setTokenURI(uint256 tokenId, string calldata uri) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        // check id exists
        if (!_exists(tokenId)) revert DoesNotExist();
        // check string not empty
        if(bytes(uri).length == 0) revert InvalidData();
        _tokenURI[tokenId] = uri;

        emit UpdateURI(tokenId, uri);
    }

    /// @notice Function for checking interface support
    /// @param interfaceId The ID of the interface to check
    function supportsInterface(bytes4 interfaceId) public view override(AccessControl, ERC721, IERC165) returns (bool) {
        return
            interfaceId == type(IToken721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice Function for returning the token's URI
    /// @param tokenId The ID of the token
    /// @dev Function does not allow to get URI of non-existent token
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert DoesNotExist();

        return _tokenURI[tokenId];
    }
}