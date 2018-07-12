const Storage = require("../lib/storage.js");

// Подключение смарт контрактов
const SaleToken = artifacts.require("./token/SaleToken.sol");
const Sale = artifacts.require("./Sale.sol");

module.exports = function (deployer, network, accounts) {

    Storage.setProdMode();

    const destinationAddress = Storage.destinationAddress;

    const etherRateInCents = 50000;

    const symbol = Storage.tokenSymbol;
    const name = Storage.tokenName;
    const decimals = Storage.tokenDecimals;

    // Даты начала и окончания продаж
    const startDateTimestamp = Storage.startDateTimestamp;
    const endDateTimestamp = Storage.endDateTimestamp;

    // Деплой
    // Контракт токена
    return deployer.deploy(SaleToken, name, symbol, decimals).then(() => {
        // Контракт для продаж
        return deployer.deploy(Sale, SaleToken.address, startDateTimestamp, endDateTimestamp, etherRateInCents, destinationAddress);
    });

};