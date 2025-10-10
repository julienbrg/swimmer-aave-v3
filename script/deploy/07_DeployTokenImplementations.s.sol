// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

// Aave V3 Core imports
import {AToken} from "../../src/protocol/tokenization/AToken.sol";
import {StableDebtToken} from "../../src/protocol/tokenization/StableDebtToken.sol";
import {VariableDebtToken} from "../../src/protocol/tokenization/VariableDebtToken.sol";
import {IPool} from "../../src/interfaces/IPool.sol";
import {IPoolAddressesProvider} from "../../src/interfaces/IPoolAddressesProvider.sol";

// Utils
import {BaseScript} from "../utils/BaseScript.sol";
import {Constants} from "../utils/Constants.sol";

/**
 * @title Deploy Token Implementations - Step 7
 * @notice Deploys the token implementation contracts (AToken, StableDebtToken, VariableDebtToken)
 * @dev Run with: forge script script/deploy/07_DeployTokenImplementations.s.sol:DeployTokenImplementations --rpc-url $RPC_URL --broadcast
 */
contract DeployTokenImplementations is BaseScript {
    struct TokenImplementations {
        address aTokenImpl;
        address stableDebtTokenImpl;
        address variableDebtTokenImpl;
    }

    function run() external {
        // Check if already deployed
        if (_hasBeenDeployed("07_DeployTokenImplementations.s.sol")) {
            console.log("Token implementations deployment already exists. Skipping deployment.");
            return;
        }

        // Network check removed - script works on any network

        // Get PoolAddressesProvider from step 1's broadcast file
        address poolAddressesProvider = _getPoolAddressesProvider();
        require(poolAddressesProvider != address(0), "PoolAddressesProvider not found. Run step 1 first.");

        logSeparator("DEPLOYING TOKEN IMPLEMENTATIONS");
        console.log("Using PoolAddressesProvider:", poolAddressesProvider);

        TokenImplementations memory tokens;

        startBroadcastWithInfo();
        tokens = _deployTokenImplementations(poolAddressesProvider);
        stopBroadcastWithInfo();

        _verifyDeployment(tokens, poolAddressesProvider);
        _saveDeployment(tokens);

        logSeparator("TOKEN IMPLEMENTATIONS DEPLOYED SUCCESSFULLY");
    }

    function _deployTokenImplementations(address poolAddressesProvider)
        internal
        returns (TokenImplementations memory tokens)
    {
        // Get the Pool proxy address from the PoolAddressesProvider
        IPoolAddressesProvider provider = IPoolAddressesProvider(poolAddressesProvider);
        address poolProxyAddress = provider.getPool();

        if (poolProxyAddress == address(0)) {
            // Pool proxy not created yet, use Pool implementation from step 4's broadcast file
            poolProxyAddress = _getPoolImplementation();
            console.log("Using Pool implementation:", poolProxyAddress);
        } else {
            console.log("Using Pool proxy:", poolProxyAddress);
        }

        require(poolProxyAddress != address(0), "Pool not found in deployment or provider");
        IPool pool = IPool(poolProxyAddress);

        // 1. Deploy AToken implementation
        console.log("\n1. Deploying AToken implementation...");
        tokens.aTokenImpl = address(new AToken(pool));
        console.log("   AToken implementation deployed:", tokens.aTokenImpl);

        // 2. Deploy StableDebtToken implementation
        console.log("\n2. Deploying StableDebtToken implementation...");
        tokens.stableDebtTokenImpl = address(new StableDebtToken(pool));
        console.log("   StableDebtToken implementation deployed:", tokens.stableDebtTokenImpl);

        // 3. Deploy VariableDebtToken implementation
        console.log("\n3. Deploying VariableDebtToken implementation...");
        tokens.variableDebtTokenImpl = address(new VariableDebtToken(pool));
        console.log("   VariableDebtToken implementation deployed:", tokens.variableDebtTokenImpl);

        console.log("\nAll token implementations deployed!");

        return tokens;
    }

    function _verifyDeployment(TokenImplementations memory tokens, address poolAddressesProvider) internal view {
        logSeparator("VERIFYING TOKEN IMPLEMENTATIONS");

        verifyAddress(tokens.aTokenImpl, "AToken Implementation");
        verifyAddress(tokens.stableDebtTokenImpl, "StableDebtToken Implementation");
        verifyAddress(tokens.variableDebtTokenImpl, "VariableDebtToken Implementation");

        // Verify that tokens are correctly configured
        AToken aToken = AToken(tokens.aTokenImpl);
        require(address(aToken.POOL()) != address(0), "AToken POOL not set");

        StableDebtToken stableDebtToken = StableDebtToken(tokens.stableDebtTokenImpl);
        require(address(stableDebtToken.POOL()) != address(0), "StableDebtToken POOL not set");

        VariableDebtToken variableDebtToken = VariableDebtToken(tokens.variableDebtTokenImpl);
        require(address(variableDebtToken.POOL()) != address(0), "VariableDebtToken POOL not set");

        console.log("All token implementation verifications passed!");
    }

    function _saveDeployment(TokenImplementations memory tokens) internal {
        // Contract addresses are automatically saved to broadcast files
        console.log("Token implementations deployed - addresses saved to broadcast files");
    }

    function _logDeploymentSummary(TokenImplementations memory tokens) internal view {
        logSeparator("TOKEN IMPLEMENTATIONS SUMMARY");
        console.log("AToken Implementation:        ", tokens.aTokenImpl);
        console.log("StableDebtToken Implementation:", tokens.stableDebtTokenImpl);
        console.log("VariableDebtToken Implementation:", tokens.variableDebtTokenImpl);

        console.log("\nNext steps:");
        console.log("1. Run 03_DeployInterestRateStrategy.s.sol");
        console.log("2. Configure reserves using these implementations");
    }
}
