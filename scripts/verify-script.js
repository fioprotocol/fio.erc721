const hre = require("hardhat");
require('dotenv');

const { NAME='WFIO Token Staging', SYMBOL='WFIO', CUSTODIANS, CONTRACT_PROXY_ADDRESS} = process.env
const custodians = CUSTODIANS.split(',');

async function main() {
    await hre.run("verify:verify", {
        address: CONTRACT_PROXY_ADDRESS,
        constructorArguments: [NAME, SYMBOL, 0, custodians],
    })
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })