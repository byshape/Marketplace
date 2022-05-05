import { ethers } from "hardhat";

import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

async function getInterface(abi: Array<string>, functions: Array<string>): Promise<string> {
    let interfaceInstance = new ethers.utils.Interface(abi)
    let interfaceId = ethers.BigNumber.from(0);
    for (let i=0; i < functions.length; i++) {
        interfaceId = interfaceId.xor(ethers.BigNumber.from(interfaceInstance.getSighash(functions[i])));
    }
    return interfaceId.toHexString();
}

async function deployContract(contractName: string, signer: SignerWithAddress, ...args: any): Promise<any> {
  const contractFactory = await ethers.getContractFactory(contractName, signer);
  const contract = await contractFactory.deploy(...args);
  return contract.deployed();
}

export { getInterface, deployContract };