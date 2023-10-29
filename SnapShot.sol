// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

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

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function permit(
        address target,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function transferWithPermit(
        address target,
        address to,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != 0x0 && codehash != accountHash);
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint value
    ) internal {
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

contract SnapShot {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    string _name;
    string _symbol;
    address owner;
    struct info {
        uint256 rewardAmount;
        bool claimed;
    }
    mapping(address => info) holderInfo;
    address[] week1Holders;
    address[] week2Holders;
    mapping(address => uint256) _balanceOf;
    mapping(address => bool) holders;
    uint256 rewardValue = 1000000000000000000;
    uint256 creationTime;
    uint256 reward1Time;
    uint256 reward2Time;
    uint256 timeReset = 50;
    uint256 private _totalSupply;
    bool snaptaken1 = false;
    bool snaptaken2 = false;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Reset();
    event SSTaken();
    event ClaimReward(uint256 amount);
    modifier onlyOwner() {
        require(msg.sender == Owner(), "AnyswapV3ERC20: FORBIDDEN");
        _;
    }

    function Owner() public view returns (address) {
        return owner;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    function mint(
        address to,
        uint256 amount
    ) external onlyOwner returns (bool) {
        _mint(to, amount);
        return true;
    }

    function burn(uint256 amount) external returns (bool) {
        require(msg.sender != address(0), "AnyswapV3ERC20: address(0x0)");
        _burn(msg.sender, amount);
        return true;
    }

    // Records number of AnyswapV3ERC20 token that account (second) will be allowed to spend on behalf of another account (first) through {transferFrom}.
    mapping(address => mapping(address => uint256)) public allowance;

    constructor() {
        _name = "SnapShot";
        _symbol = "SnapShot";
        _mint(msg.sender, 1000000 * 10 ** decimals());
        owner = msg.sender;
        creationTime = block.timestamp;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        if (holders[account] == false) {
            if (snaptaken1 == false) {
                _totalSupply += amount;
                _balanceOf[account] += amount;
                week1Holders.push(account);
                holders[account] = true;
            } else {
                _totalSupply += amount;
                _balanceOf[account] += amount;
                week2Holders.push(account);
                holders[account] = true;
            }
        } else {
            _totalSupply += amount;
            _balanceOf[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");
        _balanceOf[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(to != address(0) || to != address(this));
        uint256 balance = _balanceOf[msg.sender];
        require(
            balance >= amount,
            "AnyswapV3ERC20: transfer amount exceeds balance"
        );
        _transfer(msg.sender, to, amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        require(to != address(0) || to != address(this));
        _allowance(from, to, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        uint256 balance = _balanceOf[from];
        require(balance >= amount, "transfer amount exceeds balance");
        if (holders[to] == false) {
            if (snaptaken1 == false) {
                _balanceOf[from] = balance - amount;
                _balanceOf[to] += amount;
                week1Holders.push(to);
                holders[to] = true;
            } else {
                _balanceOf[from] = balance - amount;
                _balanceOf[to] += amount;
                week2Holders.push(to);
                holders[to] = true;
            }
        } else {
            _balanceOf[from] = balance - amount;
            _balanceOf[to] += amount;
        }
        emit Transfer(from, to, amount);
        return true;
    }

    function _allowance(
        address from,
        address to,
        uint256 amount
    ) internal returns (bool) {
        uint256 allowed = allowance[from][to];
        require(allowed >= amount, "request exceeds allowance");
        uint256 reduced = allowed - amount;
        allowance[from][to] = reduced;
        emit Approval(from, to, reduced);
        return true;
    }

    function transferOwnership(
        address _newowner
    ) public onlyOwner returns (address) {
        owner = _newowner;
        return owner;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balanceOf[account];
    }

    function updateResetTime(uint256 timeInSecond) public onlyOwner {
        timeReset = timeInSecond;
    }

    function snapShot() public payable onlyOwner {
        if (snaptaken1 == true) {
            resetHolder();
            require(msg.value == rewardValue, "value not equal to rewardValue");
            require(
                block.timestamp >= creationTime.add(timeReset),
                "time error 2"
            );
            require(snaptaken1 == false, "snap 1 should be false");
            payable(address(this)).transfer(rewardValue);
            snaptaken2 = true;
            creationTime = block.timestamp;
            reward2Time = block.timestamp;
        } else {
            require(
                block.timestamp >= creationTime.add(timeReset),
                "time error 1"
            );
            require(msg.value == rewardValue, "value not equal to rewardValue");
            payable(address(this)).transfer(rewardValue);
            snaptaken1 = true;
            creationTime = block.timestamp;
            reward1Time = block.timestamp;
        }
        emit SSTaken();
    }

    function resetHolder() internal {
        require(snaptaken1 == true || snaptaken2 == true, "snapshot not taken");
        if (snaptaken2 == true) {
            require(
                block.timestamp >= reward2Time.add(timeReset),
                "time is not completed to reset"
            );
            delete week2Holders;
            snaptaken2 = false;
        } else {
            require(
                block.timestamp >= reward1Time.add(timeReset),
                "Time is not complete to reset"
            );
            delete week1Holders;
            snaptaken1 = false;
        }
        emit Reset();
    }

    function userReward(address holder) public view returns (uint256) {
        return holderInfo[holder].rewardAmount;
    }

    function claimReward() public {
        require(snaptaken1 || snaptaken2, "Snapshot cannot be taken");
        require(!holderInfo[msg.sender].claimed, "User already claimed");
        uint256 perUserReward;
        if (snaptaken2 == true) {
            require(userExists2(msg.sender), "User does not exist");
            require(
                block.timestamp <= reward2Time.add(timeReset),
                "Claimed reward time is up"
            );
            perUserReward = get(msg.sender);
            require(perUserReward > 0, "Reward amount is zero");
            (bool success, ) = payable(msg.sender).call{value: perUserReward}(
                ""
            );
            require(success, "Transfer failed");
            holderInfo[msg.sender].claimed = true;
            holderInfo[msg.sender].rewardAmount = perUserReward;
        } else {
            require(userExists1(msg.sender), "User does not exist");
            require(
                block.timestamp <= reward1Time.add(timeReset),
                "Claim reward time is up"
            );
            perUserReward = get(msg.sender);
            require(perUserReward > 0, "Reward amount is zero");
            (bool success, ) = payable(msg.sender).call{value: perUserReward}(
                ""
            );
            require(success, "Transfer failed");
            holderInfo[msg.sender].claimed = true;
            holderInfo[msg.sender].rewardAmount = perUserReward;
        }
        emit ClaimReward(perUserReward);
    }

    function userExists1(address _user) internal view returns (bool) {
        for (uint256 i = 0; i < week1Holders.length; i++) {
            if (week1Holders[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function userExists2(address _user) internal view returns (bool) {
        for (uint256 i = 0; i < week2Holders.length; i++) {
            if (week2Holders[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function getEthBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawEther(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Insufficient balance");
        payable(owner).transfer(amount);
    }

    function updateRewardValue(uint256 _rewardValue) public onlyOwner {
        rewardValue = _rewardValue;
    }

    // Function to receive Ether
    receive() external payable {
        // This function allows the contract to receive Ether
    }

    function getReward(address holder) public view returns (uint256) {
        return holderInfo[holder].rewardAmount;
    }

    function userClaimed(address holder) public view returns (bool) {
        require(userExists1(holder), "user not exist");
        return holderInfo[holder].claimed;
    }

    function getWeeklyHolders() public view returns (address[] memory) {
        require(
            snaptaken1 == true || snaptaken2 == true,
            "snapshot cannot be taken"
        );
        address[] memory hold;
        if (snaptaken2 == true) {
            hold = week2Holders;
        } else {
            hold = week1Holders;
        }
        return hold;
    }

    function snap1() public view returns (bool) {
        return snaptaken1;
    }

    function snap2() public view returns (bool) {
        return snaptaken2;
    }

    function getSnapshotTime() public view returns (uint256) {
        return creationTime.add(timeReset);
    }

    function getClaimTime(address holder) public view returns (uint256) {
        uint256 time;
        if (snaptaken2 == true) {
            require(userExists2(holder) == true, "user not found");
            time = reward2Time;
        } else {
            require(userExists1(holder), "user not existed");
            time = reward1Time;
        }
        return time;
    }

    function get(address user) public view returns (uint256) {
        uint256 balance = balanceOf(user);
        uint256 holdersCount = calculateTokenHolders(); // Calculate holders count
        require(holdersCount > 0, "No token holders");
        uint256 reward = (rewardValue * balance) / holdersCount; // Correct reward calculation
        return reward;
    }

    function calculateTokenHolders() public view returns (uint256) {
        require(
            snaptaken1 == true || snaptaken2 == true,
            "snapshot cannot e taken"
        );
        uint256 totalBalance;
        if (snaptaken2 == true) {
            for (uint256 i = 0; i < week2Holders.length; i++) {
                address user = week2Holders[i];
                uint256 balance = balanceOf(user);
                totalBalance = totalBalance.add(balance);
            }
        } else {
            for (uint256 i = 0; i < week1Holders.length; i++) {
                address user = week1Holders[i];
                uint256 balance = balanceOf(user);
                totalBalance = totalBalance.add(balance);
            }
        }
        return totalBalance;
    }
}
