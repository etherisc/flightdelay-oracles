require('dotenv').config()

const hdWalletConfig = {
  development: {
    mnemonic: process.env.DEV_MNEMONIC,
    providerOrUrl: process.env.DEV_HTTP_PROVIDER,
  },
  xdai: {
    mnemonic: process.env.XDAI_MNEMONIC,
    providerOrUrl: process.env.XDAI_HTTP_PROVIDER,
  },
  sokol: {
    mnemonic: process.env.SOKOL_MNEMONIC,
    providerOrUrl: process.env.SOKOL_HTTP_PROVIDER,
    pollingInterval: 200000,
  },
}

const oracleConfig = {
  development: {
    gifRegistry: process.env.DEV_GIF_REGISTRY,
    httpProvider: process.env.DEV_HTTP_PROVIDER,
    chainLinkTokenAddress: process.env.DEV_CHAINLINK_TOKEN,
    chainLinkPaymentAmount: process.env.DEV_CHAINLINK_PAYMENT,
    chainLinkJobId: process.env.DEV_CHAINLINK_JOBID,
    chainLinkOracleAddress: process.env.DEV_CHAINLINK_ORACLE_ADDRESS,
  },
  xdai: {
    gifRegistry: process.env.XDAI_GIF_REGISTRY,
    httpProvider: process.env.XDAI_HTTP_PROVIDER,
    chainLinkTokenAddress: process.env.XDAI_CHAINLINK_TOKEN,
    chainLinkPaymentAmount: process.env.XDAI_CHAINLINK_PAYMENT,
    chainLinkJobId: process.env.XDAI_CHAINLINK_JOBID,
    chainLinkOracleAddress: process.env.XDAI_CHAINLINK_ORACLE_ADDRESS,
  },
  sokol: {
    gifRegistry: process.env.SOKOL_GIF_REGISTRY,
    httpProvider: process.env.SOKOL_HTTP_PROVIDER,
    chainLinkTokenAddress: process.env.SOKOL_CHAINLINK_TOKEN,
    chainLinkPaymentAmount: process.env.SOKOL_CHAINLINK_PAYMENT,
    chainLinkJobId: process.env.SOKOL_CHAINLINK_JOBID,
    chainLinkOracleAddress: process.env.SOKOL_CHAINLINK_ORACLE_ADDRESS,
  },
}

module.exports = { hdWalletConfig, oracleConfig }
