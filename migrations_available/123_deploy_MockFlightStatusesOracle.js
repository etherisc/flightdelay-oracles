require('dotenv').config();
const gif = require('@etherisc/gif-connect');
const { logger: { info } } = require('../io/module')(web3, artifacts);

const FlightStatusesOracle = artifacts.require('oracles/MockFlightStatusesOracle.sol');

module.exports = async (deployer, networks, accounts) => {

  const instance = new gif.Instance(process.env.HTTP_PROVIDER, process.env.GIF_REGISTRY);
  const oracleServiceAddress = await instance.getOracleServiceAddress();
  const oracleOwnerServiceAddress = await instance.getOracleOwnerServiceAddress();
  const flightStatusesOracle = await deployer.deploy(
    FlightStatusesOracle,
    oracleServiceAddress,
    oracleOwnerServiceAddress,
    {
      //value: 1 * (10 ** 18),
      gas: 4000000,
    },
  );

  info(`Deployed FlightStatusesOracle at ${flightStatusesOracle.address}`);

};
