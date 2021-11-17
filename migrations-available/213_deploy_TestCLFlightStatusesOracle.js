require('dotenv').config()
const gif = require('@etherisc/gif-connect')
const gifConfig = require('../gif-config')

const FlightStatusesOracle = artifacts.require('TestCLFlightStatusesOracle.sol')
// eslint-disable-next-line no-console
const info = console.log

module.exports = async (deployer, network /* , accounts */) => {
  const {
    gifRegistry,
    httpProvider,
    chainLinkTokenAddress,
    chainLinkPaymentAmount,
    chainLinkJobId,
    chainLinkOracleAddress,
  } = gifConfig.oracleConfig[network]
  info(gifConfig.oracleConfig[network])

  const gifInstance = new gif.Instance(httpProvider, gifRegistry)
  const oracleServiceAddress = await gifInstance.getOracleServiceAddress()
  const oracleOwnerServiceAddress = await gifInstance.getOracleOwnerServiceAddress()

  // Deploy FlightStatusesOracle
  await deployer.deploy(
    FlightStatusesOracle,
    chainLinkTokenAddress,
    chainLinkOracleAddress,
    oracleServiceAddress,
    oracleOwnerServiceAddress,
    chainLinkJobId,
    chainLinkPaymentAmount,
    {
      gas: 6000000,
    },
  )
  const flightStatusesOracle = await FlightStatusesOracle.deployed()
  info(`Deployed TestCLFlightStatusesOracle at ${flightStatusesOracle.address}`)
}
