// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

// Aave V3 Core imports
import {AToken} from "aave-v3-core/contracts/protocol/tokenization/AToken.sol";
import {StableDebtToken} from "aave-v3-core/contracts/protocol/tokenization/StableDebtToken.sol";
import {VariableDebtToken} from "aave-v3-core/contracts/protocol/tokenization/VariableDebtToken.sol";
import {IPool} from "aave-v3-core/contracts/interfaces/IPool.sol";

// Utils
import {BaseScript} from "../utils/BaseScript.sol";
import {Constants} from "../utils/Constants.sol";

/**
 * @title Deploy Token Implementations
 * @notice Deploys the token implementation contracts (AToken, StableDebtToken, VariableDebtToken)
 * @dev Run with: forge script script/deploy/02_DeployTokenImplementations.s.sol:DeployTokenImplementations --rpc-url $HYPEREVM_TESTNET_RPC_URL --broadcast -vvvv
 */
contract DeployTokenImplementations is BaseScript {
    struct TokenImplementations {
        address aTokenImpl;
        address stableDebtTokenImpl;
        address variableDebtTokenImpl;
    }

    function run() external {
        // Verify we're on the correct network
        require(block.chainid == Constants.CHAIN_ID, "Wrong network - expected HyperEVM Testnet");

        // Load existing deployment
        string memory existingDeployment = loadDeployment();
        address poolAddressesProvider = vm.parseJsonAddress(existingDeployment, ".poolAddressesProvider");
        require(
            poolAddressesProvider != address(0), "PoolAddressesProvider not found. Run 01_DeployCoreContracts first."
        );

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
        // 1. Deploy AToken implementation
        console.log("\n1. Deploying AToken implementation...");
        tokens.aTokenImpl = address(new AToken(IPool(poolAddressesProvider)));
        console.log("   AToken implementation deployed:", tokens.aTokenImpl);

        // 2. Deploy StableDebtToken implementation
        console.log("\n2. Deploying StableDebtToken implementation...");
        tokens.stableDebtTokenImpl = address(new StableDebtToken(IPool(poolAddressesProvider)));
        console.log("   StableDebtToken implementation deployed:", tokens.stableDebtTokenImpl);

        // 3. Deploy VariableDebtToken implementation
        console.log("\n3. Deploying VariableDebtToken implementation...");
        tokens.variableDebtTokenImpl = address(new VariableDebtToken(IPool(poolAddressesProvider)));
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
        // Load and modify existing deployment
        string memory existingJson = loadDeployment();

        // Create new JSON with token implementations
        string memory json = "deployment";
        vm.serializeAddress(json, "aTokenImpl", tokens.aTokenImpl);
        vm.serializeAddress(json, "stableDebtTokenImpl", tokens.stableDebtTokenImpl);
        string memory tokensJson = vm.serializeAddress(json, "variableDebtTokenImpl", tokens.variableDebtTokenImpl);

        // For now, just save token implementations. In production, would merge with existing JSON
        saveDeployment(tokensJson);
        console.log("Token implementations added to deployment file");
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
