// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

// Aave V3 Core imports
import {PoolAddressesProvider} from "aave-v3-core/contracts/protocol/configuration/PoolAddressesProvider.sol";
import {PoolAddressesProviderRegistry} from
    "aave-v3-core/contracts/protocol/configuration/PoolAddressesProviderRegistry.sol";
import {Pool} from "aave-v3-core/contracts/protocol/pool/Pool.sol";
import {PoolConfigurator} from "aave-v3-core/contracts/protocol/pool/PoolConfigurator.sol";
import {ACLManager} from "aave-v3-core/contracts/protocol/configuration/ACLManager.sol";
import {AaveOracle} from "aave-v3-core/contracts/misc/AaveOracle.sol";
import {AaveProtocolDataProvider} from "aave-v3-core/contracts/misc/AaveProtocolDataProvider.sol";
import {IPoolAddressesProvider} from "aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol";

// Utils
import {BaseScript} from "../utils/BaseScript.sol";
import {Constants} from "../utils/Constants.sol";

/**
 * @title Deploy Core Contracts
 * @notice Deploys the core Aave V3.0 contracts for HyperEVM Testnet
 * @dev Run with: forge script script/deploy/01_DeployCoreContracts.s.sol:DeployCoreContracts --rpc-url $HYPEREVM_TESTNET_RPC_URL --broadcast -vvvv
 */
