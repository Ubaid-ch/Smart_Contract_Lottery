// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Config {
    struct NetworkConfig {
        address vrfCoordinator; // Address of the VRF Coordinator
        bytes32 keyHash;        // Key hash for the VRF
        uint64 subscriptionId;  // Subscription ID for VRF
        uint32 callbackGasLimit; // Gas limit for the callback
        uint16 requestConfirmations; // Number of confirmations for the VRF request
    }

    // Network configurations
    NetworkConfig public mainnet;
    NetworkConfig public sepolia;
    NetworkConfig public anvil;

    constructor() {
        // Mainnet configuration
        mainnet = NetworkConfig({
            vrfCoordinator: 0x271682DEB8C4E0901D1a1550aD2e64D568E69909, // Mainnet VRF Coordinator
            keyHash: 0x8af398995b04c28e9951adb9721ef74c74f93e6a478f39e7e0777be13527e7ef, // Mainnet key hash
            subscriptionId: 1, // Replace with your mainnet subscription ID
            callbackGasLimit: 500000, // Gas limit for callback
            requestConfirmations: 3 // Number of confirmations
        });

        // Sepolia configuration
        sepolia = NetworkConfig({
            vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625, // Sepolia VRF Coordinator
            keyHash: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c, // Sepolia key hash
            subscriptionId: 973083600068905571, // Replace with your Sepolia subscription ID
            callbackGasLimit: 500000, // Gas limit for callback
            requestConfirmations: 3 // Number of confirmations
        });

        // Anvil configuration (mock addresses)
        anvil = NetworkConfig({
            vrfCoordinator: 0x5FbDB2315678afecb367f032d93F642f64180aa3, // Anvil VRF Coordinator (mock)
            keyHash: 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311, // Anvil key hash (mock)
            subscriptionId: 1, // Replace with your Anvil subscription ID
            callbackGasLimit: 500000, // Gas limit for callback
            requestConfirmations: 3 // Number of confirmations
        });
    }

    // Function to get configuration for a specific network
    function getConfig(string memory network) public view returns (NetworkConfig memory) {
        if (keccak256(abi.encodePacked(network)) == keccak256(abi.encodePacked("mainnet"))) {
            return mainnet;
        } else if (keccak256(abi.encodePacked(network)) == keccak256(abi.encodePacked("sepolia"))) {
            return sepolia;
        } else if (keccak256(abi.encodePacked(network)) == keccak256(abi.encodePacked("anvil"))) {
            return anvil;
        } else {
            revert("Invalid network");
        }
    }
}