const TronSigVerifierLite = artifacts.require("TronSigVerifierLite");

module.exports = function (deployer) {
  deployer.deploy(TronSigVerifierLite);
};
