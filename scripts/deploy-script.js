const { ethers, upgrades } = require('hardhat');

require('dotenv');

const { NAME='FIONFT Domain Wrapping Staging', SYMBOL='FIONFT', CUSTODIANS} = process.env

async function main() {
    const FioFactory = await ethers.getContractFactory('FIONFT');
    const custodians = CUSTODIANS.split(',');
    console.log('Deploying FIONFT Oracle Proxy...')
    const fionft = await upgrades.deployProxy(
        FioFactory,
        [NAME, SYMBOL, custodians],
        {
            initializer: 'initialize',
            timeout: 0,
            pollingInterval: 10000
        }
    );
    console.log('deployedProxy', JSON.stringify(fionft));
    await fionft.deployed();
    console.log("FIONFT deployed to:", fionft.address);
}

main()
    .then(() => process.exit(0))
    .catch((err) => {
        console.error(err);
        process.exit(1)
    });