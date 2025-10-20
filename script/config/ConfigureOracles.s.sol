// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

// Aave V3 Core imports
import {PoolAddressesProvider} from "../../src/protocol/configuration/PoolAddressesProvider.sol";
import {AaveOracle} from "../../src/misc/AaveOracle.sol";
import {MockAggregator} from "../../src/mocks/oracle/CLAggregators/MockAggregator.sol";

// Utils
import {BaseScript} from "../utils/BaseScript.sol";

/**
 * @title Configure Oracle with Credible Market Rates
 * @notice Deploys mock price aggregators and configures the Aave Oracle
 * @dev Run with: forge script script/config/ConfigureOracles.s.sol:ConfigureOracles --rpc-url $RPC_URL --broadcast -vvv
 */
contract ConfigureOracles is BaseScript {
    
    // Asset addresses from goldsky.md
    address constant USDC = 0x14Ee4343dc75d77446041Be83ae6f3385ccb695A;
    address constant USDT = 0x2D9a93AF809Ea53A90b5aC29e15c66F6e2FDcFb5;
    address constant WBTC = 0x6353e6A9920C964ae9E485b0B7f1F83dE7403945;
    address constant DAI = 0x5D51C1e40eDCb36b2Bb207242587d76CF799Eb05;
    address constant LINK = 0x26D7B0b2852802Fc58d97a0865771318b306BD1C;
    address constant UNI = 0x67ad97dfF0b6234F7E3c7e8E48ef035A4119428f;
    
    // Market rates (8 decimals, Chainlink standard)
    // Prices as of January 12, 2025
    int256 constant USDC_PRICE = 100000000;        // $1.00
    int256 constant USDT_PRICE = 100000000;        // $1.00  
    int256 constant WBTC_PRICE = 11172000000000;   // $111,720.00
    int256 constant DAI_PRICE = 100000000;         // $1.00
    int256 constant LINK_PRICE = 1700000000;       // $17.00
    int256 constant UNI_PRICE = 607000000;         // $6.07

    struct OracleDeployment {
        address asset;
        string symbol;
        int256 price;
        address aggregator;
    }

    function run() external {
        console.log("=================================================");
        console.log("    CONFIGURING AAVE ORACLE WITH MARKET RATES");
        console.log("=================================================");
        console.log("Network: Chain ID", block.chainid);
        
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        
        // Load oracle address
        address oracleAddr = _getOracleAddress();
        require(oracleAddr != address(0), "Oracle not found");
        
        console.log("Oracle Address:", oracleAddr);
        AaveOracle oracle = AaveOracle(oracleAddr);
        
        // Deploy mock aggregators for all assets
        OracleDeployment[] memory deployments = new OracleDeployment[](6);
        
        // Active reserves (already listed)
        deployments[0] = _deployAggregator("USDC", USDC, USDC_PRICE);
        deployments[1] = _deployAggregator("USDT", USDT, USDT_PRICE);  
        deployments[2] = _deployAggregator("WBTC", WBTC, WBTC_PRICE);
        
        // Available tokens (for future listing)
        deployments[3] = _deployAggregator("DAI", DAI, DAI_PRICE);
        deployments[4] = _deployAggregator("LINK", LINK, LINK_PRICE);
        deployments[5] = _deployAggregator("UNI", UNI, UNI_PRICE);
        
        // Configure oracle with price sources
        _configureOracle(oracle, deployments);
        
        vm.stopBroadcast();
        
        // Verify configuration
        _verifyOracleConfiguration(oracle, deployments);
        
        console.log("\n=================================================");
        console.log("    ORACLE CONFIGURATION COMPLETED");
        console.log("=================================================");
    }

    function _deployAggregator(string memory symbol, address asset, int256 price) 
        internal 
        returns (OracleDeployment memory) 
    {
        console.log("Deploying", symbol, "aggregator with price:", uint256(price));
        
        MockAggregator aggregator = new MockAggregator(price);
        console.log("  Deployed at:", address(aggregator));
        
        return OracleDeployment({
            asset: asset,
            symbol: symbol,
            price: price,
            aggregator: address(aggregator)
        });
    }

    function _configureOracle(AaveOracle oracle, OracleDeployment[] memory deployments) internal {
        console.log("\nConfiguring oracle asset sources...");
        
        address[] memory assets = new address[](deployments.length);
        address[] memory sources = new address[](deployments.length);
        
        for (uint256 i = 0; i < deployments.length; i++) {
            assets[i] = deployments[i].asset;
            sources[i] = deployments[i].aggregator;
            console.log("  Setting", deployments[i].symbol, "->", sources[i]);
        }
        
        // Set asset sources in one transaction
        oracle.setAssetSources(assets, sources);
        console.log("Oracle asset sources configured successfully");
    }

    function _verifyOracleConfiguration(AaveOracle oracle, OracleDeployment[] memory deployments) internal view {
        console.log("\nVerifying oracle configuration...");
        
        bool allConfigured = true;
        
        for (uint256 i = 0; i < deployments.length; i++) {
            address source = oracle.getSourceOfAsset(deployments[i].asset);
            uint256 price = oracle.getAssetPrice(deployments[i].asset);
            
            if (source == deployments[i].aggregator && price == uint256(deployments[i].price)) {
                console.log("  [PASS]", deployments[i].symbol);
                console.log("    Price:", price);
                console.log("    Source:", source);
            } else {
                console.log("  [FAIL]", deployments[i].symbol, "- Configuration failed");
                console.log("    Expected source:", deployments[i].aggregator);
                console.log("    Actual source:", source);
                console.log("    Expected price:", uint256(deployments[i].price));
                console.log("    Actual price:", price);
                allConfigured = false;
            }
        }
        
        if (allConfigured) {
            console.log("\n[SUCCESS] All assets successfully configured!");
            console.log("\nCurrent Market Prices (USD):");
            console.log("  USDC: $1.00");
            console.log("  USDT: $1.00");
            console.log("  WBTC: $111,720.00");
            console.log("  DAI:  $1.00");
            console.log("  LINK: $17.00");
            console.log("  UNI:  $6.07");
        } else {
            console.log("\n[WARNING] Some configurations failed. Please review.");
        }
        
        console.log("\nNext Steps:");
        console.log("1. Run oracle health check:");
        console.log("   forge script script/utils/CheckOracleConfig.s.sol:CheckOracleConfig --rpc-url $RPC_URL -vvvv");
        console.log("2. Assets USDC, USDT, WBTC are already active reserves");
        console.log("3. To list additional assets (DAI, LINK, UNI), run their respective listing scripts");
    }

    function _getOracleAddress() internal view returns (address) {
        // Try to load from PoolAddressesProvider first
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