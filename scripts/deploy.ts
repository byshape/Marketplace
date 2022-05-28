import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { Token721, Token1155 } from "../typechain";


async function main() {
  let admin: SignerWithAddress;
  [admin] = await ethers.getSigners();

  const auctionDuration: number = 3 * 60; // 3 minutes
  const MINTER_ROLE: string = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER_ROLE"));

  // deploy token
  const marketplaceFactory = await ethers.getContractFactory("Marketplace", admin);
  const marketplace = await marketplaceFactory.deploy();
  await marketplace.deployed();
  console.log(`marketplace ${marketplace.address}`);

  const erc20 = process.env.ERC20_ADDRESS as string;
  const erc721 = <Token721>(await ethers.getContractAt("Token721", process.env.ERC721_ADDRESS as string));
  const erc1155 = <Token1155>(await ethers.getContractAt("Token1155", process.env.ERC1155_ADDRESS as string));
  await erc721.grantRole(MINTER_ROLE, marketplace.address);
  await erc1155.grantRole(MINTER_ROLE, marketplace.address);

  console.log(`erc20 ${erc20}, erc721 ${erc721.address}, erc1155 ${erc1155.address}`);

  await marketplace.setUpConfig(erc721.address, erc1155.address, erc20, auctionDuration.toString());
  console.log("Config was set up");

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
