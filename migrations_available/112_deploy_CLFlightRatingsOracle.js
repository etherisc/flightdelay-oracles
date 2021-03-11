const axios = require('axios');
const { web3utils, logger: { info } } = require('../io/module')(web3, artifacts);


const InstanceOperatorService = artifacts.require('services/InstanceOperatorService.sol');
const OracleService = artifacts.require('services/OracleService.sol');
const OracleOwnerService = artifacts.require('services/OracleOwnerService.sol');
const FlightRatingsOracle = artifacts.require('examples/ChainlinkOracles/CLFlightRatingsOracle.sol');


module.exports = async (deployer) => {
  [
    'FLIGHTSTATS_APP_ID',
    'FLIGHTSTATS_APP_KEY',
    'LINK_TOKEN_ADDRESS',
    'CHAINLINK_ORACLE_ADDRESS',
    'CHAINLINK_JOB_ID',
    'CHAINLINK_PAYMENT_AMOUNT',
  ].forEach(envVar => {
    if (!process.env[envVar]) throw new Error(envVar + ' should be defined');
  });

  const instanceOperator = await InstanceOperatorService.deployed();
  const oracleService = await OracleService.deployed();
  const oracleOwnerService = await OracleOwnerService.deployed();

  // Deploy FlightRatingsOracle
  const flightRatingsOracle = await deployer.deploy(
    FlightRatingsOracle, process.env.LINK_TOKEN_ADDRESS, process.env.CHAINLINK_ORACLE_ADDRESS, oracleService.address, web3utils.bytes(32, process.env.CHAINLINK_JOB_ID), process.env.CHAINLINK_PAYMENT_AMOUNT, {
      //value: 1 * (10 ** 18),
      gas: 4000000,
    },
  );

  info('Propose OracleType');
  await oracleOwnerService.proposeOracleType(
    web3utils.bytes(32, 'FlightRatings'),
    '(bytes32 carrierFlightNumber)',
    '(uint256[6] statistics)',
    'FlightRatings oracle',
    { gas: 300000 },
  )
  .on('transactionHash', txHash => info(`transaction hash: ${txHash}\n`));

  info('Propose FlightRatingsOracle as oracle');
  await oracleOwnerService.proposeOracle(flightRatingsOracle.address, 'FlightRatings oracle', { gas: 200000 })
  .on('transactionHash', txHash => info(`transaction hash: ${txHash}\n`));

  info('Activate FlightRatings OracleType');
  await instanceOperator.activateOracleType(web3utils.bytes(32, 'FlightRatings'), { gas: 200000 })
  .on('transactionHash', txHash => info(`transaction hash: ${txHash}\n`));

  info('Activate FlightRatings Oracle');
  const oracleId = 0;
  await instanceOperator.activateOracle(oracleId, { gas: 200000 })
  .on('transactionHash', txHash => info(`transaction hash: ${txHash}\n`));

  info('Propose FlightRatingsOracle to FlightRatings OracleType');
  await oracleOwnerService.proposeOracleToType(web3utils.bytes(32, 'FlightRatings'), oracleId, { gas: 200000 })
  .on('transactionHash', txHash => info(`transaction hash: ${txHash}\n`));

  info('Assign FlightRatingsOracle to FlightRatings OracleType');
  const proposalId = 0;
  await instanceOperator.assignOracleToOracleType(web3utils.bytes(32, 'FlightRatings'), proposalId, { gas: 200000 })
  .on('transactionHash', txHash => info(`transaction hash: ${txHash}\n`));
};
