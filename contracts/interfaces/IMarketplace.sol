//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// import "./IToken20.sol";
import "./IToken721.sol";
import "./IToken1155.sol";

interface IMarketplace {
    function setUpConfig(IToken721 token721_, IToken1155 token1155_, IERC20 token20_) external;
    
    function createItem(string calldata tokenURI, address owner, bool is1155, uint256 amount) external;
}