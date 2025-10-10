// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

// Aave V3 Core imports
import {PoolAddressesProvider} from "aave-v3-core/contracts/protocol/configuration/PoolAddressesProvider.sol";
import {AaveOracle} from "aave-v3-core/contracts/misc/AaveOracle.sol";
import {AaveProtocolDataProvider} from "aave-v3-core/contracts/misc/AaveProtocolDataProvider.sol";
import {IPoolAddressesProvider} from "aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol";

// Utils
import {BaseScript} from "../utils/BaseScript.sol";
import {Constants} from "../utils/Constants.sol";

/**
 * @title Deploy Core Contracts - Step 5: Oracle and Data Provider
 * @notice Deploys AaveOracle and AaveProtocolDataProvider
 * @dev Run with: forge script script/deploy/05_DeployOracle.s.sol:DeployOracle --rpc-url $RPC_URL --broadcast
 */
contract DeployOracle is BaseScript {
    function run() external {
        // Check if already deployed
        if (_hasBeenDeployed("05_DeployOracle.s.sol")) {
            console.log("Oracle deployment already exists. Skipping deployment.");
            address oracle = _getAaveOracle();
            address dataProvider = _getAaveProtocolDataProvider();
            if (oracle != address(0) && dataProvider != address(0)) {
                console.log("Found existing AaveOracle at:", oracle);
                console.log("Found existing AaveProtocolDataProvider at:", dataProvider);
                return;
            }
        }

        // Get PoolAddressesProvider from step 1's broadcast file
        address poolAddressesProvider = _getPoolAddressesProvider();
        require(poolAddressesProvider != address(0), "PoolAddressesProvider not found. Run step 1 first.");

        logSeparator("DEPLOYING ORACLE AND DATA PROVIDER");
        console.log("Using PoolAddressesProvider:", poolAddressesProvider);

        startBroadcastWithInfo();

        // Deploy AaveOracle (initially with empty assets)
        AaveOracle oracle = new AaveOracle(
            IPoolAddressesProvider(poolAddressesProvider),
            new address[](0), // Empty assets array initially
            new address[](0), // Empty sources array initially
            address(0), // No fallback oracle
            Constants.BASE_CURRENCY,
            Constants.BASE_CURRENCY_UNIT
        );
        console.log("AaveOracle deployed at:", address(oracle));

        // Deploy AaveProtocolDataProvider
        AaveProtocolDataProvider dataProvider =
            new AaveProtocolDataProvider(IPoolAddressesProvider(poolAddressesProvider));
        console.log("AaveProtocolDataProvider deployed at:", address(dataProvider));

        // Set oracle in provider
        PoolAddressesProvider provider = PoolAddressesProvider(poolAddressesProvider);
        provider.setPriceOracle(address(oracle));

        stopBroadcastWithInfo();

        verifyAddress(address(oracle), "AaveOracle");
        verifyAddress(address(dataProvider), "AaveProtocolDataProvider");

        // Contract addresses are automatically saved to broadcast files

        console.log("Oracle set in provider");
        logSeparator("STEP 5 COMPLETED - RUN STEP 6 NEXT");
    }
}
