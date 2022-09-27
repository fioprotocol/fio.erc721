const { ethers, upgrades } = require('hardhat');
require('dotenv').config();

const { CONTRACT_PROXY_ADDRESS } = process.env;

async function main() {
    const FIONFTV2 = await ethers.getContractFactory('FIONFTV2');
    console.log(`Upgrading FIONFT at ${CONTRACT_PROXY_ADDRESS} to FIONFTV2...`);
    const fionftContractV2 = await upgrades.upgradeProxy(CONTRACT_PROXY_ADDRESS, FIONFTV2);
    console.log(`Upgraded address at: ${fionftContractV2.address}`);
}

main()
    .then(() => process.exit(0))
    .catch((err) => {
        console.log(err);
        process.exit(1)
    });