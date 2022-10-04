const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');

var Contract = artifacts.require("FIONFT");
const Custodians =[
  "0x097c3dcBA4f7E3A800ca546D87f62B646F10110E",
  "0x310cbb853e0Ed406ab476012BfD6027cb52Ec88B",
  "0x4178ffC6c78856Fb06777A68E7D5365011CBB0d6",
  "0xA1400826e266D67E1Fc61a176dB663072a0Af920",
  "0x8Aa4aA5B414f8EeB238437449c76e90471D9Fe2E",
  "0x2F278eD46ffE2297C94Ced694Da8622146bA4497",
  "0x2F958E7b420f392B72d8168918eAcb61f0558a68",
  "0xdE227CFBDa437760264b78b5ffe9c65844e89537",
  "0x71fE11C27f5e1980e6b425087d690a0d5d05E458",
  "0xADa6fc39095efc12bB9Dc865D30d4dA0B8F6f784"
]

module.exports = async function (deployer) {
  const instance = await deployProxy(Contract, ["FIONFT Staging", "FIONFT", Custodians], { deployer });
  //const upgraded = await upgradeProxy(instance.address, Contract, {deployer});
};
