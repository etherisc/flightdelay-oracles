const axios = require('axios');
const { web3utils, logger: { info } } = require('../io/module')(web3, artifacts);


const InstanceOperatorService = artifacts.require('controllers/InstanceOperatorService.sol');
const OracleService = artifacts.require('controllers/OracleService.sol');
const OracleOwnerService = artifacts.require('controllers/OracleOwnerService.sol');
const FlightStatusesOracle = artifacts.require('examples/ChainlinkOracles/CLFlightStatusesOracle.sol');


module.exports = async (deployer) => {
  [
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

  // Deploy FlightStatusesOracle
  const flightStatusesOracle = await deployer.deploy(
    FlightStatusesOracle, process.env.LINK_TOKEN_ADDRESS, process.env.CHAINLINK_ORACLE_ADDRESS, oracleService.address, web3utils.bytes(32, process.env.CHAINLINK_JOB_ID), process.env.CHAINLINK_PAYMENT_AMOUNT, {
      //value: 1 * (10 ** 18),
      gas: 4500000,
    },
  );

  info('Propose FlightStatuses OracleType');
  await oracleOwnerService.proposeOracleType(
    web3utils.bytes(32, 'FlightStatuses'),
    '(uint256 time,bytes32 carrierFlightNumber,bytes32 departureYearMonthDay)',
    '(bytes1 status,int256 delay)',
    'FlightStatuses oracle',
    { gas: 300000 },
  )
  .on('transactionHash', txHash => info(`transaction hash: ${txHash}\n`));

  info('Propose FlightStatusesOracle as Oracle');
  await oracleOwnerService.proposeOracle(flightStatusesOracle.address, 'FlightStatuses oracle', { gas: 200000 })
  .on('transactionHash', txHash => info(`transaction hash: ${txHash}\n`));

  info('Activate FlightStatuses OracleType');
  await instanceOperator.activateOracleType(web3utils.bytes(32, 'FlightStatuses'), { gas: 200000 })
  .on('transactionHash', txHash => info(`transaction hash: ${txHash}\n`));

  info('Activate FlightStatuses Oracle');
  const oracleId = 1;
  await instanceOperator.activateOracle(oracleId, { gas: 200000 })
  .on('transactionHash', txHash => info(`transaction hash: ${txHash}\n`));

  info('Propose FlightStatusesOracle to FlightStatuses OracleType');
  await oracleOwnerService.proposeOracleToType(web3utils.bytes(32, 'FlightStatuses'), oracleId, { gas: 200000 })
  .on('transactionHash', txHash => info(`transaction hash: ${txHash}\n`));

  info('Assign FlightStatusesOracle to FlightStatuses OracleType');
  const proposalId = 0;
  await instanceOperator.assignOracleToOracleType(web3utils.bytes(32, 'FlightStatuses'), proposalId, { gas: 200000 });
};
