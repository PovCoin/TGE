const Storage = require('../lib/storage.js')

const SaleToken = artifacts.require("./token/SaleToken.sol");
const Sale = artifacts.require('./Sale.sol')

module.exports = function (deployer, network, accounts) {

    const ownerAddress = Storage.ownerAddress;

    let saleTokenInstance = null;

    SaleToken.deployed().then((instance) => {
        saleTokenInstance = instance;

        return saleTokenInstance.setMintAgent(Sale.address, {from: ownerAddress});
    }).then((result) => {

        Sale.deployed().then((instance) => {
            return instance.mintTokens({from: ownerAddress});
        })

    })

}