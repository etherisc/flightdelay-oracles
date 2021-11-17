require('dotenv').config()
const gif = require('@etherisc/gif-connect')
const gifConfig = require('../gif-config')

const FlightRatingsOracle = artifacts.require('TestCLFlightRatingsOracle.sol')
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

  // Deploy FlightRatingsOracle
  await deployer.deploy(
    FlightRatingsOracle,
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
  const flightRatingsOracle = await FlightRatingsOracle.deployed()
  info(`Deployed TestCLFlightRatingsOracle at ${flightRatingsOracle.address}`)
}
