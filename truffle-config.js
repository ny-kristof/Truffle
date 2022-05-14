module.exports = {
  networks: {
    
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*",
      gas: 20000000000
      //gasPrice: 20000000000
    },
    /*
    loc_development2_development2: {
      network_id: "*",
      port: 8545,
      host: "127.0.0.1"
    },
    */
    dashboard: {}
    
  },
  compilers: {
    solc: {
      version: "0.8.13",
      optimizer: {
        enabled: true,
        runs: 1
      }
    }
  },
  db: {
    enabled: false,
    host: "127.0.0.1"
  }
};
