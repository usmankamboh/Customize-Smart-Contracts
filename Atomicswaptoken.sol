// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}
contract AtomicSwap {
    struct Swap {
        address initiator;
        address participant;
        address beneficiary;
        address token1;
        address token2;
        uint256 amount1;
        uint256 amount2;
        bytes32 secretHash; 
        bool completed;
    }
    mapping(bytes32 => Swap) public swaps;
    mapping(address => mapping(address => bytes32)) swapID;
    event SwapInitiated(bytes32 indexed swapId,bytes32 secretHash, address indexed initiator, address indexed participant, address token1, address token2, uint256 amount1, uint256 amount2);
    event SwapCompleted(bytes32 indexed swapId);
    function initiateSwap(address beneficiary,address participant,address token1, address token2, uint256 amount1, uint256 amount2) external {
        bytes32 swapId = generateSwapId(msg.sender, participant,token1,token2,amount1,amount2);
        bytes32 secrethash = generateSecretHash(msg.sender);
        require(swaps[swapId].initiator == address(0), "Swap with the given ID already exists");
        IERC20 token = IERC20(token1);
        token.approve(address(this), amount1);
        swaps[swapId] = Swap(msg.sender, participant, beneficiary,token1, token2, amount1, amount2, secrethash,false);
        swapID[msg.sender][participant] = swapId;
        emit SwapInitiated(swapId, secrethash,msg.sender, participant, token1, token2, amount1, amount2);
    }
    function completeSwap(bytes32 swapId,bytes32 secretHash) external {
        Swap storage swap = swaps[swapId];
        require(swap.initiator != address(0), "Swap with the given ID does not exist");
        require(swap.participant == msg.sender, "Only the participant can complete the swap");
        require(!swap.completed, "Swap has already been completed");
        require(swap.secretHash == secretHash, "Invalid secret");
        IERC20 token1 = IERC20(swap.token1);
        IERC20 token2 = IERC20(swap.token2);
        token1.transfer(swap.participant, swap.amount1);
        token2.transfer(swap.beneficiary, swap.amount2);
        swap.completed = true;
        emit SwapCompleted(swapId);
    }
    function generateSwapId(address _sender, address participant, address token1, address token2, uint256 amount1, uint256 amount2) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_sender,participant,token1,token2,amount1, amount2));
    }
    function generateSecretHash(address user) internal pure returns (bytes32) {
        bytes memory addressBytes = new bytes(20);
        for (uint i = 0; i < 20; i++) {
            addressBytes[i] = bytes1(uint8(uint(uint160(user)) / (2**(8*(19 - i)))));
        }
        return keccak256(addressBytes);
    }
    function getSwapId(address initiator,address participient) public view returns(bytes32) {
        return swapID[initiator][participient];
    }
}
