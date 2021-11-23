const FlightRatingsOracle = artifacts.require('CLFlightRatingsOracle')
const FlightStatusesOracle = artifacts.require('CLFlightStatusesOracle')
const gifConfig = require('../gif-config')

// eslint-disable-next-line no-console
const info = console.log
const uuid2hex = (uuid) => `0x${uuid.replaceAll('-', '')}`

const network = 'xdai'

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

    const ratingsJobId = uuid2hex('cbc36a88-6190-4488-a98c-a3ecaeb9d9a1') // job #31
    const statusesJobId = uuid2hex('76210948-801e-49f9-b612-7d2843fab1c4') // job #29
    // eslint-disable-next-line no-undef
    const fro = await FlightRatingsOracle.deployed()
    const fso = await FlightStatusesOracle.deployed()
    // function updateRequestDetails(
    //         address _oracle,
    //         bytes32 _jobId,
    //         uint256 _payment
    //     ) external onlyOwner() {
    info(`Sending Ratings update transaction, new jobId: ${ratingsJobId} ...`)
    let tx = await fro.updateRequestDetails(
      chainLinkOracleAddress,
      ratingsJobId,
      chainLinkPaymentAmount,
    )
    info('Ratings update, Transaction: ', tx)

    info(`Sending status update transaction, new jobId: ${statusesJobId} ...`)
    tx = await fso.updateRequestDetails(
      chainLinkOracleAddress,
      statusesJobId,
      chainLinkPaymentAmount,
    )
    info('Statuses update, sTransaction: ', tx)
  } catch (error) {
    info(error)
    callback(error)
  }

  callback()
}
