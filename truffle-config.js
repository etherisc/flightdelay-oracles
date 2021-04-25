require('dotenv').config();
const HDWalletProvider = require('@truffle/hdwallet-provider');
const { settings } = require('./package');

module.exports = {
  migrations_directory: process.env.MIGRATIONS_DIRECTORY || './migrations',
  contracts_build_directory: process.env.CONTRACTS_BUILD_DIRECTORY || './build',

  networks: {

    development: {
      provider: () => new HDWalletProvider(process.env.MNEMONIC, process.env.HTTP_PROVIDER),
      host: process.env.TRUFFLE_HOST,
      port: process.env.TRUFFLE_PORT,
      network_id: process.env.TRUFFLE_NETWORK_ID,
      gas: process.env.TRUFFLE_GAS,
      gasPrice: process.env.TRUFFLE_GASPRICE,
      websockets: process.env.TRUFFLE_WEBSOCKETS,
      confirmations: process.env.TRUFFLE_CONFIRMATIONS,
    },

    xdai: {
      provider: () => new HDWalletProvider(process.env.MNEMONIC, process.env.HTTP_PROVIDER),
      // provider: () => wallet,
      host: process.env.TRUFFLE_HOST,
      port: process.env.TRUFFLE_PORT,
      network_id: '100', //process.env.TRUFFLE_NETWORK_ID,
      networkCheckTimeout: 999999,
      gas: process.env.TRUFFLE_GAS,
      gasPrice: process.env.TRUFFLE_GASPRICE,
      websockets: process.env.TRUFFLE_WEBSOCKETS,
      confirmations: process.env.TRUFFLE_CONFIRMATIONS,
    },

    coverage: {
      host: 'localhost',
      network_id: '*',
      port: 8555, // the same port as in .solcover.js.
      gas: 0xfffffffffff,
      gasPrice: 0x01,
    },
  },

  mocha: {
    timeout: 30000,
    useColors: true,
  },

  compilers: {
    solc: {
      version: settings.solc,
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
        evmVersion: 'byzantium', // -> constantinople
        evmTarget: 'byzantium', // -> constantinople
      },
    },
  },

  plugins: ['truffle-source-verify']
};
