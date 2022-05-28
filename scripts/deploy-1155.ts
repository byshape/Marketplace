import fs from 'fs';
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";


async function main() {
  let admin: SignerWithAddress;
  [admin] = await ethers.getSigners();

  // deploy token
  const erc1155Factory = await ethers.getContractFactory("Token1155", admin);
  const erc1155 = await erc1155Factory.deploy("");
  await erc1155.deployed();
  console.log(`erc1155 ${erc1155.address}`);
  fs.appendFileSync(`.env`, 
    `\rERC1155_ADDRESS=${erc1155.address}\r`)
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
