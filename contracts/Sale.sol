pragma solidity ^0.4.13;

import "./Haltable.sol";

import './zeppelin/contracts/math/SafeMath.sol';
import './token/SaleToken.sol';

/* Контракт Sale части */

contract Sale is Haltable {
    using SafeMath for uint;

    /* Токен, который продаем */
    SaleToken public token;

    /* Собранные средства будут переводиться сюда */
    address public destinationWallet;

    /* Начальное кол-во токенов, которое можно продавать */
    uint public initialTokenSupply = 300000000;

    /* Флаг того, что начальное кол-во токенов переведено на контракт продаж */
    bool public isInitialTokenSupplied = false;

    /* Дополнительное кол-во токенов, которое будет выпущено, в случае покупки 200 млн. токенов с 50% бонусом */
    uint public extendedTokenSupply = 100000000;

    /* Флаг того, что выпущено расширенное кол-во токенов */
    bool public isExtendedTokenSupplied = false;

    /* Старт продаж в формате UNIX timestamp */
    uint public startsAt;

    /* Конец продаж в формате UNIX timestamp */
    uint public endsAt;

    /* Кол-во проданных токенов*/
    uint public tokensSold = 0;

    /* Сколько wei мы получили 10^18 wei = 1 ether */
    uint public weiRaised = 0;

    /* Кол-во уникальных адресов, которые у наc получили токены */
    uint public investorCount = 0;

    /* Кол-во токенов купленных с 50% бонусом */
    uint public customPercentBonusTokensSold = 0;

    /*  Сколько сейчас стоит 1 eth в центах, округленный до целых */
    uint public currentEtherRateInCents;

    /* Текущая стоимость токена в центах */
    uint public oneTokenInCents = 2;

    /* Мапа, адрес инвестора - кол-во эфира */
    mapping (address => uint256) public investedAmountOf;

    /* Мапа адрес инвестора - кол-во выданных токенов */
    mapping (address => uint256) public tokenAmountOf;

    /* Уровни бонуса */
    uint public level1BonusThresholdInCents = 1500000;
    uint public level2BonusThresholdInCents = 5000000;
    uint public level3BonusThresholdInCents = 10000000;

    /* Проценты бонуса */
    uint public level1BonusPercentage = 15;
    uint public level2BonusPercentage = 25;
    uint public level3BonusPercentage = 35;
    uint public level4BonusPercentage = 50;

    /** Возможные состояния
     *
     * - Prefunding: Префандинг, еще не задали дату окончания
     * - Funding: Продажи
     * - Success: Достигли условия завершения
     * - Finished: Продажи окончены
     */
    enum State{PreFunding, Funding, Success, Finished}

    /* Событие покупки токена */
    event Invested(address investor, uint weiAmount, uint tokenAmount);

    /* Событие изменения даты начала продаж */
    event StartsAtChanged(uint newStartsAt);

    /* Событие изменения даты окончания продаж */
    event EndsAtChanged(uint newEndsAt);

    /* Конструктор */
    function Sale(address _token, uint _start, uint _end, uint _currentEtherRateInCents, address _destinationWallet) {
        require(_token != 0);
        require(_destinationWallet != 0);

        // Проверяем даты
        require(_end != 0);
        require(_start != 0);

        token = SaleToken(_token);

        destinationWallet = _destinationWallet;

        startsAt = _start;
        endsAt = _end;

        // Проверяем дату окончания
        require(startsAt < endsAt);

        currentEtherRateInCents = _currentEtherRateInCents;
    }

    /* Устанавливаем порог для бонуса 1-го уровня */
    function setLevel1BonusThresholdInCents(uint value) external onlyOwner {
        level1BonusThresholdInCents = value;
    }

    /* Устанавливаем процент для бонуса 1-го уровня */
    function setLevel1BonusPercentage(uint value) external onlyOwner {
        level1BonusPercentage = value;
    }

    /* Устанавливаем порог для бонуса 2-го уровня */
    function setLevel2BonusThresholdInCents(uint value) external onlyOwner {
        level2BonusThresholdInCents = value;
    }

    /* Устанавливаем процент для бонуса 2-го уровня */
    function setLevel2BonusPercentage(uint value) external onlyOwner {
        level2BonusPercentage = value;
    }

    /* Устанавливаем порог для бонуса 3-го уровня */
    function setLevel3BonusThresholdInCents(uint value) external onlyOwner {
        level3BonusThresholdInCents = value;
    }

    /* Устанавливаем процент для бонуса 3-го уровня */
    function setLevel3BonusPercentage(uint value) external onlyOwner {
        level3BonusPercentage = value;
    }

    /* Устанавливаем процент для бонуса 4-го уровня */
    function setLevel4BonusPercentage(uint value) external onlyOwner {
        level4BonusPercentage = value;
    }
	
    /** Выпускаем на контракт продаж порцию токенов
     *  Выпустить можно только 1 раз
     */
    function mintTokens() external onlyOwner {
        require(!isInitialTokenSupplied);

        token.mint(initialTokenSupply.mul(10 ** token.decimals()));

        isInitialTokenSupplied = true;
    }

    /** Выпускаем на контракт продаж дополнительную порцию токенов
     *  Выпустить можно только 1 раз
     */
    function extendedTokenSupply() external onlyOwner {
        require(!isExtendedTokenSupplied);

        // Если выкуплены 200000000 токенов с заданным бонусом
        require(customPercentBonusTokensSold == (10 ** token.decimals()).mul(200000000));

        token.mint(extendedTokenSupply.mul(10 ** token.decimals()));

        isExtendedTokenSupplied = true;
    }

    /**
     * Fallback функция вызывающаяся при переводе эфира
     */
    function() payable stopInEmergency inState(State.Funding) {
        uint weiAmount = msg.value;
        address receiver = msg.sender;

        uint tokenAmount = 0;

        uint tokenMultiplier = 10 ** token.decimals();

        uint amountInCents = getWeiInCents(weiAmount);

        uint bonusPercentage = 0;

        // Кол-во токенов без бонуса
        uint resultValue = amountInCents.mul(tokenMultiplier).div(oneTokenInCents);

        uint tokensLeft = getTokensLeft();

        // 1 уровень бонусов
        if (amountInCents > 0 && amountInCents < level1BonusThresholdInCents){
            bonusPercentage = level1BonusPercentage;
        // 2 уровень бонусов
        } else if (amountInCents >= level1BonusThresholdInCents && amountInCents < level2BonusThresholdInCents){
            bonusPercentage = level2BonusPercentage;
        // 3 уровень бонусов
        } else if (amountInCents >= level2BonusThresholdInCents && amountInCents < level3BonusThresholdInCents){
            bonusPercentage = level3BonusPercentage;
       // 4 уровень бонусов
        } else if (amountInCents >= level3BonusThresholdInCents){
            bonusPercentage = level4BonusPercentage;

            // Сколько токенов можем засчитать для максимального бонуса
            uint tokensToSend = resultValue;

            if (tokensToSend > tokensLeft){
                tokensToSend = tokensLeft;
            }

            customPercentBonusTokensSold = customPercentBonusTokensSold.add(tokensToSend);
        } else {
            revert();
        }

        // Кол-во токенов с бонусом
        tokenAmount = resultValue.mul(bonusPercentage.add(100)).div(100);

        // Краевой случай, когда запросили больше, чем можем выдать
        if (tokenAmount > tokensLeft){
            tokenAmount = tokensLeft;
        }

        // Кол-во 0?, делаем откат
        require(tokenAmount != 0);

        // Переводим токены инвестору
        assignTokens(receiver, tokenAmount);

        // Шлем на кошелёк эфир
        destinationWallet.transfer(weiAmount);

        // Новый инвестор?
        if (investedAmountOf[receiver] == 0) {
            investorCount++;
        }
        // Обновляем стату
        updateStat(receiver, weiAmount, tokenAmount);

        // Вызываем событие
        Invested(receiver, weiAmount, tokenAmount);
    }

    /**
     * Обновляем стату
     */
    function updateStat(address receiver, uint weiAmount, uint tokenAmount) private {
        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokenAmount);

        investedAmountOf[receiver] = investedAmountOf[receiver].add(weiAmount);
        tokenAmountOf[receiver] = tokenAmountOf[receiver].add(tokenAmount);
    }

    /**
     * Спец. функция, которая позволяет продавать токены вне ценовой политики, доступка только владельцу
     * @param receiver - получатель
     * @param tokenAmount - общее кол-во токенов
     * @param weiAmount - цена в wei, за сколько мы отдали токены
     */
    function preallocate(address receiver, uint tokenAmount, uint weiAmount) external onlyOwner {
        // Обновляем стату
        updateStat(receiver, weiAmount, tokenAmount);

        // Переводим токены инвестору
        assignTokens(receiver, tokenAmount);

        // Вызываем событие
        Invested(receiver, weiAmount, tokenAmount);
    }

    /**
     * Позволяет менять владельцу дату начала
     */
    function setStartsAt(uint time) external onlyOwner {

        startsAt = time;

        // Вызываем событие
        StartsAtChanged(startsAt);
    }

    /**
     * Позволяет менять владельцу дату окончания
     */
    function setEndsAt(uint time) external onlyOwner {
        endsAt = time;

        // Вызываем событие
        EndsAtChanged(endsAt);
    }

    /**
     * Владелец может поменять адрес кошелька для сбора средств
     */
    function setDestinationWallet(address destinationAddress) external onlyOwner {
        destinationWallet = destinationAddress;
    }

    /**
     * Функция, которая задает текущий курс ETH в центах
     */
    function setCurrentEtherRateInCents(uint value) external onlyOwner {
        require(value > 0);

        currentEtherRateInCents = value;
    }

    /**
     * Перевод токенов покупателю
     */
    function assignTokens(address receiver, uint tokenAmount) private {
        token.transfer(receiver, tokenAmount);
    }

    /**
     * Получаем стейт
     */
    function getState() public constant returns (State) {
        if (block.timestamp < startsAt) return State.PreFunding;
        else if (block.timestamp <= endsAt && getTokensLeft() > 0) return State.Funding;
        else return State.Finished;
    }

    /**
     * Функция возвращающая текущую стоимость 1 токена в wei
     */
    function getOneTokenInWei() external constant returns(uint){
        return oneTokenInCents.mul(10 ** 18).div(currentEtherRateInCents);
    }

    /**
     * Функция, которая переводит wei в центы по текущему курсу
     */
    function getWeiInCents(uint value) public constant returns(uint){
        return currentEtherRateInCents.mul(value).div(10 ** 18);
    }

    /**
     * Возвращает кол-во нераспроданных токенов
     */
    function getTokensLeft() public constant returns (uint) {
        return token.balanceOf(address(this));
    }

    /**
    * Модификаторы
    */

    /** Только, если текущее состояние соответсвует состоянию  */
    modifier inState(State state) {
        require(getState() == state);
        _;
    }

}
