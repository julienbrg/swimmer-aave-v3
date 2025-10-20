// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

// Aave V3 Core imports
import {PoolAddressesProvider} from "../../src/protocol/configuration/PoolAddressesProvider.sol";
import {AaveOracle} from "../../src/misc/AaveOracle.sol";
import {AaveProtocolDataProvider} from "../../src/misc/AaveProtocolDataProvider.sol";
import {IAaveOracle} from "../../src/interfaces/IAaveOracle.sol";
import {AggregatorInterface} from "../../src/dependencies/chainlink/AggregatorInterface.sol";

// Utils
import {BaseScript} from "./BaseScript.sol";
import {Constants} from "./Constants.sol";

/**
 * @title Check Oracle Configuration
 * @notice Comprehensive oracle health and configuration monitoring script
 * @dev Run with: forge script script/utils/CheckOracleConfig.s.sol:CheckOracleConfig --rpc-url $RPC_URL -vvvv
 */
contract CheckOracleConfig is BaseScript {
    struct OracleStatus {
        address oracle;
        bool isActive;
        bool baseCurrencyValid;
        uint256 baseCurrencyUnit;
        address baseCurrency;
        uint8 assetsConfigured;
        uint8 pricesAvailable;
        uint8 pricesStale;
        uint8 overallHealth;
        string[] issues;
    }

    struct AssetPriceInfo {
        address asset;
        address priceSource;
        uint256 price;
        bool isAvailable;
        bool isStale;
        uint8 decimals;
        int256 latestAnswer;
        uint256 updatedAt;
        string symbol;
    }

    // Constants for price staleness check (in seconds)
    uint256 constant PRICE_STALENESS_THRESHOLD = 3600; // 1 hour
    uint256 constant CRITICAL_STALENESS_THRESHOLD = 86400; // 24 hours

    function run() external {
        console.log("=================================================");
        console.log("    AAVE V3 ORACLE CONFIGURATION CHECKER");
        console.log("=================================================");
        
        console.log("Network: Chain ID", block.chainid);
        console.log("Block Number:", block.number);
        console.log("Block Timestamp:", block.timestamp);
        console.log("");

        // Load oracle address from deployment
        address oracleAddr = _loadOracleAddress();
        
        if (oracleAddr == address(0)) {
            console.log("ERROR: Oracle not found. Run deployment scripts first.");
            return;
        }

        console.log("Oracle Address:", oracleAddr);
        
        // Check oracle configuration
        OracleStatus memory status = _checkOracleHealth(oracleAddr);
        
        // Get detailed asset information
        AssetPriceInfo[] memory assetsInfo = _getAssetPricesInfo(oracleAddr);
        
        // Generate comprehensive report
        _generateOracleReport(status, assetsInfo);
        
        console.log("=================================================");
        console.log("    ORACLE CHECK COMPLETED");
        console.log("=================================================");
    }

    function _loadOracleAddress() internal view returns (address) {
        // First try to load from PoolAddressesProvider
        address poolProvider = _loadContractFromBroadcast("01_DeployCoreContracts.s.sol", "PoolAddressesProvider");
        
        if (poolProvider != address(0)) {
            try PoolAddressesProvider(poolProvider).getPriceOracle() returns (address oracle) {
                if (oracle != address(0)) {
                    return oracle;
                }
            } catch {}
        }
        
        // Fallback: Load directly from oracle deployment
        return _loadContractFromBroadcast("05_DeployOracle.s.sol", "AaveOracle");
    }

    function _checkOracleHealth(address oracleAddr) internal view returns (OracleStatus memory status) {
        status.oracle = oracleAddr;
        string[] memory issues = new string[](10); // Pre-allocate for potential issues
        uint8 issueCount = 0;
        
        // Basic oracle existence check
        if (oracleAddr == address(0)) {
            issues[issueCount++] = "Oracle address is zero";
            status.overallHealth = 0;
            return status;
        }
        
        if (!_isContract(oracleAddr)) {
            issues[issueCount++] = "Oracle address is not a contract";
            status.overallHealth = 0;
            return status;
        }
        
        status.isActive = true;
        
        // Check oracle configuration
        AaveOracle oracle = AaveOracle(oracleAddr);
        
        try oracle.BASE_CURRENCY() returns (address baseCurrency) {
            status.baseCurrency = baseCurrency;
            status.baseCurrencyValid = (baseCurrency == Constants.BASE_CURRENCY);
            if (!status.baseCurrencyValid) {
                issues[issueCount++] = "Base currency mismatch";
            }
        } catch {
            issues[issueCount++] = "Cannot read base currency";
        }
        
        try oracle.BASE_CURRENCY_UNIT() returns (uint256 unit) {
            status.baseCurrencyUnit = unit;
            if (unit != Constants.BASE_CURRENCY_UNIT) {
                issues[issueCount++] = "Base currency unit mismatch";
            }
        } catch {
            issues[issueCount++] = "Cannot read base currency unit";
        }
        
        // Get asset list and check configurations
        address[] memory assets = _getConfiguredAssets();
        status.assetsConfigured = uint8(assets.length);
        
        uint8 availablePrices = 0;
        uint8 stalePrices = 0;
        
        for (uint256 i = 0; i < assets.length; i++) {
            try oracle.getAssetPrice(assets[i]) returns (uint256 price) {
                if (price > 0) {
                    availablePrices++;
                    
                    // Check if price is stale
                    if (_isPriceStale(oracle, assets[i])) {
                        stalePrices++;
                    }
                }
            } catch {
                // Price not available for this asset
            }
        }
        
        status.pricesAvailable = availablePrices;
        status.pricesStale = stalePrices;
        
        if (status.assetsConfigured == 0) {
            issues[issueCount++] = "No assets configured";
        }
        
        if (availablePrices == 0 && status.assetsConfigured > 0) {
            issues[issueCount++] = "No prices available for configured assets";
        }
        
        if (stalePrices > 0) {
            issues[issueCount++] = "Some prices are stale";
        }
        
        // Calculate overall health score (0-100)
        uint8 healthScore = 100;
        if (!status.isActive) healthScore -= 50;
        if (!status.baseCurrencyValid) healthScore -= 20;
        if (status.assetsConfigured == 0) healthScore -= 20;
        if (availablePrices == 0) healthScore -= 30;
        if (stalePrices > 0) healthScore -= (stalePrices * 10); // -10 per stale price
        
        status.overallHealth = healthScore > 100 ? 0 : healthScore;
        
        // Copy issues to status (only non-empty ones)
        status.issues = new string[](issueCount);
        for (uint8 i = 0; i < issueCount; i++) {
            status.issues[i] = issues[i];
        }
    }

    function _getAssetPricesInfo(address oracleAddr) internal view returns (AssetPriceInfo[] memory) {
        if (oracleAddr == address(0) || !_isContract(oracleAddr)) {
            return new AssetPriceInfo[](0);
        }
        
        address[] memory assets = _getConfiguredAssets();
        AssetPriceInfo[] memory assetsInfo = new AssetPriceInfo[](assets.length);
        
        AaveOracle oracle = AaveOracle(oracleAddr);
        
        for (uint256 i = 0; i < assets.length; i++) {
            AssetPriceInfo memory info;
            info.asset = assets[i];
            info.symbol = _getAssetSymbol(assets[i]);
            
            try oracle.getSourceOfAsset(assets[i]) returns (address source) {
                info.priceSource = source;
                
                if (source != address(0)) {
                    try oracle.getAssetPrice(assets[i]) returns (uint256 price) {
                        info.price = price;
                        info.isAvailable = (price > 0);
                    } catch {}
                    
                    // Get details from price source if it's a Chainlink aggregator
                    if (_isContract(source)) {
                        // Try to get decimals (not all aggregators have this function)
                        try this.getAggregatorDecimals(source) returns (uint8 decimals) {
                            info.decimals = decimals;
                        } catch {}
                        
                        try AggregatorInterface(source).latestAnswer() returns (int256 answer) {
                            info.latestAnswer = answer;
                        } catch {}
                        
                        try AggregatorInterface(source).latestTimestamp() returns (uint256 timestamp) {
                            info.updatedAt = timestamp;
                            info.isStale = (block.timestamp - timestamp > PRICE_STALENESS_THRESHOLD);
                        } catch {}
                    }
                }
            } catch {}
            
            assetsInfo[i] = info;
        }
        
        return assetsInfo;
    }

    function _getConfiguredAssets() internal view returns (address[] memory) {
        // Get assets from deployment or protocol data provider
        address dataProvider = _loadContractFromBroadcast("05_DeployOracle.s.sol", "AaveProtocolDataProvider");
        
        if (dataProvider != address(0) && _isContract(dataProvider)) {
            try AaveProtocolDataProvider(dataProvider).getAllReservesTokens() returns (
                AaveProtocolDataProvider.TokenData[] memory reserves
            ) {
                address[] memory assets = new address[](reserves.length);
                for (uint256 i = 0; i < reserves.length; i++) {
                    assets[i] = reserves[i].tokenAddress;
                }
                return assets;
            } catch {}
        }
        
        // Fallback: Known assets from listing scripts
        address[] memory knownAssets = new address[](2);
        // These would be loaded from actual deployment addresses
        // For now, return empty array since we don't have configured assets
        return new address[](0);
    }

    function _isPriceStale(AaveOracle oracle, address asset) internal view returns (bool) {
        try oracle.getSourceOfAsset(asset) returns (address source) {
            if (source != address(0) && _isContract(source)) {
                try AggregatorInterface(source).latestTimestamp() returns (uint256 timestamp) {
                    return (block.timestamp - timestamp > PRICE_STALENESS_THRESHOLD);
                } catch {}
            }
        } catch {}
        return false;
    }

    function _getAssetSymbol(address asset) internal view returns (string memory) {
        if (asset == address(0)) return "ETH";
        
        // Try to get symbol from ERC20 interface
        try this.getERC20Symbol(asset) returns (string memory symbol) {
            return symbol;
        } catch {
            return "UNKNOWN";
        }
    }

    // External function to call ERC20 symbol (needed for try/catch)
    function getERC20Symbol(address token) external view returns (string memory) {
        (bool success, bytes memory data) = token.staticcall(abi.encodeWithSignature("symbol()"));
        if (success && data.length > 0) {
            return abi.decode(data, (string));
        }
        return "UNKNOWN";
    }

    // External function to call aggregator decimals (needed for try/catch)
    function getAggregatorDecimals(address aggregator) external view returns (uint8) {
        (bool success, bytes memory data) = aggregator.staticcall(abi.encodeWithSignature("decimals()"));
        if (success && data.length > 0) {
            return abi.decode(data, (uint8));
        }
        return 8; // Default to 8 decimals (Chainlink standard)
    }

    function _generateOracleReport(OracleStatus memory status, AssetPriceInfo[] memory assetsInfo) internal view {
        console.log("\n=================================================");
        console.log("           ORACLE CONFIGURATION REPORT");
        console.log("=================================================");
        
        // Overall Status
        console.log("\nORACLE STATUS:");
        console.log("Address:", status.oracle);
        console.log("Active:", status.isActive ? "YES" : "NO");
        console.log("Overall Health Score:", status.overallHealth, "/100");
        
        if (status.overallHealth >= 90) {
            console.log("Health Status: EXCELLENT");
        } else if (status.overallHealth >= 70) {
            console.log("Health Status: GOOD");
        } else if (status.overallHealth >= 50) {
            console.log("Health Status: FAIR - Issues need attention");
        } else {
            console.log("Health Status: POOR - Critical issues found");
        }
        
        // Configuration Details
        console.log("\nCONFIGURATION:");
        console.log("Base Currency:", status.baseCurrency);
        console.log("Base Currency Unit:", status.baseCurrencyUnit);
        console.log("Base Currency Valid:", status.baseCurrencyValid ? "YES" : "NO");
        
        // Asset Summary
        console.log("\nASSET SUMMARY:");
        console.log("Assets Configured:", status.assetsConfigured);
        console.log("Prices Available:", status.pricesAvailable);
        console.log("Stale Prices:", status.pricesStale);
        
        // Detailed Asset Information
        if (assetsInfo.length > 0) {
            console.log("\nASSET DETAILS:");
            console.log("--------------------------------------------------------");
            for (uint256 i = 0; i < assetsInfo.length; i++) {
                AssetPriceInfo memory info = assetsInfo[i];
                console.log("Asset:", info.symbol);
                console.log("  Address:", info.asset);
                console.log("  Price Source:", info.priceSource);
                console.log("  Price:", info.price);
                console.log("  Available:", info.isAvailable ? "YES" : "NO");
                console.log("  Stale:", info.isStale ? "YES" : "NO");
                if (info.decimals > 0) {
                    console.log("  Decimals:", info.decimals);
                }
                if (info.updatedAt > 0) {
                    console.log("  Last Updated:", info.updatedAt);
                    console.log("  Age (seconds):", block.timestamp - info.updatedAt);
                }
                console.log("");
            }
        } else {
            console.log("\nNo configured assets found.");
            console.log("This usually means:");
            console.log("1. No assets have been listed yet, OR");
            console.log("2. Price sources haven't been set for listed assets");
        }
        
        // Issues and Recommendations
        if (status.issues.length > 0) {
            console.log("\nISSUES FOUND:");
            for (uint256 i = 0; i < status.issues.length; i++) {
                console.log("- ", status.issues[i]);
            }
        }
        
        console.log("\nRECOMMENDATIONS:");
        if (status.assetsConfigured == 0) {
            console.log("- Configure price sources for listed assets using setAssetSources()");
        }
        if (status.pricesStale > 0) {
            console.log("- Check Chainlink price feeds for stale data");
            console.log("- Verify price feed contracts are actively updated");
        }
        if (status.pricesAvailable == 0 && status.assetsConfigured > 0) {
            console.log("- Verify price feed contracts are properly deployed");
            console.log("- Check that asset addresses match the configured sources");
        }
        if (!status.baseCurrencyValid) {
            console.log("- Verify base currency configuration matches Constants.sol");
        }
        
        // Next Steps
        console.log("\nNEXT STEPS:");
        console.log("1. Review asset listing scripts (ListUSDC.s.sol, ListWBTC.s.sol)");
        console.log("2. Deploy price aggregators for each asset");
        console.log("3. Call setAssetSources() to connect assets to price feeds");
        console.log("4. Run this script again to verify configuration");
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function _loadContractFromBroadcast(string memory scriptName, string memory contractName)
        internal
        view
        returns (address)
    {
        string memory broadcastFile =
            string(abi.encodePacked("./broadcast/", scriptName, "/", vm.toString(block.chainid), "/run-latest.json"));

        try vm.readFile(broadcastFile) returns (string memory json) {
            bytes memory jsonBytes = bytes(json);
            if (jsonBytes.length <= 10) {
                return address(0);
            }

            try vm.parseJsonAddress(json, ".transactions[0].contractAddress") returns (address contractAddr) {
                return contractAddr;
            } catch {
                return address(0);
            }
        } catch {
            return address(0);
        }
    }
}