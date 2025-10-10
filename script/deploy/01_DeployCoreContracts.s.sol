// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

// Aave V3 Core imports
import {PoolAddressesProvider} from "aave-v3-core/contracts/protocol/configuration/PoolAddressesProvider.sol";

// Utils
import {BaseScript} from "../utils/BaseScript.sol";
import {Constants} from "../utils/Constants.sol";

/**
 * @title Deploy Core Contracts - Step 1: PoolAddressesProvider
 * @notice Deploys the PoolAddressesProvider contract
 * @dev Run with: forge script script/deploy/01_DeployCoreContracts.s.sol:DeployCoreContracts --rpc-url $RPC_URL --broadcast
 */
contract DeployCoreContracts is BaseScript {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        logSeparator("DEPLOYING POOLADDRESSESPROVIDER");
        console.log("Market ID:", Constants.MARKET_ID);
        console.log("Owner:", deployer);

        startBroadcastWithInfo();
        PoolAddressesProvider provider = new PoolAddressesProvider(Constants.MARKET_ID, deployer);
        stopBroadcastWithInfo();

        verifyAddress(address(provider), "PoolAddressesProvider");

        // Save to deployment file
        string memory json = "deployment";
        vm.serializeUint(json, "chainId", block.chainid);
        vm.serializeString(json, "network", block.chainid == 998 ? "hyperevm-testnet" : "unknown");
        vm.serializeUint(json, "timestamp", block.timestamp);
        string memory finalJson = vm.serializeAddress(json, "poolAddressesProvider", address(provider));
        saveDeployment(finalJson);

        console.log("PoolAddressesProvider deployed at:", address(provider));
        logSeparator("STEP 1 COMPLETED - RUN STEP 2 NEXT");
    }
}
