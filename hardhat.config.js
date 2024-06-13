require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.24",
  networks: {
    bsctest: {
      url: `https://data-seed-prebsc-1-s1.bnbchain.org:8545`,
      accounts: [process.env.BSCTEST_ACCOUNT_KEY],
    },
    bsc: {
      url: `https://bsc-dataseed3.bnbchain.org`,
      accounts: [process.env.BSCTEST_ACCOUNT_KEY]
    },
    astarzkevm: {
      url: `https://rpc.startale.com/astar-zkevm`,
      accounts: [process.env.BSCTEST_ACCOUNT_KEY]
    },
    astar: {
      url: `https://evm.astar.network`,
      accounts: [process.env.BSCTEST_ACCOUNT_KEY]
    }
  },
  etherscan: {
    apiKey: process.env.BSCSCAN_API_KEY, // Your Etherscan API key
  }
};
