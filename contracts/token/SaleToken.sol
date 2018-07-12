pragma solidity ^0.4.13;

import "../zeppelin/contracts/token/StandardToken.sol";
import "../zeppelin/contracts/ownership/Ownable.sol";

import '../zeppelin/contracts/math/SafeMath.sol';

/**
 * Токен продаж
 *
 * ERC-20 токен
 *
 */

contract SaleToken is StandardToken, Ownable {
    using SafeMath for uint;

    /* Описание см. в конструкторе */
    string public name;

    string public symbol;

    uint public decimals;

    address public mintAgent;

    /** Событие обновления токена (имя и символ) */
    event UpdatedTokenInformation(string newName, string newSymbol);

    /**
     * Конструктор
     *
     * @param _name - имя токена
     * @param _symbol - символ токена
     * @param _decimals - кол-во знаков после запятой
     */
    function SaleToken(string _name, string _symbol, uint _decimals) {
        name = _name;
        symbol = _symbol;

        decimals = _decimals;
    }

    /**
     * Может вызвать только агент
     */
    function mint(uint amount) public onlyMintAgent {
        balances[mintAgent] = balances[mintAgent].add(amount);

        totalSupply = balances[mintAgent];
    }

    /**
     * Владелец может обновить инфу по токену
     */
    function setTokenInformation(string _name, string _symbol) external onlyOwner {
        name = _name;
        symbol = _symbol;

        // Вызываем событие
        UpdatedTokenInformation(name, symbol);
    }

    /**
     * Может вызвать только владелец
     * Установить можно только 1 раз
     */
    function setMintAgent(address mintAgentAddress) external emptyMintAgent onlyOwner {
        mintAgent = mintAgentAddress;
    }

    /**
     * Модификаторы
     */
    modifier onlyMintAgent() {
        require(msg.sender == mintAgent);
        _;
    }

    modifier emptyMintAgent() {
        require(mintAgent == 0);
        _;
    }

}
