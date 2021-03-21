const FIONFT = artifacts.require("FIONFT");
var Custodians =
[
  '0xBd75376fB6E7eFb1DF19353A43Cd6f9B23ABB2DF',
  '0x7419Bdc9D018fdc77264C9fD8a234eFa1c73BC79',
  '0x996E32a723CFE4afcb30f5eE3DB78808eE816114',
  '0xfa71461858999C1820688a78117D7e0eA8DBcD91',
  '0x763F7dD3662b903aA863190F370b7Cde793c0caC',
  '0x929eb5beF97280FCE4D3F50c23AE15a1c0eD80c2',
  '0xB5cf0289855982A93525E6Bab6B399D4f766AF6d',
  '0x975792Fcb1F7606053B9362ec8BdBF80a681b293',
  '0x7F04130c583474A345A52C769cc46E40C3e2b23e',
  '0xbb8963B0d68DE4669663e987e3a82EA41CA8Fd0d'
]

module.exports = function (deployer) {
  deployer.deploy(FIONFT, Custodians);
};
