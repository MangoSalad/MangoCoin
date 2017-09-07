var mangoCoin = artifacts.require("./mangoCoin.sol");

module.exports = function(deployer) {
  deployer.deploy(mangoCoin);
};
