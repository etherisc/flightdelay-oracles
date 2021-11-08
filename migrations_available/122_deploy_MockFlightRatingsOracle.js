require('dotenv').config();
const gif = require('@etherisc/gif-connect');
const { web3utils, logger: { info } } = require('../io/module')(web3, artifacts);
const abiDecoder = require('abi-decoder');

const FlightRatingsOracle = artifacts.require('oracles/MockFlightRatingsOracle.sol');

module.exports = async (deployer, networks, accounts) => {

  const instance = new gif.Instance(process.env.HTTP_PROVIDER, process.env.GIF_REGISTRY);
  const oracleServiceAddress = await instance.getOracleServiceAddress();
  const oracleOwnerServiceAddress = await instance.getOracleOwnerServiceAddress();
  const flightRatingsOracle = await deployer.deploy(
    FlightRatingsOracle,
    oracleServiceAddress,
    oracleOwnerServiceAddress,
    {
      //value: 1 * (10 ** 18),
      gas: 4000000,
    },
  );

  info(`Deployed FlightRatingsOracle at ${flightRatingsOracle.address}`);

};
