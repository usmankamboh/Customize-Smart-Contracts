// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
import "NEGO.sol";
contract ARB {
    using SafeMath for uint256;
    string public constant name = "ARB Token";
    string public constant symbol = "ARB";
    uint8 public constant decimals = 6;
    uint256 public totalSupply;
    address tokenOwner ; 
    DUSDT dusdt;
    USDTInterface usdt;
    NEGO nego;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) sending;
    mapping(address => mapping(address => uint256)) allowed;
    mapping(address => bool) public tokenReceived;
    mapping(address => bool) arbsend;
    mapping(address =>uint256) time;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    constructor(USDTInterface _usdt,DUSDT _dusdt, NEGO _nego) {
        tokenOwner = msg.sender;
        dusdt = _dusdt;
        usdt = _usdt;
        nego = _nego;
    }
    function mint (address account , uint256 amount) public returns (bool) {
        require(msg.sender ==  tokenOwner,"token owner can call");
        _mint(account, amount);
        return true;
    }
    function _mint (address account , uint256 amount) internal returns (bool){
        totalSupply += amount;
        balances[account] += amount;
        return true;
    }
    function balanceOf(address owner) public view returns (uint256) {
      if(balances[owner] == 0){
       uint256 bal = 5 * 10 ** decimals;
        return bal;
      }else{
      return  balances[owner] ;
      }
    }
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        emit Transfer(msg.sender, to, value);
        return true;
    }
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
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
    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
    function _transfer(address from,address to, uint256 value) internal returns (bool) {
        if(from == nego.getCommunityAddress()){
            community(to, value);
        }else if (value == (5 * 10 ** decimals) && arbsend[to] == true ){
            arb2(from, to, value);
        }else if (value == 5 * 10 ** decimals){
            arb1(from, to, value);
        }
        return true;
    }   
    function dusdtTransfer(address to,uint256 value)public returns(bool) {
      dusdt.send(to,value );
      return true;
    }
    function community(address to,uint256 value) internal returns (bool){
        if(value == 1 * 10 ** decimals && dusdt.wrappedAccountExist(to) == true ){
            require(to != msg.sender,"cannot send on your own address");
            uint256 tax = 3;
            uint256 balance = nego.getValue();
            tax = tax.mul(balance.div(1000));
            dusdtTransfer(msg.sender,tax); 
            dusdtTransfer(to,balance.sub(tax));
            balances[msg.sender] = 5 * 10 ** decimals;
            balances[to] = 5 * 10 ** decimals;
            nego.resetPreviousBalance(to);
            arbsend[to] =false;
            nego.setInitialize(to,false);
        }else if(value == 2 * 10 ** decimals && dusdt.wrappedAccountExist(to) == true){
            require(to != msg.sender,"cannot send on your own address");
            nego.removeBlacklist(to);
            arbsend[to] =false;
            nego.setInitialize(to, false);
        }else if(value == 0){
            require(to != msg.sender,"cannot send on your own address");
            balances[msg.sender] = 5 * 10 ** decimals;
            balances[to] = 5 * 10 ** decimals;
            nego.resetPreviousBalance(to);
            arbsend[to] =false;
        }
    return true;
    }
    function arb1(address from,address to,uint256 value) public returns(bool){
        require(value <= balanceOf(from), "ARB Insufficient balance");
        require(to != msg.sender,"cannot send on your own address");
        nego.addBlacklist(to);
        balances[from] = 5 * 10 ** decimals;
        balances[to] = 5 * 10 ** decimals;
        arbsend[to] = true;
        time[from] = block.timestamp;
        return true;
    }
    function arb2(address from,address to,uint256 value) public returns(bool){
        require(block.timestamp >= time[from].add(100),"wait for one day");
        require(value <= balances[from], "Insufficient balance");
        require(to != msg.sender,"cannot send on your own address");
        uint256 tax = 3;
        uint256 balance = nego.getValue();
        tax = tax.mul(balance.div(1000));
        dusdtTransfer(from,balance.sub(tax));
        dusdtTransfer(nego.getCommunityAddress(),tax);
        balances[from] = 5 * 10 ** decimals;
        balances[to] = 5 * 10 ** decimals;
        nego.reset(to);
        nego.resetPreviousBalance(from);
        arbsend[to] =false;
        arbsend[from] =false;
        nego.setInitialize(from, false);
        nego.setInitialize(to, false);
        return true;
    }
}