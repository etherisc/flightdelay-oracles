require('dotenv').config()
const gif = require('@etherisc/gif-connect')
const gifConfig = require('../gif-config')

const FlightRatingsOracle = artifacts.require('oracles/CLFlightRatingsOracle.sol')
// eslint-disable-next-line no-console
const info = console.log
const uuid2hex = (uuid) => `0x${uuid.replaceAll('-', '')}`

module.exports = async (deployer, network /* , accounts */) => {
  const {
    gifRegistry,
    httpProvider,
    chainLinkTokenAddress,
    chainLinkPaymentAmount,
    chainLinkRatingsJobId,
    chainLinkOracleAddress,
  } = gifConfig.oracleConfig[network]

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
    uuid2hex(chainLinkRatingsJobId),
    chainLinkPaymentAmount,
    {
      gas: 6000000,
    },
  )
  const flightRatingsOracle = await FlightRatingsOracle.deployed()
  info(`Deployed FlightRatingsOracle at ${flightRatingsOracle.address}`)
}
