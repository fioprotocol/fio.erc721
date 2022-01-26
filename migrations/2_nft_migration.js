const { deployProxy, upgradeProxy } = require('@openzeppelin/truffle-upgrades');
const FIONFT = artifacts.require("FIONFT");
var Custodians =[
  '0xf74634D31E30b7f9f06e30dDb7Be729C2f136bb7',
  '0x773171b2977059ffe47b2620bB52e2a5C456ed41',
  '0xDd8D967974b451cF25116E673b987DCD407bc9fc',
  '0x226172d1D968A975688Dcf72346ABBab93E97411',
  '0xDFaA71cAfa2624c403cC8FC18cbC2f9139290fc2',
  '0x61e3D238B0687b7c54F195776F91C2fDa452Fb66',
  '0xDbe7FA5bDab52EEAFfd79c9f382E57fb641C10FF',
  '0x4A66C0f2159989bfD7900658129d43019db9528D',
  '0x3f8d7D92513084318Eca0736806fc316C208cA47',
  '0x1e4a59E644C003FA8e3FdCE77ef9851fCBa2f0c6'
]
module.exports = async function (deployer) {
  const instance = await deployProxy(FIONFT, [Custodians], { deployer });
  //const upgraded = await upgradeProxy(instance.address, FIONFT, {deployer});
};
