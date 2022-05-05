import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";


async function main() {
  let admin: SignerWithAddress;
  [admin] = await ethers.getSigners();

  // deploy token
  const erc721Factory = await ethers.getContractFactory("Token721", admin);
  const erc721 = await erc721Factory.deploy("Test NFT token", "TNFT");
  await erc721.deployed();
  console.log(`erc721 ${erc721.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
