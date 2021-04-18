const Gifcli = require('@etherisc/gifcli');
const { web3utils, logger: { info } } = require('../io/module')(web3, artifacts);
const abiDecoder = require('abi-decoder');

const FlightStatusesOracle = artifacts.require('examples/ChainlinkOracles/CLFlightStatusesOracle.sol');

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

  /*
  info('Propose FlightStatuses OracleType');
  await OracleOwnerService.methods.proposeOracleType(
    web3utils.bytes(32, 'FlightStatuses'),
    '(uint256 time,bytes32 carrierFlightNumber,bytes32 departureYearMonthDay)',
    '(bytes1 status,int256 delay)',
    'FlightStatuses oracle'
  )
  .send({ from,  gas: 300000 })
  .on('transactionHash', txHash => info(`transaction hash: ${txHash}\n`));

  info('Activate FlightStatuses OracleType');
  await InstanceOperatorService.methods.activateOracleType(
    bytes32FlightStatuses
  )
  .send({ from, gas: 200000 })
  .on('transactionHash', txHash => info(`transaction hash: ${txHash}\n`));
  */

  info('Propose FlightStatusesOracle as oracle');
  await new Promise((resolve) => {
    OracleOwnerService.methods.proposeOracle(
      flightStatusesOracle.address,
      'Chainlink FlightStatuses oracle'
    )
    .send({ from, gas: 200000 })
    .on('transactionHash', txHash => info(`transaction hash: ${txHash}\n`))
    .on('receipt', receipt => {
      resolve(receipt);
    });
  });

  const oracleId = await Query.methods.oracleIdByAddress(flightStatusesOracle.address).call();

  info(`Activate FlightStatuses Oracle, oracleId = ${oracleId}`);
  await new Promise((resolve) => {
    InstanceOperatorServiceDeployed
    InstanceOperatorService.methods.activateOracle(
      oracleId
    )
    .send({ from, gas: 200000 })
    .on('transactionHash', txHash => info(`transaction hash: ${txHash}\n`))
    .on('receipt', receipt => {
      resolve(receipt);
    });
  });

  info('Propose FlightStatusesOracle to FlightStatuses OracleType');
  const proposalId = await new Promise(resolve => {
    OracleOwnerService.methods.proposeOracleToType(
      bytes32FlightStatuses,
      oracleId
    )
    .send({ from, gas: 200000 })
    .on('transactionHash', txHash => info(`transaction hash: ${txHash}\n`))
    .on('receipt', async receipt => {
      // console.log(receipt);
      // const logs1 = abiDecoder.decodeLogs(receipt.logs);
      // console.log(JSON.stringify(logs1, null, 2));
      info('Waiting for 10 seconds for tx receipt ...')
      await new Promise((resolve) => setTimeout(resolve, 10000));
      const txHash = receipt.transactionHash;
      const txReceipt = await web3.eth.getTransactionReceipt(txHash);
      const logs = abiDecoder.decodeLogs(txReceipt.logs);
      const LogOracleProposedToType = logs.filter(item => item.name === 'LogOracleProposedToType')[0];
      const proposalIdValue = LogOracleProposedToType.events.filter(item => item.name === 'proposalId')[0];
      resolve(parseInt(proposalIdValue.value));
    });
  });

  info(`Assign FlightStatusesOracle to FlightStatuses OracleType, proposalId = ${proposalId}`);
  await InstanceOperatorService.methods.assignOracleToOracleType(
    bytes32FlightStatuses,
    proposalId
  )
  .send({ from, gas: 200000 })
  .on('transactionHash', txHash => info(`transaction hash: ${txHash}\n`));
};








