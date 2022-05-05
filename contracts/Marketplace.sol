//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
// import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IToken721.sol";
import "./interfaces/IToken1155.sol";
import "./interfaces/IMarketplace.sol";

import "./Token721.sol";
import "./Token1155.sol";

contract Marketplace is IMarketplace, AccessControl {
    // using SafeERC20 for IERC20;

    IToken721 public token721;
    IToken1155 public token1155;
    IERC20 public token20;

    mapping(address => address) public _ownersToNFTs;
    
    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setUpConfig(
        IToken721 token721_,
        IToken1155 token1155_,
        IERC20 token20_
    ) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        token721 = token721_;
        token1155 = token1155_;
        token20 = token20_;
    }

    function createItem(string calldata tokenURI, address owner, bool is1155, uint256 amount) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        if (is1155) {
            Token1155 newNFT = new Token1155(tokenURI);
            _ownersToNFTs[owner] = address(newNFT);
            newNFT.mint(owner, 0, amount);
        } else {
            Token721 newNFT = new Token721("Test token", "TST");
            _ownersToNFTs[owner] = address(newNFT);
            newNFT.mint(owner, 1);
            newNFT.setTokenURI(0, tokenURI);
        }
    }
}