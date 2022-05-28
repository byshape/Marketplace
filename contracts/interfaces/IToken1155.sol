//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IToken1155 {
    error InvalidData();

    /// @dev Emits when URI is set
    event UpdateURI(string uri);

    /// @notice Function for minting tokens to account
    /// @param to Address of the account to mint tokens
    /// @param tokenId Token id for mint
    /// @param amount Amount of tokens to mint
    /// @dev Function does not allow to mint zero tokens
    /// @dev Function does not allow to mint to the zero address
    /// @dev Function emits TransferSingle event
    function mint(address to, uint256 tokenId, uint256 amount) external;

    /// @notice Function for burning tokens by the account
    /// @param id The ID of the token to burn
    /// @param amount Amount of tokens to burn
    /// @dev Function does not allow to burn zero tokens
    /// @dev Function does not allow to burn from the zero address
    /// @dev Function does not allow to burn tokens more than balance
    /// @dev Function emits TransferSingle event
    function burn(uint256 id, uint256 amount) external;

    /// @notice Function for setting up the base tokens URI
    /// @param newuri The new base URI
    /// @dev Function does not allow to set up empty URI
    /// @dev Function emits UpdateURI event
    function setURI(string memory newuri) external;
}