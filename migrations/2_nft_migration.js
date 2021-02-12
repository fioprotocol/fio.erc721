const FIONFT = artifacts.require("FIONFT");

module.exports = function (deployer) {
  deployer.deploy(FIONFT);
};
