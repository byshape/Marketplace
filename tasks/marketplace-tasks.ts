import { task } from "hardhat/config";
import { types } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const getContract = async (contract: string, hre:HardhatRuntimeEnvironment) => {
    const erc721Factory = await hre.ethers.getContractFactory("Marketplace");
    return erc721Factory.attach(contract);
}

task("createItem721", "Mints token to address")
.addParam("contract", "Marketplace address", undefined, types.string)
.addParam("id", "Token id", undefined, types.string)
.setAction(async (taskArgs, hre) => {
    let marketplace = await getContract(taskArgs.contract, hre);
    await marketplace.createItem721(taskArgs.id);
    console.log(`Token was created`);
});

task("listItem721", "Lists token on marketplace")
.addParam("contract", "Marketplace address", undefined, types.string)
.addParam("id", "Token id", undefined, types.string)
.addParam("price", "Item's price", undefined, types.string)
.setAction(async (taskArgs, hre) => {
    let marketplace = await getContract(taskArgs.contract, hre);
    await marketplace.listItem721(taskArgs.id, taskArgs.price);
    console.log(`Token was listed`);
});

task("cancelItem721", "Cancels listing")
.addParam("contract", "Marketplace address", undefined, types.string)
.addParam("id", "Token id", undefined, types.string)
.setAction(async (taskArgs, hre) => {
    let marketplace = await getContract(taskArgs.contract, hre);
    await marketplace.cancelItem721(taskArgs.id);
    console.log(`Listing was cancelled`);
});

task("buyItem721", "Buys item")
.addParam("contract", "Marketplace address", undefined, types.string)
.addParam("id", "Token id", undefined, types.string)
.setAction(async (taskArgs, hre) => {
    let marketplace = await getContract(taskArgs.contract, hre);
    await marketplace.buylItem721(taskArgs.id);
    console.log(`Token was bought`);
});

task("listItemOnAuction721", "Lists token on auction")
.addParam("contract", "Marketplace address", undefined, types.string)
.addParam("id", "Token id", undefined, types.string)
.addParam("price", "Start price", undefined, types.string)
.setAction(async (taskArgs, hre) => {
    let marketplace = await getContract(taskArgs.contract, hre);
    await marketplace.listItemOnAuction721(taskArgs.id, taskArgs.price);
    console.log(`Token was listed`);
});

task("makeBid721", "Makes bid")
.addParam("contract", "Marketplace address", undefined, types.string)
.addParam("id", "Token id", undefined, types.string)
.addParam("price", "Bid", undefined, types.string)
.setAction(async (taskArgs, hre) => {
    let marketplace = await getContract(taskArgs.contract, hre);
    await marketplace.makeBid721(taskArgs.id, taskArgs.price);
    console.log(`Bid was made`);
});

task("finishAuction721", "Finishes auction")
.addParam("contract", "Marketplace address", undefined, types.string)
.addParam("id", "Token id", undefined, types.string)
.setAction(async (taskArgs, hre) => {
    let marketplace = await getContract(taskArgs.contract, hre);
    await marketplace.finishAuction721(taskArgs.id);
    console.log(`Auction was finished`);
});

task("createItem1155", "Mints tokens to address")
.addParam("contract", "Marketplace address", undefined, types.string)
.addParam("id", "Token id", undefined, types.string)
.addParam("amount", "Amount of tokens to mint", undefined, types.string)
.setAction(async (taskArgs, hre) => {
    let marketplace = await getContract(taskArgs.contract, hre);
    await marketplace.createItem1155(taskArgs.id, taskArgs.amount);
    console.log(`Tokens were created`);
});

task("listItem1155", "Lists tokens on marketplace")
.addParam("contract", "Marketplace address", undefined, types.string)
.addParam("id", "Token id", undefined, types.string)
.addParam("amount", "Amount of tokens to list", undefined, types.string)
.addParam("price", "Item's price", undefined, types.string)
.setAction(async (taskArgs, hre) => {
    let marketplace = await getContract(taskArgs.contract, hre);
    await marketplace.listItem1155(taskArgs.id, taskArgs.amount, taskArgs.price);
    console.log(`Tokens were listed`);
});

task("cancelItem1155", "Cancels listings")
.addParam("contract", "Marketplace address", undefined, types.string)
.addParam("id", "Token id", undefined, types.string)
.addParam("amount", "Amount of tokens to cancel", undefined, types.string)
.setAction(async (taskArgs, hre) => {
    let marketplace = await getContract(taskArgs.contract, hre);
    await marketplace.cancelItem1155(taskArgs.id, taskArgs.amount);
    console.log(`Listings for ${taskArgs.amount} tokens were cancelled`);
});

task("buyItem1155", "Buys items")
.addParam("contract", "Marketplace address", undefined, types.string)
.addParam("id", "Token id", undefined, types.string)
.addParam("amount", "Amount of tokens to buy", undefined, types.string)
.setAction(async (taskArgs, hre) => {
    let marketplace = await getContract(taskArgs.contract, hre);
    await marketplace.buylItem1155(taskArgs.id, taskArgs.amount);
    console.log(`Tokens were bought`);
});

task("listItemOnAuction1155", "Lists tokens on auction")
.addParam("contract", "Marketplace address", undefined, types.string)
.addParam("id", "Token id", undefined, types.string)
.addParam("price", "Start price", undefined, types.string)
.addParam("amount", "Amount of tokens to list on auction", undefined, types.string)
.setAction(async (taskArgs, hre) => {
    let marketplace = await getContract(taskArgs.contract, hre);
    await marketplace.listItemOnAuction1155(taskArgs.id, taskArgs.price, taskArgs.amount);
    console.log(`Tokens were listed`);
});

task("makeBid1155", "Makes bid")
.addParam("contract", "Marketplace address", undefined, types.string)
.addParam("id", "Token id", undefined, types.string)
.addParam("price", "Bid", undefined, types.string)
.setAction(async (taskArgs, hre) => {
    let marketplace = await getContract(taskArgs.contract, hre);
    await marketplace.makeBid1155(taskArgs.id, taskArgs.price);
    console.log(`Bid was made`);
});

task("finishAuction1155", "Finishes auction")
.addParam("contract", "Marketplace address", undefined, types.string)
.addParam("id", "Token id", undefined, types.string)
.setAction(async (taskArgs, hre) => {
    let marketplace = await getContract(taskArgs.contract, hre);
    await marketplace.finishAuction1155(taskArgs.id);
    console.log(`Auction was finished`);
});