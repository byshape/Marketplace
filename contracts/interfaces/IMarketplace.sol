//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IMarketplace {
    /// @notice Function for setting up the marketplace contract
    /// @param token721_ Token721 address
    /// @param token1155_ Token1155 address
    /// @param token20_ ERC20 token address
    /// @param auctionDuration_ Duration of the auction in seconds
    function setUpConfig(address token721_, address token1155_, address token20_, uint256 auctionDuration_) external;
}