// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

// Aave V3 Core imports
import {PoolAddressesProvider} from "aave-v3-core/contracts/protocol/configuration/PoolAddressesProvider.sol";
import {Pool} from "aave-v3-core/contracts/protocol/pool/Pool.sol";
import {PoolConfigurator} from "aave-v3-core/contracts/protocol/pool/PoolConfigurator.sol";
import {IPoolAddressesProvider} from "aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol";

// Utils
import {BaseScript} from "../utils/BaseScript.sol";

/**
 * @title Deploy Core Contracts - Step 4: Pool Implementations
 * @notice Deploys Pool and PoolConfigurator implementations
 * @dev Run with: forge script script/deploy/04_DeployPool.s.sol:DeployPool --rpc-url $RPC_URL --broadcast
 */
contract DeployPool is BaseScript {
    function run() external {
        // Load existing deployment
        string memory existingJson = loadDeployment();
        address poolAddressesProvider = vm.parseJsonAddress(existingJson, ".poolAddressesProvider");
        require(poolAddressesProvider != address(0), "PoolAddressesProvider not found in deployment file");

        logSeparator("DEPLOYING POOL IMPLEMENTATIONS");
        console.log("Using PoolAddressesProvider:", poolAddressesProvider);

        startBroadcastWithInfo();
        
        // Deploy Pool implementation
        Pool pool = new Pool(IPoolAddressesProvider(poolAddressesProvider));
        console.log("Pool implementation deployed at:", address(pool));
        
        // Deploy PoolConfigurator implementation
        PoolConfigurator configurator = new PoolConfigurator();
        console.log("PoolConfigurator implementation deployed at:", address(configurator));
        
        // Set implementations in provider
        PoolAddressesProvider provider = PoolAddressesProvider(poolAddressesProvider);
        provider.setPoolImpl(address(pool));
        provider.setPoolConfiguratorImpl(address(configurator));
        console.log("Pool implementations set in provider");
        
        // Verify proxies were created
        address poolProxy = provider.getPool();
        address configProxy = provider.getPoolConfigurator();
        console.log("Pool Proxy created at:", poolProxy);
        console.log("PoolConfigurator Proxy created at:", configProxy);
        
        stopBroadcastWithInfo();

        verifyAddress(address(pool), "Pool Implementation");
        verifyAddress(address(configurator), "PoolConfigurator Implementation");
        verifyAddress(poolProxy, "Pool Proxy");
        verifyAddress(configProxy, "PoolConfigurator Proxy");

        console.log("DEPLOYMENT SUMMARY:");
        console.log("Pool Implementation:        ", address(pool));
        console.log("PoolConfigurator Implementation:", address(configurator));
        console.log("Pool Proxy:                ", poolProxy);
        console.log("PoolConfigurator Proxy:    ", configProxy);
        
        logSeparator("STEP 4 COMPLETED - PROXIES CREATED");
    }
}