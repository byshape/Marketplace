//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

interface IToken1155 is IAccessControl, IERC1155 {
    function mint(address to, uint256 id, uint256 amount) external;
    function burn(uint256 id, uint256 amount) external;
    function setURI(string memory newuri) external;
}