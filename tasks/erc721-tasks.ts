import { task } from "hardhat/config";
import { types } from "hardhat/config";
import { HardhatRuntimeEnvironment } from "hardhat/types";

const getContract = async (contract: string, hre:HardhatRuntimeEnvironment) => {
    const erc721Factory = await hre.ethers.getContractFactory("Token721");
    return erc721Factory.attach(contract);
}

task("balance721", "Prints the account balance")
.addParam("contract", "ERC721 address", undefined, types.string)
.addParam("owner", "Owner address", undefined, types.string)
.setAction(async (taskArgs, hre) => {
    let erc721 = await getContract(taskArgs.contract, hre);
    let balance = await erc721.balanceOf(taskArgs.owner);
     console.log(taskArgs.owner, "has balance", balance.toString());
});

task("setApprovalForAll721", "Set approval for all tokens to operator")
.addParam("contract", "ERC721 address", undefined, types.string)
.addParam("to", "Operator address", undefined, types.string)
.addParam("approval", "Grant approval or take it bake", undefined, types.boolean)
.setAction(async (taskArgs, hre) => {
    let erc721 = await getContract(taskArgs.contract, hre);
    await erc721.setApprovalForAll(taskArgs.to, taskArgs.approval);
    console.log(`Approval was set`);
});

task("mint721", "Mints token to address")
.addParam("contract", "ERC721 address", undefined, types.string)
.addParam("to", "Recipient address", undefined, types.string)
.addParam("id", "Token id", undefined, types.string)
.setAction(async (taskArgs, hre) => {
    let erc721 = await getContract(taskArgs.contract, hre);
    await erc721.mint(taskArgs.to, taskArgs.id);
    console.log(`Token was minted`);
});

task("burn721", "Burns token")
.addParam("contract", "ERC721 address", undefined, types.string)
.addParam("id", "Token id", undefined, types.string)
.setAction(async (taskArgs, hre) => {
    let erc721 = await getContract(taskArgs.contract, hre);
    await erc721.burn(taskArgs.id);
    console.log(`Token was burned`);
});

task("tokenURI721", "Gets token's URI")
.addParam("contract", "ERC721 address", undefined, types.string)
.addParam("id", "Token ID", undefined, types.string)
.setAction(async (taskArgs, hre) => {
    let erc721 = await getContract(taskArgs.contract, hre);
    let uri = await erc721.tokenURI(taskArgs.id);
    console.log(`NFT with ID ${taskArgs.id} has URI: ${uri}`);
});

task("setBaseURI721", "Sets tokens' base URI")
.addParam("contract", "ERC721 address", undefined, types.string)
.addParam("uri", "URI address to set", undefined, types.string)
.setAction(async (taskArgs, hre) => {
    let erc721 = await getContract(taskArgs.contract, hre);
    await erc721.setBaseURI(taskArgs.uri);
    console.log(`URI was set`);
});