import { expect } from "chai";
import { ethers } from "hardhat";

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

import { Marketplace, Marketplace__factory } from "../typechain";

import { deployContract } from "./helpers";

describe("Marketplace", function () {
  let admin: SignerWithAddress;
  let user: SignerWithAddress;
  let marketplaceFactory: Marketplace__factory;
  let marketplace: Marketplace;

  const DEFAULT_URI: string = "https://test-uri.com/test-collection/";

  before(async () => {
    // get signers
    [admin, user] = await ethers.getSigners();

    // deploy 

    // deploy Marketplace
    marketplace = await deployContract("Marketplace", admin);

  });

  it("Sets up config", async () => {
    // marketplace.setUpConfig()
  });

  it("Creates item", async () => {
  });
});
