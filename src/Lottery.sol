// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "chainlink/contracts/src/v0.8/vrf/interfaces/VRFCoordinatorV2Interface.sol";
import "chainlink/contracts/src/v0.8/vrf/VRFConsumerBaseV2.sol";
import "chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";

contract Lottery is VRFConsumerBaseV2, AutomationCompatibleInterface {
    // Enum to represent the state of the lottery
    enum LotteryState {
        OPEN,
        PICKING_WINNER
    }

    // State variables
    LotteryState public state;
    uint256 public randomResult;
    address[] public participants;
    address public recentWinner;
    address public owner;
    uint256 public lastWinnerTimestamp;
    uint256 public interval;
    uint256 public minParticipants;

    // Chainlink VRF variables
    VRFCoordinatorV2Interface public vrfCoordinator;
    uint64 public subscriptionId;
    bytes32 public keyHash;
    uint32 public callbackGasLimit;
    uint16 public requestConfirmations;

    // Events
    event RandomNumberGenerated(uint256 randomNumber);
    event WinnerSelected(address winner);
    event NewParticipant(address participant);
    event LotteryStateChanged(LotteryState state);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }

    modifier onlyWhenOpen() {
        require(state == LotteryState.OPEN, "Lottery is not open");
        _;
    }

    // Constructor
    constructor(
        address _vrfCoordinator,
        uint64 _subscriptionId,
        bytes32 _keyHash,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations,
        uint256 _interval,
        uint256 _minParticipants
    ) VRFConsumerBaseV2(_vrfCoordinator) {
        vrfCoordinator = VRFCoordinatorV2Interface(_vrfCoordinator);
        subscriptionId = _subscriptionId;
        keyHash = _keyHash;
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
        interval = _interval;
        minParticipants = _minParticipants;
        owner = msg.sender;
        lastWinnerTimestamp = block.timestamp;
        state = LotteryState.OPEN; // Initialize the state as OPEN
    }

    // Function to enter the lottery
    function enter() public onlyWhenOpen {
        participants.push(msg.sender);
        emit NewParticipant(msg.sender);
    }

    // Function to pick a winner
    function pickWinner() public onlyOwner onlyWhenOpen {
        require(participants.length >= minParticipants, "Not enough participants");
        state = LotteryState.PICKING_WINNER; // Change state to PICKING_WINNER
        emit LotteryStateChanged(state);

        lastWinnerTimestamp = block.timestamp;
        vrfCoordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            1 // Number of random words to request
        );
    }

    // Callback function for VRF
    function fulfillRandomWords(uint256 /* requestId */, uint256[] memory randomWords) internal override {
        require(state == LotteryState.PICKING_WINNER, "Lottery is not picking a winner");

        randomResult = randomWords[0];
        uint256 index = randomResult % participants.length;
        recentWinner = participants[index];

        emit RandomNumberGenerated(randomResult);
        emit WinnerSelected(recentWinner);

        // Reset the participants list and state
        participants = new address[](0);
        state = LotteryState.OPEN;
        emit LotteryStateChanged(state);
    }

    // Chainlink Keeper: Check if upkeep is needed
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timePassed = (block.timestamp - lastWinnerTimestamp) >= interval;
        bool hasEnoughParticipants = participants.length >= minParticipants;
        bool isOpen = state == LotteryState.OPEN;
        upkeepNeeded = timePassed && hasEnoughParticipants && isOpen;
         return (upkeepNeeded, "0x0");
    }

    // Chainlink Keeper: Perform the upkeep
    function performUpkeep(bytes calldata /* performData */) external override {
        require((block.timestamp - lastWinnerTimestamp) >= interval, "Interval not passed");
        require(participants.length >= minParticipants, "Not enough participants");
        require(state == LotteryState.OPEN, "Lottery is not open");
        pickWinner();
    }

    // Function to get the list of participants
    function getParticipants() public view returns (address[] memory) {
        return participants;
    }

    // Helper function for testing: Simulate VRF callback
    function simulateVRFCallback(uint256[] memory randomWords) external {
        require(msg.sender == owner, "Only the owner can call this function");
        fulfillRandomWords(1, randomWords);
    }
}