const FIONFT = artifacts.require("FIONFT");

const { CUSTODIANS_LOCAL, CUSTODIANS_DEVNET, CUSTODIANS_TESTNET, CUSTODIANS_MAINNET } = process.env;
const custodiansLocal = CUSTODIANS_LOCAL.split(',');
const custodiansDevnet = CUSTODIANS_DEVNET.split(',');
const custodiansTestnet = CUSTODIANS_TESTNET.split(',');
const custodiansMainnet = CUSTODIANS_MAINNET.split(',');

module.exports = async function (deployer, network) {
  if (network == "development") {
    await deployer.deploy(FIONFT, custodiansLocal);
  } else if (network == "mumbai_devnet") {
    await deployer.deploy(FIONFT, custodiansDevnet);
  } else if (network == "mumbai_testnet" || network == "goerli_testnet") {
    await deployer.deploy(FIONFT, custodiansTestnet);
  } else if (network == "polygon") {
    await deployer.deploy(FIONFT, custodiansMainnet);
  }
};
