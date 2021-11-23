require('dotenv').config()
const gif = require('@etherisc/gif-connect')
const gifConfig = require('../gif-config')

const FlightStatusesOracle = artifacts.require('oracles/CLFlightStatusesOracle.sol')
// eslint-disable-next-line no-console
const info = console.log
const uuid2hex = (uuid) => `0x${uuid.replaceAll('-', '')}`

module.exports = async (deployer, network /* , accounts */) => {
  const {
    gifRegistry,
    httpProvider,
    chainLinkTokenAddress,
    chainLinkPaymentAmount,
    chainLinkStatusesJobId,
    chainLinkOracleAddress,
  } = gifConfig.oracleConfig[network]

  const gifInstance = new gif.Instance(httpProvider, gifRegistry)
  const oracleServiceAddress = await gifInstance.getOracleServiceAddress()
  const oracleOwnerServiceAddress = await gifInstance.getOracleOwnerServiceAddress()

  // Deploy FlightRatingsOracle
  await deployer.deploy(
    FlightStatusesOracle,
    chainLinkTokenAddress,
    chainLinkOracleAddress,
    oracleServiceAddress,
    oracleOwnerServiceAddress,
    uuid2hex(chainLinkStatusesJobId),
    chainLinkPaymentAmount,
    {
      gas: 6000000,
    },
  )
  const flightStatusesOracle = await FlightStatusesOracle.deployed()
  info(`Deployed FlightStatusesOracle at ${flightStatusesOracle.address}`)
}
