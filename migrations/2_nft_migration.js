const FIONFT = artifacts.require("FIONFT");

const { CUSTODIANS_LOCAL, CUSTODIANS_DEVNET, CUSTODIANS_TESTNET } = process.env;
const custodiansLocal = CUSTODIANS_LOCAL.split(',');
const custodiansDevnet = CUSTODIANS_DEVNET.split(',');
const custodiansTestnet = CUSTODIANS_TESTNET.split(',');

module.exports = async function (deployer, network) {
  if (network == "development") {
    await deployer.deploy(FIONFT, custodiansLocal);
  } else if (network == "mumbai_devnet") {
    await deployer.deploy(FIONFT, custodiansDevnet);
  } else if (network == "mumbai_testnet") {
    await deployer.deploy(FIONFT, custodiansTestnet);
  }
};
