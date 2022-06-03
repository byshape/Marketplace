import { expect } from "chai";
import { ethers } from "hardhat";

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { ERC20, Marketplace, Token1155, Token721 } from "../typechain";

import { deployContract, getInterface } from "./helpers";
import { BigNumber } from "ethers";

describe("Marketplace", function () {
  let admin: SignerWithAddress;
  let user: SignerWithAddress;
  let user2: SignerWithAddress;
  let user3: SignerWithAddress;
  let token721: Token721;
  let token1155: Token1155;
  let token20: ERC20;
  let marketplace: Marketplace;
  let counter1155: number = 0;

  const DEFAULT_URI_721: string = "https://test-uri.com/test-721-uri/";
  const DEFAULT_URI_1155: string = "https://test-uri.com/test-1155-uri/";
  const initialSupply: bigint = BigInt(1000 * 10 ** 18);
  const MINTER_ROLE: string = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER_ROLE"));
  const price: bigint = BigInt(0.01 * 10 **18);
  const auctionDuration: number = 3 * 60; // 3 minutes
  const tokens20Amount: bigint = BigInt(10 * 10 ** 18);

  before(async () => {
    // get signers
    [admin, user, user2, user3] = await ethers.getSigners();

    // deploy tokens
    token721 = await deployContract("Token721", admin, "Test 721 token", "TST721");
    token1155 = await deployContract("Token1155", admin, DEFAULT_URI_1155);
    token20 = await deployContract("ERC20", admin, "Test 20 token", "TST20", 18, initialSupply, admin.address);

    // set up token 721 URI
    await token721.setBaseURI(DEFAULT_URI_721);

    // deploy Marketplace
    marketplace = await deployContract("Marketplace", admin);

    // grant minter role to the marketplace
    await token721.grantRole(MINTER_ROLE, marketplace.address);
    await token1155.grantRole(MINTER_ROLE, marketplace.address);

    await token20.connect(admin).mint(user.address, tokens20Amount.toString());
    await token20.connect(admin).mint(user2.address, tokens20Amount.toString());
    await token20.connect(user).approve(marketplace.address, tokens20Amount.toString());
    await token20.connect(user2).approve(marketplace.address, tokens20Amount.toString());

  });

  it("Sets up config", async () => {
    await marketplace.setUpConfig(token721.address, token1155.address, token20.address, auctionDuration.toString());
    expect(await marketplace.token721()).to.be.equal(token721.address);
    expect(await marketplace.token1155()).to.be.equal(token1155.address);
    expect(await marketplace.token20()).to.be.equal(token20.address);
  });

  it("Should support IMarketplace interface", async function () {
    let abi = [
      "function setUpConfig(address,address,address,uint256)", "function createItem1155(uint256,uint256)", "function listItem1155(uint256,uint256,uint256)",
      "function cancelItem1155(uint256,uint256)", "function buylItem1155(uint256,uint256)",
      "function listItemOnAuction1155(uint256,uint256,uint256)", "function makeBid1155(uint256, uint256)",
      "function finishAuction1155(uint256)", "function createItem721(uint256)", "function listItem721(uint256,uint256)",
      "function cancelItem721(uint256)", "function buylItem721(uint256)",
      "function listItemOnAuction721(uint256,uint256)", "function makeBid721(uint256, uint256)",
      "function finishAuction721(uint256)"
    ];
    let functions = ["setUpConfig", "createItem1155", "listItem1155", "cancelItem1155", "buylItem1155",
      "listItemOnAuction1155", "makeBid1155", "finishAuction1155", "createItem721", "listItem721", "cancelItem721", "buylItem721",
      "listItemOnAuction721", "makeBid721", "finishAuction721"];
    expect(await marketplace.connect(admin).supportsInterface(await getInterface(abi, functions))).to.be.equal(true);
  });

  it("Should return onERC1155BatchReceived selector", async function () {
    expect(await marketplace.callStatic.onERC1155BatchReceived(user.address, user.address, [1], [1], [0xb5])).to.be.equal("0xbc197c81");
  });

  it("Creates 721 item", async () => {
    let tokenId: number = 0;
    await expect(
      marketplace.connect(user).createItem721(tokenId)
    ).to.emit(token721, "Transfer").withArgs(ethers.constants.AddressZero, user.address, tokenId);
    expect(await token721.ownerOf(tokenId)).to.be.equal(user.address);
    expect(await token721.tokenURI(tokenId)).to.be.equal(DEFAULT_URI_721 + tokenId.toString());
  });

  it("Creates 1155 item", async () => {
    let id: number = 0;
    let amount: number = 10;
    await expect(
      marketplace.connect(user).createItem1155(id, amount)
    ).to.emit(token1155, "TransferSingle").withArgs(
      marketplace.address, ethers.constants.AddressZero, user.address, id, amount
    );
    expect(await token1155.balanceOf(user.address, id)).to.be.equal(amount);
    expect(await token1155.uri(id)).to.be.equal(DEFAULT_URI_1155 + id.toString());
  });

  it("Does not list 721 item by non-owner", async () => {
    let tokenId = 0;
    await expect(marketplace.connect(user2).listItem721(
      tokenId, price.toString()
    )).to.be.revertedWith("ERC721: transfer caller is not owner nor approved");
    expect(await token721.ownerOf(tokenId)).to.be.equal(user.address);
  });

  it("Lists 721 item", async () => {
    let tokenId = 0;
    await token721.connect(user).setApprovalForAll(marketplace.address, true);
    await expect(marketplace.connect(user).listItem721(
      tokenId, price.toString()
    )).to.emit(marketplace, "Item721Listed").withArgs(tokenId, price);
    expect(await token721.ownerOf(tokenId)).to.be.equal(marketplace.address);
  });

  it("Does not list 721 item on auction by non-owner", async () => {
    let tokenId: number = 1;
    let tokenId2: number = 2;

    await expect(
      marketplace.connect(user).createItem721(tokenId)
    ).to.emit(token721, "Transfer").withArgs(ethers.constants.AddressZero, user.address, tokenId);
    await expect(marketplace.connect(user2).listItemOnAuction721(
      tokenId, price.toString()
    )).to.be.revertedWith("ERC721: transfer from incorrect owner");
    expect(await token721.ownerOf(tokenId)).to.be.equal(user.address);

    await expect(
      marketplace.connect(user).createItem721(tokenId2)
    ).to.emit(token721, "Transfer").withArgs(ethers.constants.AddressZero, user.address, tokenId2);
    await expect(marketplace.connect(user2).listItemOnAuction721(
      tokenId2, price.toString()
    )).to.be.revertedWith("ERC721: transfer from incorrect owner");
    expect(await token721.ownerOf(tokenId2)).to.be.equal(user.address);

    
  });
  
  it("Lists 721 item on auction", async () => {
    let tokenId: number = 1;
    let tokenId2: number = 2;
    await expect(marketplace.connect(user).listItemOnAuction721(
      tokenId, price.toString()
    )).to.emit(marketplace, "Item721ListedAuction").withArgs(tokenId, price);
    expect(await token721.ownerOf(tokenId)).to.be.equal(marketplace.address);

    await expect(marketplace.connect(user).listItemOnAuction721(
      tokenId2, price.toString()
    )).to.emit(marketplace, "Item721ListedAuction").withArgs(tokenId2, price);
    expect(await token721.ownerOf(tokenId2)).to.be.equal(marketplace.address);
  });

  it("Does not list 1155 item more than balance", async () => {
    let amount: number = 100;
    let tokenId: number = 0;
    await expect(marketplace.connect(user).listItem1155(
      tokenId, amount, price.toString()
    )).to.be.revertedWith("InsufficientBalance");
    expect(await token1155.balanceOf(marketplace.address, tokenId)).to.be.equal(0);
    expect(await token1155.balanceOf(user.address, tokenId)).to.be.equal(10);
  });

  it("Lists 1155 item", async () => {
    let amount: number = 5;
    let tokenId: number = 0;
    await token1155.connect(user).setApprovalForAll(marketplace.address, true);
    await expect(marketplace.connect(user).listItem1155(
      tokenId, amount, price.toString()
    )).to.emit(marketplace, "Item1155Listed").withArgs(counter1155, tokenId, price, amount);
    expect(await token1155.balanceOf(marketplace.address, tokenId)).to.be.equal(amount);
    expect(await token1155.balanceOf(user.address, tokenId)).to.be.equal(5);
    counter1155++;
  });

  it("Lists 1155 item with the same id", async () => {
    let tokenId: number = 50;
    let amount: number =  10;
    let amountToList: number =  amount / 2;

    await expect(
      marketplace.connect(user).createItem1155(tokenId, amount)
    ).to.emit(token1155, "TransferSingle").withArgs(
      marketplace.address, ethers.constants.AddressZero, user.address, tokenId, amount
    );

    await expect(marketplace.connect(user).listItem1155(
      tokenId, amountToList, price.toString()
    )).to.emit(marketplace, "Item1155Listed").withArgs(counter1155, tokenId, price, amountToList);
    expect(await token1155.balanceOf(marketplace.address, tokenId)).to.be.equal(amountToList);
    expect(await token1155.balanceOf(user.address, tokenId)).to.be.equal(amountToList);
    counter1155++;

    await expect(marketplace.connect(user).listItem1155(
      tokenId, amountToList, price.toString()
    )).to.emit(marketplace, "Item1155Listed").withArgs(counter1155, tokenId, price, amountToList);
    expect(await token1155.balanceOf(marketplace.address, tokenId)).to.be.equal(amount);
    expect(await token1155.balanceOf(user.address, tokenId)).to.be.equal(0);
    await expect(marketplace.connect(user2).buylItem1155(
      counter1155, amount
    )).to.be.revertedWith("InvalidValue");
    counter1155++;
    
  });

  it("Does not list 1155 item on auction more than balance", async () => {
    let tokenId: number = 1;
    let amount: number =  20;
    let tokenId2: number = 2;

    await expect(
      marketplace.connect(user).createItem1155(tokenId, amount)
    ).to.emit(token1155, "TransferSingle").withArgs(
      marketplace.address, ethers.constants.AddressZero, user.address, tokenId, amount
    );
    await expect(marketplace.connect(user).listItemOnAuction1155(
      tokenId, 100, price.toString()
    )).to.be.revertedWith("InsufficientBalance");
    expect(await token1155.balanceOf(marketplace.address, tokenId)).to.be.equal(0);
    expect(await token1155.balanceOf(user.address, tokenId)).to.be.equal(amount);

    await expect(
      marketplace.connect(user).createItem1155(tokenId2, amount)
    ).to.emit(token1155, "TransferSingle").withArgs(
      marketplace.address, ethers.constants.AddressZero, user.address, tokenId2, amount
    );
    await expect(marketplace.connect(user).listItemOnAuction1155(
      tokenId2, 100, price.toString()
    )).to.be.revertedWith("InsufficientBalance");
    expect(await token1155.balanceOf(marketplace.address, tokenId2)).to.be.equal(0);
    expect(await token1155.balanceOf(user.address, tokenId2)).to.be.equal(amount);
  });

  it("Lists 1155 item on auction", async () => {
    let tokenId: number = 1;
    let amount: number =  5;
    let tokenId2: number = 2;

    await expect(marketplace.connect(user).listItemOnAuction1155(
      tokenId, price.toString(), amount
    )).to.emit(marketplace, "Item1155ListedAuction").withArgs(counter1155, tokenId, price, amount);
    expect(await token1155.balanceOf(marketplace.address, tokenId)).to.be.equal(amount);
    expect(await token1155.balanceOf(user.address, tokenId)).to.be.equal(15);
    counter1155++;

    await expect(marketplace.connect(user).listItemOnAuction1155(
      tokenId2, price.toString(), amount
    )).to.emit(marketplace, "Item1155ListedAuction").withArgs(counter1155, tokenId2, price, amount);
    expect(await token1155.balanceOf(marketplace.address, tokenId2)).to.be.equal(amount);
    expect(await token1155.balanceOf(user.address, tokenId2)).to.be.equal(15);
    counter1155++;
  });

  it("Does not cancel 721 item by non-owner", async () => {
    let tokenId = 0;
    await expect(marketplace.connect(user2).cancelItem721(tokenId)).to.be.revertedWith("NotOwner");
    expect(await token721.ownerOf(tokenId)).to.be.equal(marketplace.address);
  });

  it("Cancels 721 item", async () => {
    let tokenId = 0;
    await expect(marketplace.connect(user).cancelItem721(tokenId)).to.emit(
      marketplace, "Item721Cancelled"
    ).withArgs(tokenId);
    expect(await token721.ownerOf(tokenId)).to.be.equal(user.address);
  });

  it("Does not cancel 1155 item by non-owner", async () => {
    let amount: number = 1;
    let tokenId = 0;
    await expect(marketplace.connect(user2).cancelItem1155(tokenId, amount)).to.be.revertedWith("NotOwner");
    expect(await token1155.balanceOf(marketplace.address, tokenId)).to.be.equal(5);
    expect(await token1155.balanceOf(user.address, tokenId)).to.be.equal(5);
  });

  it("Cancels 1155 item", async () => {
    let amount: number = 1;
    let tokenId = 0;
    await expect(marketplace.connect(user).cancelItem1155(tokenId, amount)).to.emit(
      marketplace, "Item1155Cancelled"
    ).withArgs(tokenId, amount);
    expect(await token1155.balanceOf(marketplace.address, tokenId)).to.be.equal(4);
    expect(await token1155.balanceOf(user.address, tokenId)).to.be.equal(6);
  });

  it("Does not sell non-existent 721 item", async () => {
    let tokenId = 100;
    await expect(marketplace.connect(user2).buylItem721(tokenId)).to.be.revertedWith("DoesNotExist");
  });

  it("Does not sell 721 item if unsufficient funds", async () => {
    let tokenId = 0;
    await expect(marketplace.connect(user).listItem721(
      tokenId, price.toString()
    )).to.emit(marketplace, "Item721Listed").withArgs(tokenId, price);
    await expect(marketplace.connect(user3).buylItem721(tokenId)).to.be.revertedWith("InsufficientBalance");
    expect(await token721.ownerOf(tokenId)).to.be.equal(marketplace.address);
  });

  it("Sels 721 item", async () => {
    let tokenId = 0;
    await expect(marketplace.connect(user2).buylItem721(tokenId)).to.emit(marketplace, "Item721Sold").withArgs(tokenId, user2.address, price);
    expect(await token721.ownerOf(tokenId)).to.be.equal(user2.address);
  });

  it("Does not accept bid for non-existent 721 item", async () => {
    let tokenId: number = 10;
    let bid: bigint = price * BigInt(2);

    let userBalance: BigNumber = await token20.balanceOf(user.address);
    await expect(marketplace.connect(user).makeBid721(
      tokenId, bid.toString()
    )).to.be.revertedWith("DoesNotExist");
    expect(await token20.balanceOf(user.address)).to.be.equal(userBalance);
  });

  it("Does not accept bid for 721 listing if unsufficient funds", async () => {
    let tokenId: number = 1;
    let bid: bigint = price * BigInt(2);

    let userBalance: BigNumber = await token20.balanceOf(user3.address);

    await expect(marketplace.connect(user3).makeBid721(
      tokenId, bid.toString()
    )).to.be.revertedWith("InsufficientBalance");
    expect(await token20.balanceOf(user3.address)).to.be.equal(userBalance);
  });

  it("Accepts bid for 721 item", async () => {
    let tokenId: number = 1;
    let tokenId2: number = 2;
    let bid: bigint = price * BigInt(2);
    let bid2: bigint = price * BigInt(3);
    let bid3: bigint = price * BigInt(4);

    let userBalance: BigNumber = await token20.balanceOf(user.address);
    let userBalance2: BigNumber = await token20.balanceOf(user2.address);

    await expect(marketplace.connect(user).makeBid721(
      tokenId, bid.toString()
    )).to.emit(marketplace, "Item721BiddedAuction").withArgs(tokenId, user.address, bid);
    await expect(marketplace.connect(user).makeBid721(
      tokenId2, bid.toString()
    )).to.emit(marketplace, "Item721BiddedAuction").withArgs(tokenId2, user.address, bid);
    expect(await token20.balanceOf(user.address)).to.be.equal(userBalance.sub(bid * BigInt(2)));
    
    await expect(marketplace.connect(user2).makeBid721(
      tokenId, bid2.toString()
    )).to.emit(marketplace, "Item721BiddedAuction").withArgs(tokenId, user2.address, bid2);
    await expect(marketplace.connect(user2).makeBid721(
      tokenId2, bid2.toString()
    )).to.emit(marketplace, "Item721BiddedAuction").withArgs(tokenId2, user2.address, bid2);
    expect(await token20.balanceOf(user.address)).to.be.equal(userBalance);
    expect(await token721.ownerOf(tokenId)).to.be.equal(marketplace.address);

    await expect(marketplace.connect(user2).makeBid721(
      tokenId2, bid3.toString()
    )).to.emit(marketplace, "Item721BiddedAuction").withArgs(tokenId2, user2.address, bid3);
    expect(await token20.balanceOf(user2.address)).to.be.equal(userBalance2.sub(bid2 + bid3));
    expect(await token721.ownerOf(tokenId2)).to.be.equal(marketplace.address);
  });

  it("Does not accept incorrect bid for 721 item", async () => {
    let tokenId: number = 1;
    let bid: bigint = price * BigInt(2);

    let userBalance: BigNumber = await token20.balanceOf(user.address);

    await expect(marketplace.connect(user).makeBid721(
      tokenId, bid.toString()
    )).to.be.revertedWith("InvalidValue");
    expect(await token20.balanceOf(user.address)).to.be.equal(userBalance);
  });

  it("Does not finish auction for 721 item before it ends", async () => {
    let tokenId: number = 1;
    await expect(marketplace.connect(user2).finishAuction721(tokenId)).to.be.revertedWith("WrongPeriod");
    expect(await token721.ownerOf(tokenId)).to.be.equal(marketplace.address);
  });

  it("Does not finish auction for non-existent 721 item", async () => {
    let tokenId: number = 100;
    await expect(marketplace.connect(user2).finishAuction721(tokenId)).to.be.revertedWith("DoesNotExist");
  });

  it("Does not accept bid for 721 item after auction", async () => {
    let tokenId: number = 1;
    let bid: bigint = price * BigInt(2);

    await ethers.provider.send('evm_increaseTime', [auctionDuration]);

    let userBalance: BigNumber = await token20.balanceOf(user.address);
    await expect(marketplace.connect(user).makeBid721(
      tokenId, bid.toString()
    )).to.be.revertedWith("WrongPeriod");
    expect(await token20.balanceOf(user.address)).to.be.equal(userBalance);
  });

  it("Finishes auction for 721 item, 2 or less bids", async () => {
    let tokenId: number = 1;
    await expect(marketplace.connect(user2).finishAuction721(tokenId)).to.emit(marketplace, "Item721FinishedAuction").withArgs(tokenId, user.address, price * BigInt(3));
    expect(await token721.ownerOf(tokenId)).to.be.equal(user.address);
  });

  it("Finishes auction for 721 item, more than 2 bids", async () => {
    let tokenId: number = 2;
    await expect(marketplace.connect(user2).finishAuction721(tokenId)).to.emit(marketplace, "Item721FinishedAuction").withArgs(tokenId, user2.address, price * BigInt(4));
    expect(await token721.ownerOf(tokenId)).to.be.equal(user2.address);
  });

  it("Doesn not sell non-existent 1155 item", async () => {
    let amount: number = 1;
    let listingId = 10;
    await expect(marketplace.connect(user2).buylItem1155(listingId, amount)).to.be.revertedWith("DoesNotExist");
  });

  it("Doesn not sell 1155 item if unsufficient balance", async () => {
    let amount: number = 1;
    let listingId = 0;
    let tokenId = 0;
    await expect(marketplace.connect(user3).buylItem1155(listingId, amount)).to.be.revertedWith("InsufficientBalance");
    expect(await token1155.balanceOf(marketplace.address, tokenId)).to.be.equal(4);
    expect(await token1155.balanceOf(user.address, tokenId)).to.be.equal(6);
    expect(await token1155.balanceOf(user3.address, tokenId)).to.be.equal(0);
  });

  it("Sels 1155 item", async () => {
    let amount: number = 1;
    let listingId = 0;
    let tokenId = 0;
    await expect(marketplace.connect(user2).buylItem1155(listingId, amount)).to.emit(marketplace, "Item1155Sold").withArgs(listingId, amount, user2.address, price);;
    expect(await token1155.balanceOf(marketplace.address, tokenId)).to.be.equal(3);
    expect(await token1155.balanceOf(user.address, tokenId)).to.be.equal(6);
    expect(await token1155.balanceOf(user2.address, tokenId)).to.be.equal(1);
  });

  it("Does not accept bid for 1155 non-existent listing", async () => {
    let listingId: number = 10;
    let bid: bigint = price * BigInt(5 * 2);
    let userBalance: BigNumber = await token20.balanceOf(user.address);

    await expect(marketplace.connect(user).makeBid1155(
      listingId, bid.toString()
    )).to.be.revertedWith("DoesNotExist");
    expect(await token20.balanceOf(user.address)).to.be.equal(userBalance);
  });

  it("Does not accept bid for 1155 item if unsufficient funds", async () => {
    let listingId: number = 3;
    let bid: bigint = price * BigInt(5 * 2);

    let userBalance: BigNumber = await token20.balanceOf(user3.address);

    await expect(marketplace.connect(user3).makeBid1155(
      listingId, bid.toString()
    )).to.be.revertedWith("InsufficientBalance");
    expect(await token20.balanceOf(user3.address)).to.be.equal(userBalance);
  });

  it("Accepts bid for 1155 item", async () => {
    let listingId: number = 3;
    let tokenId: number = 1;
    let listingId2: number = 4;
    let tokenId2: number = 2;
    let bid: bigint = price * BigInt(5 * 2);
    let bid2: bigint = price * BigInt(5 * 3);
    let bid3: bigint = price * BigInt(5 * 4);

    let userBalance: BigNumber = await token20.balanceOf(user.address);
    let userBalance2: BigNumber = await token20.balanceOf(user2.address);

    let marketplaceBalance = await token1155.balanceOf(marketplace.address, tokenId);
    let marketplaceBalance2 = await token1155.balanceOf(marketplace.address, tokenId2);

    await expect(marketplace.connect(user).makeBid1155(
      listingId, bid.toString()
    )).to.emit(marketplace, "Item1155BiddedAuction").withArgs(listingId, user.address, bid);
    await expect(marketplace.connect(user).makeBid1155(
      listingId2, bid.toString()
    )).to.emit(marketplace, "Item1155BiddedAuction").withArgs(listingId2, user.address, bid);
    expect(await token20.balanceOf(user.address)).to.be.equal(userBalance.sub(bid * BigInt(2)));
    
    await expect(marketplace.connect(user2).makeBid1155(
      listingId, bid2.toString()
    )).to.emit(marketplace, "Item1155BiddedAuction").withArgs(listingId, user2.address, bid2);
    await expect(marketplace.connect(user2).makeBid1155(
      listingId2, bid2.toString()
    )).to.emit(marketplace, "Item1155BiddedAuction").withArgs(listingId2, user2.address, bid2);
    expect(await token20.balanceOf(user.address)).to.be.equal(userBalance);
    expect(await token1155.balanceOf(marketplace.address, tokenId)).to.be.equal(marketplaceBalance);

    await expect(marketplace.connect(user2).makeBid1155(
      listingId2, bid3.toString()
    )).to.emit(marketplace, "Item1155BiddedAuction").withArgs(listingId2, user2.address, bid3);
    expect(await token20.balanceOf(user2.address)).to.be.equal(userBalance2.sub(bid2 + bid3));
    expect(await token1155.balanceOf(marketplace.address, tokenId2)).to.be.equal(marketplaceBalance2);
  });

  it("Does not accept incorrect bid for 1155 item", async () => {
    let listingId: number = 3;
    let bid: bigint = price * BigInt(2);

    let userBalance: BigNumber = await token20.balanceOf(user.address);

    await expect(marketplace.connect(user).makeBid1155(
      listingId, bid.toString()
    )).to.be.revertedWith("InvalidValue");
    expect(await token20.balanceOf(user.address)).to.be.equal(userBalance);
  });

  it("Does not finish auction for 1155 item before it ends", async () => {
    let listingId: number = 3;
    let tokenId: number = 1;
    let marketplaceBalance = await token1155.balanceOf(marketplace.address, tokenId);
    await expect(marketplace.connect(user2).finishAuction1155(listingId)).to.be.revertedWith("WrongPeriod");
    expect(await token1155.balanceOf(marketplace.address, tokenId)).to.be.equal(marketplaceBalance);
  });

  it("Does not finish auction for non-existent 1155 item", async () => {
    let listingId: number = 100;
    await expect(marketplace.connect(user2).finishAuction1155(listingId)).to.be.revertedWith("DoesNotExist");
  });

  it("Does not accept bid for 1155 item after auction", async () => {
    let listingId: number = 3;
    let tokenId: number = 1;
    let bid: bigint = price * BigInt(5 * 2);

    let userBalance: BigNumber = await token20.balanceOf(user.address);
    let marketplaceBalance = await token1155.balanceOf(marketplace.address, tokenId);

    await ethers.provider.send('evm_increaseTime', [auctionDuration]);

    await expect(marketplace.connect(user).makeBid1155(
      listingId, bid.toString()
    )).to.be.revertedWith("WrongPeriod");
    expect(await token20.balanceOf(user.address)).to.be.equal(userBalance);
    expect(await token1155.balanceOf(marketplace.address, tokenId)).to.be.equal(marketplaceBalance);
  });

  it("Finishes auction for 1155 item, 2 or less bids", async () => {
    let listingId: number = 3;
    let tokenId: number = 1;
    await ethers.provider.send('evm_increaseTime', [auctionDuration]);
    let marketplaceBalance = await token1155.balanceOf(marketplace.address, tokenId);
    let userBalance = await token1155.balanceOf(user.address, tokenId);
    await expect(marketplace.connect(user2).finishAuction1155(listingId)).to.emit(marketplace, "Item1155FinishedAuction").withArgs(listingId, user.address, price * BigInt(5 * 3));
    expect(await token1155.balanceOf(user.address, tokenId)).to.be.equal(userBalance.add(marketplaceBalance));
  });

  it("Finishes auction for 721 item, more than 2 bids", async () => {
    let listingId: number = 4;
    let tokenId: number = 2;
    let marketplaceBalance = await token1155.balanceOf(marketplace.address, tokenId);
    await expect(marketplace.connect(user2).finishAuction1155(listingId)).to.emit(marketplace, "Item1155FinishedAuction").withArgs(listingId, user2.address, price * BigInt(5 * 4));
    expect(await token1155.balanceOf(user2.address, tokenId)).to.be.equal(marketplaceBalance);
  });
  
});
