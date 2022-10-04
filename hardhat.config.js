require("@nomicfoundation/hardhat-toolbox");
require("@nomiclabs/hardhat-etherscan");
require('dotenv').config();

const { INFURA_API_KEY, MNEMONIC_TESTNET, MNEMONIC_DEVNET, POLYGONSCAN_API_KEY } = process.env;

module.exports = {
    solidity: {
        version: "0.8.7",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200
            }
        }
    },
    networks: {
        mumbai_devnet: {
            url: `https://polygon-mumbai.infura.io/v3/${INFURA_API_KEY}`,
            accounts: {
                mnemonic: MNEMONIC_DEVNET,
                path: "m/44'/60'/0'/0",
                initialIndex: 0,
                count: 5,
                passphrase: "",
            },
            network_id: 5,
            gas: 9000000,
        },
        mumbai_testnet: {
            url: `https://polygon-mumbai.infura.io/v3/${INFURA_API_KEY}`,
            accounts: {
                mnemonic: MNEMONIC_TESTNET,
                path: "m/44'/60'/0'/0",
                initialIndex: 0,
                count: 5,
                passphrase: "",
            }
        }
    },
    etherscan: {
        apiKey: POLYGONSCAN_API_KEY
    }
};