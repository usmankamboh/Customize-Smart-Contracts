// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;
interface USDTInterface {
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
}
contract USDTWrapper {
    DUSDT dusdtAddress;
    USDTInterface usdtAddress;
    uint256 usdtbalance;
    address public owner;
    constructor(address usdt,address _dusdtAddress) {
        dusdtAddress = DUSDT(_dusdtAddress);
        owner = msg.sender;
        dusdtAddress.transfer(msg.sender,0);
        usdtAddress = USDTInterface(usdt);
    }
    function transferUSDT() public {
        usdtAddress.transfer(address(dusdtAddress), usdtAddress.balanceOf(address(this)));
    }
}
contract DUSDT {
    string public constant name = "DUSD Tether";
    string public constant symbol = "DUSDT";
    uint8 public constant decimals = 6;
    uint256 public totalSupply;
    address tokenOwner ; 
    USDTInterface  usdt;
    USDTWrapper wrappAccount;
    mapping(address => address) wrappedAccount;
    mapping(address => bool) wrapexist;
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    constructor(USDTInterface  _usdt) {
        tokenOwner = msg.sender;
        usdt = _usdt;
    }
    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }
    function _mint(address to,uint256 amount) internal returns(uint256){
        balances[to] += amount;
        totalSupply += amount;
        return balanceOf(to);
    }
    function _transfer(address from,address to, uint256 value) internal returns (bool) {
        if(to == from && value==0){
            createWrappingAccount();  
        }else if(to == getWrappedAccount(from) && value== 0){
            _mint(msg.sender, usdt.balanceOf(getWrappedAccount(from)));
            wrappAccount.transferUSDT();
        }else if (to == getWrappedAccount(from) && value > 0){
            tranferUSDT(msg.sender, value);
            balances[address(this)] +=value;
            balances[from] -= value;
        }else  {
            balances[to] += value;
            balances[from] -= value;
        }
        emit Transfer(from, to, value);
        return true;
    }
    function transfer(address to, uint256 value) public{
        _transfer(msg.sender,to, value);
    } 
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= balances[from], "DUSDT Insufficient balance");
        _transfer(from,to, value);
        emit Transfer(from, to, value);
        return true;
    }
    function approve(address spender, uint256 value) public returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }
    function createWrappingAccount() internal {
        wrappAccount = new USDTWrapper(address(usdt),address(this));
        wrappedAccount[msg.sender]= address(wrappAccount);
        wrapexist[address(wrappAccount)] = true;
    }
    function getWrappedAccount(address user) public  view returns (address){
        return wrappedAccount[user];
    }
    function wrappedAccountExist(address user) public view returns (bool){
        return wrapexist[getWrappedAccount(user)];
    }
    function send(address to, uint256 value) external returns (bool) {
        balances[to] += value;
        balances[address(this)] -= value;
        emit Transfer(msg.sender, to, value);
        return true;
    }
    function tranferUSDT(address to,uint256 value) public {
        usdt.transfer(to, value);
    }

}