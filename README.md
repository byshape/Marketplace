# Description
There are standard ERC721 and ERC1155 smart contracts. Their main features:
* ERC721 receives name and symbol to constructor.
* ERC721 and ERC1155 mint tokens by contract minter role to an account.
* ERC721 and ERC1155 burn tokens from an account.
* ERC721 and ERC1155 set up the tokens' metadata URI.
* ERC721 and ERC1155 return the tokens' metadata URI.

## Launch instructions
Run this command in terminal
```
npm install --save-dev hardhat
```
When installation process is finished, create `.env` file and add `API_URL`, `PRIVATE_KEY` and `ETHERSCAN_API_KEY` variables there.

Run:
* `npx hardhat test` to run tests
* `npx hardhat coverage` to get coverage report
* `npx hardhat run --network rinkeby scripts/deploy-721.js` to deploy ERC721 smart contract to the rinkeby testnet
* `npx hardhat run --network rinkeby scripts/deploy-1155.js` to deploy ERC1155 smart contract to the rinkeby testnet
* `npx hardhat verify --network rinkeby DEPLOYED_CONTRACT_ADDRESS` to verify staking contract or ERC20 tokens
* `npx hardhat help` to get the list of available tasks, including tasks for interaction with deployed contract: mint, burn, uri, setURI.
`