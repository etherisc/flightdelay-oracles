const FlightRatingsOracle = artifacts.require('CLFlightRatingsOracle')
const FlightStatusesOracle = artifacts.require('CLFlightStatusesOracle')
const gifConfig = require('../gif-config')

// eslint-disable-next-line no-console
const info = console.log
const uuid2hex = (uuid) => `0x${uuid.replaceAll('-', '')}`

const network = 'xdai'

const doRating = false
const doStatus = true

module.exports = async (callback) => {
  try {
    const {
      // gifRegistry,
      // httpProvider,
      // chainLinkTokenAddress,
      chainLinkPaymentAmount,
      // chainLinkJobId,
      chainLinkOracleAddress,
    } = gifConfig.oracleConfig[network]

    const ratingsJobId = uuid2hex('cbc36a88-6190-4488-a98c-a3ecaeb9d9a1') // job #1
    const statusesJobId = uuid2hex('f9b1bcf6-6c71-498e-85b9-d0bc26e0b11f') // job #3
    // eslint-disable-next-line no-undef
    const fro = await FlightRatingsOracle.deployed()
    const fso = await FlightStatusesOracle.deployed()

    if (doRating) {
      info(`Sending Ratings update transaction, new jobId: ${ratingsJobId} ...`)
      const tx = await fro.updateRequestDetails(
        chainLinkOracleAddress,
        ratingsJobId,
        chainLinkPaymentAmount,
      )
      info('Ratings update, Transaction: ', tx)
    }

    if (doStatus) {
      info(`Sending status update transaction, new jobId: ${statusesJobId} ...`)
      const tx = await fso.updateRequestDetails(
        chainLinkOracleAddress,
        statusesJobId,
        chainLinkPaymentAmount,
      )
      info('Statuses update, sTransaction: ', tx)
    }
  } catch (error) {
    info(error)
    callback(error)
  }

  callback()
}
