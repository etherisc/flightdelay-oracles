const Operator = artifacts.require('Operator.sol')
const gifConfig = require('../gif-config')
// eslint-disable-next-line no-console
const info = console.log

module.exports = async (deployer, network, accounts) => {
  await deployer.deploy(
    Operator,
    gifConfig.oracleConfig[network].chainLinkTokenAddress,
    accounts[0],
    {
      gas: 6000000,
    },
  )
  const operatorContract = await Operator.deployed()
  info(`Deployed Chainlink Operator Contract at ${operatorContract.address} - set .env Variable accordingly!!`)
}
