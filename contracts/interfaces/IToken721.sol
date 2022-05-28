//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IToken721 {
    error DoesNotExist();
    error InvalidData();
    error NotAuthorized();

    /// @dev Emits when URI is set
    event UpdateURI(string uri);

    /// @notice Function for setting up the base URI
    /// @param uri Base URI to set
    /// @dev Function does not allow to set up empty URI
    /// @dev Function emits UpdateURI event
    function setBaseURI(string calldata uri) external;

    /// @notice Function for minting tokens to account
    /// @param to Address of the account to mint tokens
    /// @param tokenId Token id for mint
    /// @dev Function does not allow to mint zero tokens
    /// @dev Function emits Transfer event
    function mint(address to, uint256 tokenId) external;

    /// @notice Function for burning tokens by the account
    /// @param tokenId The ID of the token to burn
    /// @dev Function does not allow to burn non-existent token
    /// @dev Function does not allow to burn not owned or approved tokens
    /// @dev Function emits Transfer and Approval events
    function burn(uint256 tokenId) external;
}