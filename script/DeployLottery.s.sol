// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Lottery.sol";
import "../src/Config.sol";

contract DeployLottery is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Load network from environment variable
       string memory network = vm.envString("NETWORK");
       //string memory network = vm.envOr("NETWORK", "sepolia");

        // Deploy the Config contract
        Config config = new Config();

        // Get network-specific configuration
        Config.NetworkConfig memory networkConfig = config.getConfig(network);

        // Time and length parameters
        uint256 interval = 30 seconds; // 1 hour interval
        uint256 minParticipants = 3; // Minimum 3 participants

        // Deploy the Lottery contract
        Lottery lottery = new Lottery(
            networkConfig.vrfCoordinator,
            networkConfig.subscriptionId,
            networkConfig.keyHash,
            networkConfig.callbackGasLimit,
            networkConfig.requestConfirmations,
            interval,
            minParticipants
        );

        console.log("Lottery deployed at:", address(lottery));

        vm.stopBroadcast();
    }
}