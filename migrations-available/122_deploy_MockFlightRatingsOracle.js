require('dotenv').config()
const gif = require('@etherisc/gif-connect')

const FlightRatingsOracle = artifacts.require('oracles/MockFlightRatingsOracle.sol')
// eslint-disable-next-line no-console
const info = console.log

module.exports = async (deployer /* , networks, accounts */) => {
  const instance = new gif.Instance(process.env.HTTP_PROVIDER, process.env.GIF_REGISTRY)
  const oracleServiceAddress = await instance.getOracleServiceAddress()
  const oracleOwnerServiceAddress = await instance.getOracleOwnerServiceAddress()
  const flightRatingsOracle = await deployer.deploy(
    FlightRatingsOracle,
    oracleServiceAddress,
    oracleOwnerServiceAddress,
    {
      gas: 4000000,
    },
  )

  info(`Deployed FlightRatingsOracle at ${flightRatingsOracle.address}`)
}
