require('dotenv').config()
const gif = require('@etherisc/gif-connect')
const truffleConfig = require('../truffle-config')

const FlightRatingsOracle = artifacts.require('oracles/CLFlightRatingsOracle.sol')
// eslint-disable-next-line no-console
const info = console.log

module.exports = async (deployer, network /* , accounts */) => {
  const { gifRegistry, httpProvider } = truffleConfig.networks[network]
  const gifInstance = new gif.Instance(httpProvider, gifRegistry)

  const oracleServiceAddress = await gifInstance.getOracleServiceAddress()
  const oracleOwnerServiceAddress = await gifInstance.getOracleOwnerServiceAddress()

  const chainLinkTokenAddress = '0xE2e73A1c69ecF83F464EFCE6A5be353a37cA09b2'
  const chainLinkPaymentAmount = 0
  const chainLinkJobId = '0x9f87b3276cbd4651b8a9180b26171c7b'
  const chainLinkOracleAddress = '0xa68bC2d344f69F34f5A7cbb5233f9bF1a270B2f6'

  // Deploy FlightRatingsOracle
  const flightRatingsOracle = await deployer.deploy(
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

  info(`Deployed FlightRatingsOracle at ${flightRatingsOracle.address}`)
}
