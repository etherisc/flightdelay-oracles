require('dotenv').config();
const gif = require('@etherisc/gif-connect');
const { web3utils, logger: { info } } = require('../io/module')(web3, artifacts);

const FlightRatingsOracle = artifacts.require('oracles/CLFlightRatingsOracle.sol');

module.exports = async (deployer /*, networks, accounts */ ) => {

  const instance = new gif.Instance(process.env.HTTP_PROVIDER, process.env.GIF_REGISTRY);
  const oracleServiceAddress = await instance.getOracleServiceAddress();
  const oracleOwnerServiceAddress = await instance.getOracleOwnerServiceAddress();

  const chainLinkTokenAddress = '0xE2e73A1c69ecF83F464EFCE6A5be353a37cA09b2';
  const chainLinkPaymentAmount = 0;
  const chainLinkJobId = '9f87b3276cbd4651b8a9180b26171c7b';
  const chainLinkOracleAddress = '0xa68bC2d344f69F34f5A7cbb5233f9bF1a270B2f6';


  // Deploy FlightRatingsOracle
  const flightRatingsOracle = await deployer.deploy(
    FlightRatingsOracle,
    chainLinkTokenAddress,
    chainLinkOracleAddress,
    oracleServiceAddress,
    oracleOwnerServiceAddress,
    web3utils.bytes(32, chainLinkJobId),
    chainLinkPaymentAmount,
    {
      //value: 1 * (10 ** 18),
      gas: 4000000,
    },
  );

  info(`Deployed FlightRatingsOracle at ${flightRatingsOracle.address}`);

};
