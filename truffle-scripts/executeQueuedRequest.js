const FlightStatusesOracle = artifacts.require('CLFlightStatusesOracle')

// eslint-disable-next-line no-console
const info = console.log

module.exports = async (callback) => {
  try {
    const gifRequestId = 4
    const fso = await FlightStatusesOracle.deployed()
    info(`Executing Queued Request # ${gifRequestId} ...`)
    const tx = await fso.executeQueuedRequest(
      gifRequestId,
    )
    info('Executed, Transaction: ', tx)
  } catch (error) {
    info(error)
    callback(error)
  }

  callback()
}
