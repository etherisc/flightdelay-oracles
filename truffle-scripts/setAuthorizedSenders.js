const ChainlinkOperator = artifacts.require('Operator')
const open = require('open')
// eslint-disable-next-line no-console
const info = console.log

const nodeKey = '0x62697Aded16a116F4416E50e07B5a5B2753D9418'
const showTx = async (tx) => { await open(`https://blockscout.com/xdai/mainnet/tx/${tx}`) }

module.exports = async (callback) => {
  try {
    const Operator = await ChainlinkOperator.deployed()
    const tx = await Operator.setAuthorizedSenders([nodeKey])
    info('setAuthorizedSenders, txHash = ', tx.tx)
    await showTx(tx.tx)
  } catch (error) {
    info(error)
    callback(error)
  }

  callback()
}
