## Table of Contents

- [Introduction](#introduction)
- [Accessing Remix IDE](#accessing-remix-ide)
- [Loading the Contract](#loading-the-contract)
- [Compiling the Contract](#compiling-the-contract)
- [Deploying the Contract](#deploying-the-contract)
- [Interacting with the Contract](#interacting-with-the-contract)
  - [Adding NFT Types](#adding-nft-types)
  - [Minting NFTs](#minting-nfts)
  - [Querying NFT Types and Ownership](#querying-nft-types-and-ownership)
  - [Managing Contract Settings](#managing-contract-settings)


# How To: Interact with the MyNFT Smart Contract using Remix IDE

## Introduction

The MyNFT Smart Contract is designed for creators and collectors in the Ethereum blockchain ecosystem. It enables the creation and sale of unique digital assets known as Non-Fungible Tokens (NFTs). Each NFT represents ownership of a specific item or asset, with the details and uniqueness being verifiable on the blockchain. This contract uses the ERC721 standard, which is a widely accepted open standard for NFTs on the Ethereum blockchain.

This contract includes features such as adding different types of NFTs, each with its own maximum supply, minting new NFTs with a random selection mechanism, and managing NFT ownership. It also integrates with an ERC20 token for payment purposes, allowing for a seamless and decentralized transaction process.

Whether you are an artist looking to digitize your creations, a game developer seeking to tokenize in-game items, or a digital collector aiming to expand your collection, the MyNFT Smart Contract provides the necessary infrastructure to mint, manage, and transfer your NFTs securely and efficiently.

Now, let's walk through how to deploy and interact with this contract using the Remix IDE, a powerful in-browser IDE that allows for smart contract development and interaction directly from your web browser.

## Accessing Remix IDE

This introduction provides a clear understanding of the contract's purpose, making it easier for users to grasp why they might want to interact with it and what they can achieve by using it.

## Accessing Remix IDE

1. Open your web browser and navigate to [Remix IDE](https://remix.ethereum.org/).
2. Remix will open with a default workspace. You can create a new file or work within the existing files.

## Loading the Contract

1. **Create a New File:**
   In the `File Explorers` tab on the left, click the "Create New File" icon and name it `MyNFT.sol`.

2. **Copy the Contract Code:**
   Copy the entire Solidity contract code provided in this repository.

3. **Paste the Contract Code:**
   Paste the copied code into the newly created `MyNFT.sol` file in Remix.

## Compiling the Contract

1. **Open the Compiler:**
   Click on the `Solidity Compiler` tab on the left sidebar.

2. **Select Compiler Version:**
   Ensure that the compiler version matches the version pragma in your contract (`^0.8.20`). Remix usually selects the correct version automatically.

3. **Compile the Contract:**
   Click the `Compile MyNFT.sol` button to compile your contract.

## Deploying the Contract

1. **Open the Deploy Tab:**
   Click on the `Deploy & Run Transactions` tab on the left sidebar.

2. **Connect to MetaMask:**
   If not already done, connect Remix to your MetaMask wallet by selecting `Injected Web3` in the `Environment` dropdown. Remix will automatically request a connection to MetaMask.

3. **Deploy the Contract:**
   After connecting to MetaMask, click the `Deploy` button to deploy your contract to the selected network. MetaMask will prompt you to confirm the transaction.

## Interacting with the Contract

### Adding NFT Types

1. **Access Deployed Contract:**
   Find your deployed contract in the `Deployed Contracts` section of the `Deploy & Run Transactions` tab.

2. **Use `addNFTType`:**
   Expand the deployed contract, enter the details for the NFT type in the `addNFTType` function inputs, and click the transact button.

### Minting NFTs

1. **Call `mint`:**
   To mint an NFT, simply click on the `mint` function. Ensure you have enough of the ERC20 token used for payment in your wallet.

### Querying NFT Types and Ownership

- **Get NFT Types:**
  Click on the `getNFTTypes` function to retrieve the list of NFT types and their details.

- **Check Owned NFTs:**
  Enter an address into the `tokensOfOwner` input field and click the call button to display the NFTs owned by that address.

### Managing Contract Settings

- **Adjust Mint Price:**
  Enter a new price in the `setMintPrice` input field and click the transact button to update the mint price.

- **Change Payment Receiver:**
  Enter a new address in the `setPaymentReceiver` input field and click the transact button to change the payment receiver.

## Conclusion

You have now learned how to deploy and interact with the MyNFT Smart Contract using Remix IDE. For further assistance or to report issues, please open an issue in this repository or contact mykarma#4885 on Discord.
