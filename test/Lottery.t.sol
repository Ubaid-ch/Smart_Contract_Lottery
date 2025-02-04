// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/Lottery.sol";
import "../src/Config.sol";

contract MockVRFCoordinator {
    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 requestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId) {
        // Simulate a successful request
        return 1;
    }
}

contract LotteryTest is Test {
    Lottery public lottery;
    Config public config;
    MockVRFCoordinator public mockVRFCoordinator;

    address public owner = address(0x123);
    address public participant1 = address(0x456);
    address public participant2 = address(0x789);
    address public participant3 = address(0xABC);

    function setUp() public {
        // Deploy the Config contract
        config = new Config();

        // Deploy the mock VRF coordinator
        mockVRFCoordinator = new MockVRFCoordinator();

        // Use Sepolia network configuration for testing
        Config.NetworkConfig memory networkConfig = config.getConfig("sepolia");

        // Override the VRF coordinator with the mock
        networkConfig.vrfCoordinator = address(mockVRFCoordinator);

        // Deploy the Lottery contract
        vm.startPrank(owner);
        lottery = new Lottery(
            networkConfig.vrfCoordinator,
            networkConfig.subscriptionId,
            networkConfig.keyHash,
            networkConfig.callbackGasLimit,
            networkConfig.requestConfirmations,
            1 hours, // Interval: 1 hour
            3        // Minimum participants: 3
        );
        vm.stopPrank();
    }

    // Test entering the lottery
    function testEnterLottery() public {
        vm.startPrank(participant1);
        lottery.enter();
        vm.stopPrank();

        address[] memory participants = lottery.getParticipants();
        assertEq(participants.length, 1);
        assertEq(participants[0], participant1);
    }

    // Test that participants cannot enter when the lottery is picking a winner
    function testCannotEnterWhenPickingWinner() public {
        // Enter participants
        vm.startPrank(participant1);
        lottery.enter();
        vm.stopPrank();

        vm.startPrank(participant2);
        lottery.enter();
        vm.stopPrank();

        vm.startPrank(participant3);
        lottery.enter();
        vm.stopPrank();

        // Start picking a winner
        vm.startPrank(owner);
        lottery.pickWinner();
        vm.stopPrank();

        // Try to enter while picking a winner
        vm.startPrank(participant1);
        vm.expectRevert("Lottery is not open");
        lottery.enter();
        vm.stopPrank();
    }

    // Test that the lottery cannot pick a winner without enough participants
    function testPickWinnerWithoutEnoughParticipants() public {
        vm.startPrank(participant1);
        lottery.enter();
        vm.stopPrank();

        vm.startPrank(owner);
        vm.expectRevert("Not enough participants");
        lottery.pickWinner();
        vm.stopPrank();
    }

    // Test that the lottery can pick a winner with enough participants
    function testPickWinnerWithEnoughParticipants() public {
        // Enter participants
        vm.startPrank(participant1);
        lottery.enter();
        vm.stopPrank();

        vm.startPrank(participant2);
        lottery.enter();
        vm.stopPrank();

        vm.startPrank(participant3);
        lottery.enter();
        vm.stopPrank();

        // Pick a winner
        vm.startPrank(owner);
        lottery.pickWinner();
        vm.stopPrank();

        // Simulate the VRF callback with a random number
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 123456; // Example random number
        vm.startPrank(owner);
        lottery.simulateVRFCallback(randomWords);
        vm.stopPrank();

        // Check that the participants list is reset
        address[] memory participants = lottery.getParticipants();
        assertEq(participants.length, 0);
    }

    // Test that the upkeep is needed when conditions are met
    function testCheckUpkeep() public {
        // Enter participants
        vm.startPrank(participant1);
        lottery.enter();
        vm.stopPrank();

        vm.startPrank(participant2);
        lottery.enter();
        vm.stopPrank();

        vm.startPrank(participant3);
        lottery.enter();
        vm.stopPrank();

        // Fast-forward time to meet the interval condition
        vm.warp(block.timestamp + 1 hours);

        // Check upkeep
        (bool upkeepNeeded, ) = lottery.checkUpkeep("");
        assertTrue(upkeepNeeded);
    }

    // Test that the upkeep is not needed when conditions are not met
    function testCheckUpkeepNotNeeded() public {
        // Enter participants (not enough)
        vm.startPrank(participant1);
        lottery.enter();
        vm.stopPrank();

        // Check upkeep
        (bool upkeepNeeded, ) = lottery.checkUpkeep("");
        assertFalse(upkeepNeeded);
    }

    // Test that the performUpkeep function works
    function testPerformUpkeep() public {
        // Enter participants
        vm.startPrank(participant1);
        lottery.enter();
        vm.stopPrank();

        vm.startPrank(participant2);
        lottery.enter();
        vm.stopPrank();

        vm.startPrank(participant3);
        lottery.enter();
        vm.stopPrank();

        // Fast-forward time to meet the interval condition
        vm.warp(block.timestamp + 1 hours);

        // Perform upkeep
        vm.startPrank(owner);
        lottery.performUpkeep("");
        vm.stopPrank();

        // Simulate the VRF callback with a random number
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = 123456; // Example random number
        vm.startPrank(owner);
        lottery.simulateVRFCallback(randomWords);
        vm.stopPrank();

        // Check that the participants list is reset
        address[] memory participants = lottery.getParticipants();
        assertEq(participants.length, 0);
    }
}