module.exports = {
    networks: {
        main: {
            network_id: 1,
            host: '127.0.0.1',
            port: 8548,
            gas: 4712388,
            gasPrice: '50000000000',
            from: '0x651617c5576c489c3ca5cdf11257b246aabde925'
        },

        dev: {
            host: '127.0.0.1',
            port: 8548,
            network_id: '*',
            gas: 4712388,
            gasPrice: '25000000000',
            from: '0x651617c5576c489c3ca5cdf11257b246aabde925'
        },

        local: {
            host: '127.0.0.1',
            port: 8545,
            network_id: '*',
            gas: 4712388
        }
    }
};