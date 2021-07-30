const FIONFT = artifacts.require("FIONFT");
var Custodians =
[
  '0x7621d2ff61eb02cae56adeb1428ffb47db3b8324',
  '0x14a9e85107077476fbac5779c069107753fcdd6b',
  '0xf103bd38c31fc2c8d99d711ed5398d2966484388',
  '0x7a0301bcaefd2529ec3780c3282f087279ac481e',
  '0xa82349d996b36e64d8b8903c20a2dcc9659cbe71',
  '0x9c4528d3a8a501a46454336ccf6883a6fb59e97f',
  '0x4763ac7610b3cba72522625238701db72b8f5ed1',
  '0xd7e87c88935fea016a6838f5420fc6b79bd67bf2',
  '0xc24ae0a7a92055828c10521e2cae4f06b01026ce',
  '0xe02F4a2716ED8b81810fBC2aa0375F2D70F1FAeB'
]

module.exports = function (deployer) {
  deployer.deploy(FIONFT, Custodians);
};