contract DeployCoreContracts is BaseScript {
    struct DeploymentParams {
        string marketId;
        address owner;
        address emergencyAdmin;
        address[] priceOracleAssets;
        address[] priceOracleSources;
        address fallbackOracle;
        address baseCurrency;
        uint256 baseCurrencyUnit;
    }

    struct CoreContracts {
        address poolAddressesProvider;
        address poolAddressesProviderRegistry;
        address pool;
        address poolConfigurator;
        address aclManager;
        address oracle;
        address protocolDataProvider;
    }

    function run() external {
        // Verify we're on the correct network
        require(block.chainid == Constants.CHAIN_ID, "Wrong network - expected HyperEVM Testnet");

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        DeploymentParams memory params = DeploymentParams({
            marketId: Constants.MARKET_ID,
            owner: deployer, // In production, this should be a multisig/governance contract
            emergencyAdmin: deployer, // In production, this should be a separate emergency multisig
            priceOracleAssets: new address[](0), // Will be populated when adding reserves
            priceOracleSources: new address[](0), // Will be populated when adding reserves
            fallbackOracle: address(0), // No fallback oracle initially
            baseCurrency: Constants.BASE_CURRENCY,
            baseCurrencyUnit: Constants.BASE_CURRENCY_UNIT
        });

        logSeparator("DEPLOYING AAVE V3.0 CORE CONTRACTS");
        console.log("Market ID:", params.marketId);
        console.log("Owner:", params.owner);
        console.log("Emergency Admin:", params.emergencyAdmin);

        CoreContracts memory contracts;

        startBroadcastWithInfo();
        contracts = _deployCoreContracts(params);
        stopBroadcastWithInfo();

        _verifyDeployment(contracts);
        _saveDeployment(contracts);

        logSeparator("DEPLOYMENT COMPLETED SUCCESSFULLY");
    }

    function _deployCoreContracts(DeploymentParams memory params) internal returns (CoreContracts memory contracts) {
        // 1. Deploy PoolAddressesProvider
        console.log("\n1. Deploying PoolAddressesProvider...");
        contracts.poolAddressesProvider = address(new PoolAddressesProvider(params.marketId, params.owner));
        console.log("   PoolAddressesProvider deployed:", contracts.poolAddressesProvider);

        // 2. Deploy PoolAddressesProviderRegistry
        console.log("\n2. Deploying PoolAddressesProviderRegistry...");
        contracts.poolAddressesProviderRegistry = address(new PoolAddressesProviderRegistry(params.owner));
        console.log("   PoolAddressesProviderRegistry deployed:", contracts.poolAddressesProviderRegistry);

        // Register the provider in the registry
        PoolAddressesProviderRegistry(contracts.poolAddressesProviderRegistry).registerAddressesProvider(
            contracts.poolAddressesProvider, 1
        );
        console.log("   PoolAddressesProvider registered in registry");

        // 3. Set ACL Admin in PoolAddressesProvider (required before ACLManager deployment)
        console.log("\n3. Setting ACL Admin in PoolAddressesProvider...");
        PoolAddressesProvider(contracts.poolAddressesProvider).setACLAdmin(params.owner);
        console.log("   ACL Admin set:", params.owner);

        // 4. Deploy ACLManager
        console.log("\n4. Deploying ACLManager...");
        contracts.aclManager = address(new ACLManager(IPoolAddressesProvider(contracts.poolAddressesProvider)));
        console.log("   ACLManager deployed:", contracts.aclManager);

        // Set ACLManager in PoolAddressesProvider
        PoolAddressesProvider(contracts.poolAddressesProvider).setACLManager(contracts.aclManager);
        console.log("   ACLManager set in PoolAddressesProvider");

        // 5. Deploy Pool implementation
        console.log("\n5. Deploying Pool implementation...");
        contracts.pool = address(new Pool(IPoolAddressesProvider(contracts.poolAddressesProvider)));
        console.log("   Pool implementation deployed:", contracts.pool);

        // 6. Deploy PoolConfigurator implementation
        console.log("\n6. Deploying PoolConfigurator implementation...");
        contracts.poolConfigurator = address(new PoolConfigurator());
        console.log("   PoolConfigurator implementation deployed:", contracts.poolConfigurator);

        // 7. Deploy AaveOracle
        console.log("\n7. Deploying AaveOracle...");
        contracts.oracle = address(
            new AaveOracle(
                IPoolAddressesProvider(contracts.poolAddressesProvider),
                params.priceOracleAssets,
                params.priceOracleSources,
                params.fallbackOracle,
                params.baseCurrency,
                params.baseCurrencyUnit
            )
        );
        console.log("   AaveOracle deployed:", contracts.oracle);

        // 8. Deploy AaveProtocolDataProvider
        console.log("\n8. Deploying AaveProtocolDataProvider...");
        contracts.protocolDataProvider =
            address(new AaveProtocolDataProvider(IPoolAddressesProvider(contracts.poolAddressesProvider)));
        console.log("   AaveProtocolDataProvider deployed:", contracts.protocolDataProvider);

        // 9. Set implementations in PoolAddressesProvider
        console.log("\n9. Setting implementations in PoolAddressesProvider...");
        PoolAddressesProvider provider = PoolAddressesProvider(contracts.poolAddressesProvider);

        provider.setPoolImpl(contracts.pool);
        console.log("   Pool implementation set");

        provider.setPoolConfiguratorImpl(contracts.poolConfigurator);
        console.log("   PoolConfigurator implementation set");

        provider.setPriceOracle(contracts.oracle);
        console.log("   PriceOracle set");

        // 10. Setup initial admin roles
        console.log("\n10. Setting up initial admin roles...");
        ACLManager aclManager = ACLManager(contracts.aclManager);

        // Add deployer as initial admin (should be changed to governance later)
        aclManager.addPoolAdmin(params.owner);
        console.log("   Pool Admin set:", params.owner);

        aclManager.addEmergencyAdmin(params.emergencyAdmin);
        console.log("   Emergency Admin set:", params.emergencyAdmin);

        // Add deployer as asset listing admin for initial setup
        aclManager.addAssetListingAdmin(params.owner);
        console.log("   Asset Listing Admin set:", params.owner);

        console.log("\nAll core contracts deployed and configured!");

        return contracts;
    }

    function _verifyDeployment(CoreContracts memory contracts) internal view {
        logSeparator("VERIFYING DEPLOYMENT");

        verifyAddress(contracts.poolAddressesProvider, "PoolAddressesProvider");
        verifyAddress(contracts.poolAddressesProviderRegistry, "PoolAddressesProviderRegistry");
        verifyAddress(contracts.aclManager, "ACLManager");
        verifyAddress(contracts.pool, "Pool");
        verifyAddress(contracts.poolConfigurator, "PoolConfigurator");
        verifyAddress(contracts.oracle, "AaveOracle");
        verifyAddress(contracts.protocolDataProvider, "AaveProtocolDataProvider");

        // Verify configurations
        PoolAddressesProvider provider = PoolAddressesProvider(contracts.poolAddressesProvider);

        require(provider.getPool() != address(0), "Pool not set in provider");
        require(provider.getPoolConfigurator() != address(0), "PoolConfigurator not set in provider");
        require(provider.getPriceOracle() == contracts.oracle, "Oracle mismatch in provider");
        require(provider.getACLManager() == contracts.aclManager, "ACLManager mismatch in provider");

        console.log("All verifications passed!");
    }

    function _saveDeployment(CoreContracts memory contracts) internal {
        string memory json = "deployment";

        // Network info
        vm.serializeUint(json, "chainId", block.chainid);
        vm.serializeString(json, "network", "hyperevm-testnet");
        vm.serializeUint(json, "timestamp", block.timestamp);

        // Core contracts
        vm.serializeAddress(json, "poolAddressesProvider", contracts.poolAddressesProvider);
        vm.serializeAddress(json, "poolAddressesProviderRegistry", contracts.poolAddressesProviderRegistry);
        vm.serializeAddress(json, "aclManager", contracts.aclManager);
        vm.serializeAddress(json, "pool", contracts.pool);
        vm.serializeAddress(json, "poolConfigurator", contracts.poolConfigurator);
        vm.serializeAddress(json, "oracle", contracts.oracle);
        string memory finalJson = vm.serializeAddress(json, "protocolDataProvider", contracts.protocolDataProvider);

        saveDeployment(finalJson);
    }

    function _logDeploymentSummary(CoreContracts memory contracts) internal view {
        logSeparator("DEPLOYMENT SUMMARY");
        console.log("PoolAddressesProvider:        ", contracts.poolAddressesProvider);
        console.log("PoolAddressesProviderRegistry:", contracts.poolAddressesProviderRegistry);
        console.log("Pool:                        ", contracts.pool);
        console.log("PoolConfigurator:            ", contracts.poolConfigurator);
        console.log("ACLManager:                  ", contracts.aclManager);
        console.log("AaveOracle:                  ", contracts.oracle);
        console.log("AaveProtocolDataProvider:    ", contracts.protocolDataProvider);

        console.log("\nNext steps:");
        console.log("1. Run 02_DeployTokenImplementations.s.sol");
        console.log("2. Run 03_DeployInterestRateStrategy.s.sol");
        console.log("3. Configure reserves and oracles");
        console.log("4. Transfer admin roles to governance contracts");
    }
}
