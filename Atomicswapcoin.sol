// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
contract AtomicSwapCoin {
    struct Swap {
        address initiator; 
        address participant; 
        uint256 Ethamount;
        bytes32 secretHash; 
        bool completed; 
    }
    mapping(bytes32 => Swap) public swaps; // Mapping of swap ID to Swap struct
    mapping(address => mapping(address => bytes32)) swapID;
    event SwapInitiated(bytes32 indexed swapId, address indexed initiator, address indexed participant, uint256 amount, bytes32 secretHash);
    event SwapCompleted(bytes32 indexed swapId, bytes32 secret);
    function initiateSwap(address participant) external payable returns(bytes32){
        require(msg.value > 0, "Invalid amount");
        bytes32 swapId = generateSwapId(msg.sender, participant, msg.value);
        bytes32 secrethash = generateSecretHash(msg.sender);
        Swap storage swap = swaps[swapId];
        require(swap.initiator == address(0), "Swap ID already exists");
        swap.initiator = msg.sender;
        swap.participant = participant;
        swap.Ethamount = msg.value;
        swap.secretHash = secrethash;
        swap.completed = false;
        swapID[msg.sender][participant] = swapId;
        emit SwapInitiated(swapId, msg.sender, participant, msg.value, secrethash);
        return swapId;
    }

    function completeSwap(bytes32 swapId, bytes32 secret) external payable {
        Swap storage swap = swaps[swapId];
        require(swap.initiator != address(0), "Swap ID does not exist");
        require(swap.completed == false, "Swap already completed");
        require(swap.secretHash == secret, "Invalid secret");
        require(swap.participant == msg.sender,"participient can call");
        (bool sent, ) = swap.participant.call{value: swap.Ethamount}("");
        require(sent, "Failed to send BNB");
        swap.completed = true;
        
        emit SwapCompleted(swapId, secret);
    }
    function generateSwapId(address _sender, address _recipient, uint256 _amount) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_sender, _recipient, _amount));
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
    function getSwapSecret(bytes32 swapId) public view returns(bytes32) {
        Swap storage swap = swaps[swapId];
        return swap.secretHash;
    }
    function getData(bytes32 swapId) public view returns( address initiator,
        address participant,
        uint256 Ethamount,
        bytes32 secretHash, 
        bool completed ){
            Swap storage swap = swaps[swapId];
            return(swap.initiator,swap.participant,swap.Ethamount,swap.secretHash,swap.completed);
    }
}
