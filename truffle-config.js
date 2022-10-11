const HDWalletProvider = require('@truffle/hdwallet-provider');
// create a file at the root of your project and name it .env -- there you can set process variables
require('dotenv').config();
const mnemonicDevnet = process.env["MNEMONIC_DEVNET"];
const mnemonicTestnet = process.env["MNEMONIC_TESTNET"];
const appid = process.env["APP_ID"];
const apikey = process.env["POLYGONSCAN_API_KEY"];

module.exports = {

  /**
  * contracts_build_directory tells Truffle where to store compiled contracts
  */
  contracts_build_directory: './build/polygon-contracts',

  /**
  * contracts_directory tells Truffle where the contracts you want to compile are located
  */
  contracts_directory: './contracts/',

  networks: {
    development: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 8545,            // Standard Ethereum port (default: none)
      network_id: "*",       // Any network (default: none)
    },
    // Was getting "FIONFT could not deploy due to insufficient funds" with out gas and gasPrice
    // Current price: https://api-testnet.polygonscan.com/api?module=proxy&action=eth_gasPrice&apikey=YourApiKeyToken
    mumbai_devnet: {
      provider: () => new HDWalletProvider(mnemonicDevnet, "https://polygon-mumbai.infura.io/v3/" + appid),
      network_id: 80001,
      //gas: 9000000,            // Gas Limit, default is 6721975, mumbai migration returned (overall) Block gas limit: 21102957
      //gasPrice: 20000000000,    // Default is 20000000000 (20 Gwei)
      timeoutBlocks: 50,
    },
    mumbai_testnet: {
      provider: () => new HDWalletProvider(mnemonicTestnet, "https://polygon-mumbai.infura.io/v3/" + appid),
      network_id: 80001,
      confirmations: 2,
      timeoutBlocks: 50,
      skipDryRun: true,
      chainId: 80001
    }
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.7",
      settings: {          // See the solidity docs for advice about optimization and evmVersion
        optimizer: {
        enabled: true,
        runs: 200
        },
      }
    },
  },

  // Truffle DB is enabled in this project by default. Enabling Truffle DB surfaces access to the @truffle/db package
  // for querying data about the contracts, deployments, and networks in this project
  db: {
    enabled: true
  },

  // Used to automatically verifiy the contract on etherscan
  api_keys: {
    polygonscan: apikey,
  },
  plugins: [
    'truffle-plugin-verify'
  ],

}
