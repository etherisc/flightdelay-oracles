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

    const ratingsJobId = uuid2hex('810fb14d-3791-4826-8e7b-8d7861b48e15') // job #31
    const statusesJobId = uuid2hex('243b6e69-a263-4736-a2fb-6185579fa515') // job #29
    // eslint-disable-next-line no-undef
    const fro = await FlightRatingsOracle.deployed()
    const fso = await FlightStatusesOracle.deployed()
    // function updateRequestDetails(
    //         address _oracle,
    //         bytes32 _jobId,
    //         uint256 _payment
    //     ) external onlyOwner() {
    let tx = await fro.updateRequestDetails(
      chainLinkOracleAddress,
      ratingsJobId,
      chainLinkPaymentAmount,
    )
    info('Ratings update, Transaction: ', tx)
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
