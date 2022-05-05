//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IToken721 is IAccessControl, IERC721 {
    function setTokenURI(uint256 tokenId, string calldata uri) external;
    function mint(address to, uint256 amount) external;
    function burn(uint256 tokenId) external;
}