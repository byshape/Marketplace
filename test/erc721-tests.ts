import { expect } from "chai";
import { ethers } from "hardhat";

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { Token721, Token721__factory } from "../typechain";

import { getInterface } from "./helpers";

describe("Token721", function () {
  let admin: SignerWithAddress;
  let user: SignerWithAddress;
  let tokenFactory: Token721__factory;
  let token: Token721;
  let tokenCounter: number = 0;

  before(async () => {
    // get signers
    [admin, user] = await ethers.getSigners();

    // deploy Token721
    tokenFactory = await ethers.getContractFactory("Token721", admin);
    token = await tokenFactory.deploy("Test 721", "TST721");
    await token.deployed(); 

  });

  it("Should support Token721 interface", async function () {
    let abi = [
      "function setBaseURI(string)", "function mint(address,uint256)",
      "function burn(uint256)"
    ];
    let functions = ["setBaseURI", "mint", "burn"];
    expect(await token.connect(admin).supportsInterface(await getInterface(abi, functions))).to.be.equal(true);
  });

  it("Should support AccessControl interface", async function () {
    let abi = [
      "function hasRole(bytes32,address)", "function getRoleAdmin(bytes32)", "function grantRole(bytes32,address)",
      "function revokeRole(bytes32,address)", "function renounceRole(bytes32,address)"
    ];
    let functions = ["hasRole", "getRoleAdmin", "grantRole", "revokeRole", "renounceRole"];
    expect(await token.connect(admin).supportsInterface(await getInterface(abi, functions))).to.be.equal(true);
  });

  it("Should support ERC721 interface", async function () {
    let abi = [
      "function balanceOf(address)", "function ownerOf(uint256)", "function safeTransferFrom(address,address,uint256,bytes)",
      "function safeTransferFrom(address,address,uint256)", "function transferFrom(address,address,uint256)",
      "function approve(address, uint256)", "function setApprovalForAll(address, bool)", "function getApproved(uint256)",
      "function isApprovedForAll(address, address)"
    ];
    let functions = [
      "balanceOf", "ownerOf", "safeTransferFrom(address,address,uint256,bytes)", "safeTransferFrom(address,address,uint256)", "transferFrom",
      "approve", "setApprovalForAll", "getApproved", "isApprovedForAll"
    ];
    expect(await token.connect(admin).supportsInterface(await getInterface(abi, functions))).to.be.equal(true);
  });

  it("Should support ERC721Metadata interface", async function () {
    let abi = ["function name()", "function symbol()", "function tokenURI(uint256)"];
    let functions = ["name", "symbol", "tokenURI"];
    expect(await token.connect(admin).supportsInterface(await getInterface(abi, functions))).to.be.equal(true);
  });

  it("Sets token URI", async () => {
    let tokenId: number  = 0;
    expect(await token.connect(admin).mint(user.address, tokenId)).to.emit(token, "Transfer").withArgs(ethers.constants.AddressZero, user.address, tokenId);
    expect(await token.tokenURI(tokenId)).to.be.equal("");
    let uriString: string = "test/";
    expect(await token.connect(admin).setBaseURI(uriString)).to.emit(token, "UpdateURI").withArgs(uriString);
    expect(await token.connect(admin).tokenURI(tokenId)).to.be.equal(uriString + tokenId.toString());
  });

  it("Does not set empty token URI", async () => {
    await expect(token.connect(admin).setBaseURI("")).to.be.revertedWith("InvalidData");
  });

  it("Does not burn non-existent token", async () => {
    await expect(token.connect(user).burn(666)).to.be.revertedWith("DoesNotExist");
  });

  it("Does not burn token by the non-owner", async () => {
    let tokenId: number  = 0;
    await expect(token.connect(admin).burn(tokenId)).to.be.revertedWith("NotAuthorized");
  });

  it("Burns token by the owner", async () => {
    let tokenId: number  = 0;
    expect(await token.connect(user).ownerOf(tokenId)).to.be.equal(user.address);
    expect(await token.connect(user).burn(tokenId)).to.emit(token, "Transfer").withArgs(user.address, ethers.constants.AddressZero);
  });
});
