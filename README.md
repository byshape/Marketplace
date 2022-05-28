# Description
There is marketplace contract for buying and selling ERC721 and ERC1155 tokens. It's main features:
* Marketplace mints tokens to the caller.
* Marketplace lists items for sale and auction.
* Marketplace cancels listings.
* Marketplace sells items.
* Marketplace accepts bids for listings.
* Marketplace ends auction.

## Launch instructions
Run this command in terminal
```
npm install --save-dev hardhat
```
When installation process is finished, create `.env` file and add `API_URL`, `PRIVATE_KEY` and `ETHERSCAN_API_KEY` variables there.

Run:
* `npx hardhat test` to run tests
* `npx hardhat coverage` to get coverage report
* `npx hardhat run --network rinkeby scripts/deploy-20.ts` to deploy ERC20 smart contract to the rinkeby testnet
* `npx hardhat run --network rinkeby scripts/deploy-721.ts` to deploy ERC721 smart contract to the rinkeby testnet
* `npx hardhat run --network rinkeby scripts/deploy-1155.ts` to deploy ERC1155 smart contract to the rinkeby testnet
* `npx hardhat verify --network rinkeby DEPLOYED_CONTRACT_ADDRESS` to verify marketplace contract or tokens
* `npx hardhat help` to get the list of available tasks, including tasks for interaction with deployed contracts.