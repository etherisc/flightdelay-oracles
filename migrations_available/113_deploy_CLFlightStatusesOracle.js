const Gifcli = require('@etherisc/gifcli');
const { web3utils, logger: { info } } = require('../io/module')(web3, artifacts);
const abiDecoder = require('abi-decoder');

const FlightStatusesOracle = artifacts.require('oracles/CLFlightStatusesOracle.sol');

module.exports = async (deployer, networks, accounts) => {

  const gif = await Gifcli.connect();
  const from = accounts[0];
  const chainLinkTokenAddress = '0xE2e73A1c69ecF83F464EFCE6A5be353a37cA09b2';
  const chainLinkPaymentAmount = 0;
  const chainLinkJobId = 'e67eb5a4072b48ba881863f1b9b57fab';
  const chainLinkOracleAddress = '0xa68bC2d344f69F34f5A7cbb5233f9bF1a270B2f6';

  const InstanceOperatorServiceDeployed = await gif.artifact.get('platform', 'development', 'InstanceOperatorService');
  const QueryDeployed = await gif.artifact.get('platform', 'development', 'Query');
  const OracleServiceDeployed = await gif.artifact.get('platform', 'development', 'OracleService');
  const OracleOwnerServiceDeployed = await gif.artifact.get('platform', 'development', 'OracleOwnerService');
  abiDecoder.addABI(JSON.parse(JSON.parse(QueryDeployed.abi)));

  const InstanceOperatorService = new web3.eth.Contract(
    JSON.parse(JSON.parse(InstanceOperatorServiceDeployed.abi)),
    InstanceOperatorServiceDeployed.address
  );
  const Query = new web3.eth.Contract(
    JSON.parse(JSON.parse(QueryDeployed.abi)),
    QueryDeployed.address
  );
  const OracleOwnerService = new web3.eth.Contract(
    JSON.parse(JSON.parse(OracleOwnerServiceDeployed.abi)),
    OracleOwnerServiceDeployed.address
  );
  const bytes32FlightStatuses = web3utils.bytes(32, 'FlightStatuses');
  const oracleType = await Query.methods.oracleTypes(bytes32FlightStatuses).call();

  if (!oracleType.initialized) {
    info('Propose OracleType');
    await OracleOwnerService.methods.proposeOracleType(
      web3utils.bytes(32, 'FlightStatuses'),
      '(uint256 time,bytes32 carrierFlightNumber,bytes32 departureYearMonthDay)',
      '(bytes1 status,int256 delay)',
      'FlightStatuses oracle'
    )
    .send({ from,  gas: 300000 })
    .on('transactionHash', txHash => info(`transaction hash: ${txHash}\n`));
  } else {
    console.log('OracleType already initialized.')
  }

  if (oracleType.state !== '1') {
    info('Activate FlightStatuses OracleType');
    await InstanceOperatorService.methods.activateOracleType(
      bytes32FlightStatuses
    )
    .send({ from, gas: 200000 })
    .on('transactionHash', txHash => info(`transaction hash: ${txHash}\n`));
  } else {
    console.log('OracleType already activated.')
  }

  // Deploy FlightStatusesOracle
  const flightStatusesOracle = await deployer.deploy(
    FlightStatusesOracle,
    chainLinkTokenAddress,
    chainLinkOracleAddress,
    OracleServiceDeployed.address,
    web3utils.bytes(32, chainLinkJobId),
    chainLinkPaymentAmount,
    {
      //value: 1 * (10 ** 18),
      gas: 4000000,
    },
  );

  info('Propose FlightStatusesOracle as oracle');
  await OracleOwnerService.methods.proposeOracle(
      flightStatusesOracle.address,
      'Chainlink FlightStatuses oracle'
    )
    .send({ from, gas: 200000 })
    .on('transactionHash', txHash => info(`transaction hash: ${txHash}\n`));

  const oracleId = await Query.methods.oracleIdByAddress(flightStatusesOracle.address).call();

  info(`Activate FlightStatuses Oracle, oracleId = ${oracleId}`);
  await InstanceOperatorService.methods.activateOracle(
      oracleId
    )
    .send({ from, gas: 200000 })
    .on('transactionHash', txHash => info(`transaction hash: ${txHash}\n`));

  info('Propose FlightStatusesOracle to FlightStatuses OracleType');
  await OracleOwnerService.methods.proposeOracleToOracleType(
      bytes32FlightStatuses,
      oracleId
    )
    .send({ from, gas: 200000 })
    .on('transactionHash', txHash => info(`transaction hash: ${txHash}\n`));

  info(`Assign FlightStatusesOracle to FlightStatuses OracleType, oracleId = ${oracleId}`);
  await InstanceOperatorService.methods.assignOracleToOracleType(
    bytes32FlightStatuses,
    oracleId
  )
  .send({ from, gas: 200000 })
  .on('transactionHash', txHash => info(`transaction hash: ${txHash}\n`));

};








