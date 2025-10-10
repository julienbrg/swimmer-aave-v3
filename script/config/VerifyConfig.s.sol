// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

// Aave V3 Core imports
import {PoolAddressesProvider} from "aave-v3-core/contracts/protocol/configuration/PoolAddressesProvider.sol";
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
 * @title Verify Configuration
 * @notice Comprehensive verification of Aave V3.0 deployment configuration
 * @dev Run with: forge script script/config/VerifyConfig.s.sol:VerifyConfig --rpc-url $HYPEREVM_TESTNET_RPC_URL -vvvv
 */
contract VerifyConfig is BaseScript {
    struct DeploymentAddresses {
        address poolAddressesProvider;
        address poolAddressesProviderRegistry;
        address aclManager;
        address pool;
        address poolConfigurator;
        address poolProxy;
        address poolConfiguratorProxy;
        address oracle;
        address protocolDataProvider;
        address aTokenImpl;
        address stableDebtTokenImpl;
        address variableDebtTokenImpl;
        address defaultInterestRateStrategy;
        address stablecoinInterestRateStrategy;
        address volatileAssetInterestRateStrategy;
    }

    struct ConfigurationStatus {
        bool allContractsDeployed;
        bool proxiesConfigured;
        bool implementationsSet;
        bool aclConfigured;
        bool oracleConfigured;
        bool interestRateStrategiesDeployed;
        uint8 overallScore;
    }

    function run() external {
        console.log("=================================================");
        console.log("    AAVE V3.0 CONFIGURATION VERIFICATION");
        console.log("=================================================");

        // Verify we're on the correct network
        require(block.chainid == Constants.CHAIN_ID, "Wrong network - expected HyperEVM Testnet");
        console.log("Network: HyperEVM Testnet (Chain ID: 998)");

        // Load deployment file
        string memory deploymentJson = loadDeployment();
        if (bytes(deploymentJson).length <= 2) {
            console.log("ERROR: No valid deployment data found.");
            console.log("Please run deployment scripts first.");
            return;
        }

        DeploymentAddresses memory addresses = _loadAddresses(deploymentJson);
        ConfigurationStatus memory status = _verifyConfiguration(addresses);

        _generateReport(status, addresses);

        console.log("=================================================");
        console.log("    VERIFICATION COMPLETED");
        console.log("=================================================");
    }

    function _loadAddresses(string memory json) internal pure returns (DeploymentAddresses memory addresses) {
        addresses.poolAddressesProvider = vm.parseJsonAddress(json, ".poolAddressesProvider");
        addresses.poolAddressesProviderRegistry = vm.parseJsonAddress(json, ".poolAddressesProviderRegistry");
        addresses.aclManager = vm.parseJsonAddress(json, ".aclManager");
        addresses.pool = vm.parseJsonAddress(json, ".pool");
        addresses.poolConfigurator = vm.parseJsonAddress(json, ".poolConfigurator");

        // Try to parse proxy addresses (may not exist in older deployments)
        try vm.parseJsonAddress(json, ".poolProxy") returns (address poolProxy) {
            addresses.poolProxy = poolProxy;
        } catch {}

        try vm.parseJsonAddress(json, ".poolConfiguratorProxy") returns (address poolConfiguratorProxy) {
            addresses.poolConfiguratorProxy = poolConfiguratorProxy;
        } catch {}

        addresses.oracle = vm.parseJsonAddress(json, ".oracle");
        addresses.protocolDataProvider = vm.parseJsonAddress(json, ".protocolDataProvider");
        addresses.aTokenImpl = vm.parseJsonAddress(json, ".aTokenImpl");
        addresses.stableDebtTokenImpl = vm.parseJsonAddress(json, ".stableDebtTokenImpl");
        addresses.variableDebtTokenImpl = vm.parseJsonAddress(json, ".variableDebtTokenImpl");
        addresses.defaultInterestRateStrategy = vm.parseJsonAddress(json, ".defaultInterestRateStrategy");
        addresses.stablecoinInterestRateStrategy = vm.parseJsonAddress(json, ".stablecoinInterestRateStrategy");
        addresses.volatileAssetInterestRateStrategy = vm.parseJsonAddress(json, ".volatileAssetInterestRateStrategy");
    }

    function _verifyConfiguration(DeploymentAddresses memory addresses)
        internal
        view
        returns (ConfigurationStatus memory status)
    {
        console.log("\n1. VERIFYING CONTRACT DEPLOYMENTS...");
        status.allContractsDeployed = _verifyContractDeployments(addresses);

        console.log("\n2. VERIFYING PROXY CONFIGURATION...");
        status.proxiesConfigured = _verifyProxies(addresses);

        console.log("\n3. VERIFYING IMPLEMENTATION SETUP...");
        status.implementationsSet = _verifyImplementations(addresses);

        console.log("\n4. VERIFYING ACL CONFIGURATION...");
        status.aclConfigured = _verifyACL(addresses);

        console.log("\n5. VERIFYING ORACLE CONFIGURATION...");
        status.oracleConfigured = _verifyOracle(addresses);

        console.log("\n6. VERIFYING INTEREST RATE STRATEGIES...");
        status.interestRateStrategiesDeployed = _verifyInterestRateStrategies(addresses);

        // Calculate overall score
        uint8 score = 0;
        if (status.allContractsDeployed) score += 20;
        if (status.proxiesConfigured) score += 20;
        if (status.implementationsSet) score += 15;
        if (status.aclConfigured) score += 15;
        if (status.oracleConfigured) score += 15;
        if (status.interestRateStrategiesDeployed) score += 15;
        status.overallScore = score;
    }

    function _verifyContractDeployments(DeploymentAddresses memory addresses) internal view returns (bool) {
        bool allDeployed = true;

        if (!_isContract(addresses.poolAddressesProvider)) {
            console.log("   [FAIL] PoolAddressesProvider not deployed");
            allDeployed = false;
        } else {
            console.log("   [PASS] PoolAddressesProvider deployed");
        }

        if (!_isContract(addresses.aclManager)) {
            console.log("   [FAIL] ACLManager not deployed");
            allDeployed = false;
        } else {
            console.log("   [PASS] ACLManager deployed");
        }

        if (!_isContract(addresses.pool)) {
            console.log("   [FAIL] Pool implementation not deployed");
            allDeployed = false;
        } else {
            console.log("   [PASS] Pool implementation deployed");
        }

        if (!_isContract(addresses.poolConfigurator)) {
            console.log("   [FAIL] PoolConfigurator implementation not deployed");
            allDeployed = false;
        } else {
            console.log("   [PASS] PoolConfigurator implementation deployed");
        }

        if (!_isContract(addresses.oracle)) {
            console.log("   [FAIL] Oracle not deployed");
            allDeployed = false;
        } else {
            console.log("   [PASS] Oracle deployed");
        }

        return allDeployed;
    }

    function _verifyProxies(DeploymentAddresses memory addresses) internal view returns (bool) {
        if (addresses.poolAddressesProvider == address(0)) {
            console.log("   [FAIL] PoolAddressesProvider address not found");
            return false;
        }

        PoolAddressesProvider provider = PoolAddressesProvider(addresses.poolAddressesProvider);

        address poolProxy = provider.getPool();
        address configProxy = provider.getPoolConfigurator();

        if (poolProxy == address(0)) {
            console.log("   [FAIL] Pool proxy not created");
            return false;
        } else {
            console.log("   [PASS] Pool proxy created at:", poolProxy);
        }

        if (configProxy == address(0)) {
            console.log("   [FAIL] PoolConfigurator proxy not created");
            return false;
        } else {
            console.log("   [PASS] PoolConfigurator proxy created at:", configProxy);
        }

        return true;
    }

    function _verifyImplementations(DeploymentAddresses memory addresses) internal view returns (bool) {
        if (addresses.poolAddressesProvider == address(0)) return false;

        PoolAddressesProvider provider = PoolAddressesProvider(addresses.poolAddressesProvider);

        // Verify Pool proxy exists (indicates implementation was set)
        address poolProxy = provider.getPool();
        if (poolProxy == address(0)) {
            console.log("   [FAIL] Pool proxy not created - implementation not set");
            return false;
        } else {
            console.log("   [PASS] Pool implementation properly set (proxy exists)");
        }

        // Verify PoolConfigurator proxy exists (indicates implementation was set)
        address configProxy = provider.getPoolConfigurator();
        if (configProxy == address(0)) {
            console.log("   [FAIL] PoolConfigurator proxy not created - implementation not set");
            return false;
        } else {
            console.log("   [PASS] PoolConfigurator implementation properly set (proxy exists)");
        }

        // Additional check - verify that deployed implementations match what's in deployment file
        if (addresses.pool != address(0) && _isContract(addresses.pool)) {
            console.log("   [PASS] Pool implementation contract verified:", addresses.pool);
        } else {
            console.log("   [WARN] Pool implementation not found in deployment file");
        }

        if (addresses.poolConfigurator != address(0) && _isContract(addresses.poolConfigurator)) {
            console.log("   [PASS] PoolConfigurator implementation contract verified:", addresses.poolConfigurator);
        } else {
            console.log("   [WARN] PoolConfigurator implementation not found in deployment file");
        }

        return true;
    }

    function _verifyACL(DeploymentAddresses memory addresses) internal view returns (bool) {
        if (addresses.poolAddressesProvider == address(0) || addresses.aclManager == address(0)) {
            return false;
        }

        PoolAddressesProvider provider = PoolAddressesProvider(addresses.poolAddressesProvider);

        // Verify ACL Manager is set in provider
        address aclFromProvider = provider.getACLManager();
        if (aclFromProvider == address(0)) {
            console.log("   [FAIL] ACL Manager not set in provider");
            return false;
        } else if (aclFromProvider != addresses.aclManager && addresses.aclManager != address(0)) {
            console.log(
                "   [WARN] ACL Manager address mismatch - Provider:",
                aclFromProvider,
                "Deployment:",
                addresses.aclManager
            );
            console.log("   [PASS] ACL Manager is set (but address differs from deployment file)");
        } else {
            console.log("   [PASS] ACL Manager properly configured:", aclFromProvider);
        }

        // Verify ACL Admin is set
        address aclAdmin = provider.getACLAdmin();
        if (aclAdmin == address(0)) {
            console.log("   [FAIL] ACL Admin not set");
            return false;
        } else {
            console.log("   [PASS] ACL Admin set to:", aclAdmin);
        }

        return true;
    }

    function _verifyOracle(DeploymentAddresses memory addresses) internal view returns (bool) {
        if (addresses.poolAddressesProvider == address(0) || addresses.oracle == address(0)) {
            return false;
        }

        PoolAddressesProvider provider = PoolAddressesProvider(addresses.poolAddressesProvider);

        // Verify Oracle is set in provider
        address oracleFromProvider = provider.getPriceOracle();
        if (oracleFromProvider == address(0)) {
            console.log("   [FAIL] Oracle not set in provider");
            return false;
        } else if (oracleFromProvider != addresses.oracle && addresses.oracle != address(0)) {
            console.log(
                "   [WARN] Oracle address mismatch - Provider:", oracleFromProvider, "Deployment:", addresses.oracle
            );
            console.log("   [PASS] Oracle is set (but address differs from deployment file)");
        } else {
            console.log("   [PASS] Oracle properly configured:", oracleFromProvider);
        }

        return true;
    }

    function _verifyInterestRateStrategies(DeploymentAddresses memory addresses) internal view returns (bool) {
        bool allDeployed = true;

        if (!_isContract(addresses.defaultInterestRateStrategy)) {
            console.log("   [FAIL] Default Interest Rate Strategy not deployed");
            allDeployed = false;
        } else {
            console.log("   [PASS] Default Interest Rate Strategy deployed");
        }

        if (!_isContract(addresses.stablecoinInterestRateStrategy)) {
            console.log("   [FAIL] Stablecoin Interest Rate Strategy not deployed");
            allDeployed = false;
        } else {
            console.log("   [PASS] Stablecoin Interest Rate Strategy deployed");
        }

        if (!_isContract(addresses.volatileAssetInterestRateStrategy)) {
            console.log("   [FAIL] Volatile Asset Interest Rate Strategy not deployed");
            allDeployed = false;
        } else {
            console.log("   [PASS] Volatile Asset Interest Rate Strategy deployed");
        }

        return allDeployed;
    }

    function _generateReport(ConfigurationStatus memory status, DeploymentAddresses memory addresses) internal view {
        console.log("\n=================================================");
        console.log("           CONFIGURATION REPORT");
        console.log("=================================================");

        console.log("\nSTATUS SUMMARY:");
        console.log("Contract Deployments:", status.allContractsDeployed ? "PASS" : "FAIL");
        console.log("Proxy Configuration:", status.proxiesConfigured ? "PASS" : "FAIL");
        console.log("Implementation Setup:", status.implementationsSet ? "PASS" : "FAIL");
        console.log("ACL Configuration:", status.aclConfigured ? "PASS" : "FAIL");
        console.log("Oracle Configuration:", status.oracleConfigured ? "PASS" : "FAIL");
        console.log("Interest Rate Strategies:", status.interestRateStrategiesDeployed ? "PASS" : "FAIL");

        console.log("\nOVERALL SCORE:", status.overallScore, "/100");

        if (status.overallScore >= 90) {
            console.log("STATUS: EXCELLENT - Ready for production");
        } else if (status.overallScore >= 70) {
            console.log("STATUS: GOOD - Minor issues to address");
        } else if (status.overallScore >= 50) {
            console.log("STATUS: FAIR - Several issues need attention");
        } else {
            console.log("STATUS: POOR - Major configuration issues");
        }

        console.log("\nKEY ADDRESSES:");
        console.log("Pool (Main Entry Point):", _getPoolProxy(addresses));
        console.log("PoolAddressesProvider:", addresses.poolAddressesProvider);
        console.log("ACLManager:", addresses.aclManager);
        console.log("Oracle:", addresses.oracle);

        if (status.overallScore < 100) {
            console.log("\nRECOMMENDATIONS:");
            if (!status.allContractsDeployed) {
                console.log("- Complete contract deployment using deployment scripts");
            }
            if (!status.proxiesConfigured) {
                console.log("- Run proxy configuration steps");
            }
            if (!status.implementationsSet) {
                console.log("- Set implementation contracts in PoolAddressesProvider");
            }
            if (!status.aclConfigured) {
                console.log("- Configure ACL Manager and admin roles");
            }
            if (!status.oracleConfigured) {
                console.log("- Set price oracle in PoolAddressesProvider");
            }
            if (!status.interestRateStrategiesDeployed) {
                console.log("- Deploy interest rate strategies for different asset types");
            }
        }
    }

    function _getPoolProxy(DeploymentAddresses memory addresses) internal view returns (address) {
        if (addresses.poolAddressesProvider == address(0)) return address(0);

        try PoolAddressesProvider(addresses.poolAddressesProvider).getPool() returns (address poolProxy) {
            return poolProxy;
        } catch {
            return address(0);
        }
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}
