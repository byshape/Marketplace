import { expect } from "chai";
import { ethers } from "hardhat";

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { Token1155, Token1155__factory } from "../typechain";

import { getInterface } from "./helpers";

describe("Token1155", function () {
  let admin: SignerWithAddress;
  let user: SignerWithAddress;
  let tokenFactory: Token1155__factory;
  let token: Token1155;

  const DEFAULT_URI: string = "https://test-uri.com/test-collection/";

  before(async () => {
    // get signers
    [admin, user] = await ethers.getSigners();

    // deploy Token1155
    tokenFactory = await ethers.getContractFactory("Token1155", admin);
    token = await tokenFactory.deploy(DEFAULT_URI);
    await token.deployed(); 

  });

  it("Should support Token1155 interface", async function () {
    let abi = [
      "function mint(address,uint256,uint256)", "function burn(uint256,uint256)",
      "function setURI(string)"
    ];
    let functions = ["mint", "burn", "setURI"];
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

  it("Should support 1155 interface", async function () {
    let abi = [
      "function balanceOf(address,uint256)", "function balanceOfBatch(address[],uint256[])",
      "function setApprovalForAll(address,bool)", "function isApprovedForAll(address,address)",
      "function safeTransferFrom(address,address,uint256,uint256,bytes)",
      "function safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)"
    ];
    let functions = [
      "balanceOf", "balanceOfBatch", "setApprovalForAll", "isApprovedForAll",
      "safeTransferFrom", "safeBatchTransferFrom"
    ];
    expect(await token.connect(admin).supportsInterface(await getInterface(abi, functions))).to.be.equal(true);
  });

  it("Should support IERC1155MetadataURI interface", async function () {
    let abi = ["function uri(uint256)"];
    let functions = ["uri"];
    expect(await token.connect(admin).supportsInterface(await getInterface(abi, functions))).to.be.equal(true);
  });

  it("Gets token URI for token", async () => {
    expect(await token.connect(admin).uri(0)).to.be.equal(DEFAULT_URI + "0");
  });

  it("Does not set token URI by the non-admin", async () => {
    await expect(token.connect(user).setURI("")).to.be.revertedWith("AccessControl");
  });

  it("Does not set empty token URI", async () => {
    await expect(token.connect(admin).setURI("")).to.be.revertedWith("InvalidData");
  });

  it("Does not mint tokens by the non-minter", async () => {
    expect(token.connect(user).mint(user.address, 0, 3)).to.be.revertedWith("AccessControl");
  });

  it("Does not mint zero tokens", async () => {
    await expect(token.connect(admin).mint(user.address, 0, 0)).to.be.revertedWith("InvalidData");
  });

  it("Mints tokens by the minter", async () => {
    expect(await token.connect(admin).mint(user.address, 0, 3)).to.emit(token, "TransferSingle").withArgs(admin.address, ethers.constants.AddressZero, user.address, 0, 3, "");
    expect(await token.balanceOf(user.address, 0)).to.be.equal(3);
  });

  it("Sets token URI", async () => {
    expect(await token.uri(0)).to.be.equal(DEFAULT_URI + "0");
    let uriString: string = "test";
    expect(await token.connect(admin).setURI(uriString)).to.emit(token, "UpdateURI").withArgs(uriString);
    expect(await token.connect(admin).uri(0)).to.be.equal(uriString + "0");
  });

  it("Does not burn tokens more than balance", async () => {
    await expect(token.connect(user).burn(0, 10)).to.be.revertedWith("ERC1155: burn amount exceeds balance");
  });

  it("Does not burn zero tokens", async () => {
    await expect(token.connect(admin).burn(0, 0)).to.be.revertedWith("InvalidData");
  });

  it("Burns token by the user", async () => {
    expect(await token.connect(user).burn(0, 3)).to.emit(token, "TransferSingle").withArgs(admin.address, user.address, ethers.constants.AddressZero, 0, 3);
  });

});
