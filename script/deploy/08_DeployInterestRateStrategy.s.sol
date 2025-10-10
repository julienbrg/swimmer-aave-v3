// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

// Aave V3 Core imports
import {DefaultReserveInterestRateStrategy} from
    "aave-v3-core/contracts/protocol/pool/DefaultReserveInterestRateStrategy.sol";
import {IPoolAddressesProvider} from "aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol";

// Utils
import {BaseScript} from "../utils/BaseScript.sol";
import {Constants} from "../utils/Constants.sol";

/**
 * @title Deploy Interest Rate Strategy
 * @notice Deploys interest rate strategies for different asset types
 * @dev Run with: forge script script/deploy/03_DeployInterestRateStrategy.s.sol:DeployInterestRateStrategy --rpc-url $HYPEREVM_TESTNET_RPC_URL --broadcast -vvvv
 */
contract DeployInterestRateStrategy is BaseScript {
    struct InterestRateParams {
        uint256 optimalUsageRatio;
        uint256 baseVariableBorrowRate;
        uint256 variableRateSlope1;
        uint256 variableRateSlope2;
        uint256 stableRateSlope1;
        uint256 stableRateSlope2;
        uint256 baseStableRateOffset;
        uint256 stableRateExcessOffset;
        uint256 optimalStableToTotalDebtRatio;
    }

    struct InterestRateStrategies {
        address defaultStrategy;
        address stablecoinStrategy;
        address volatileAssetStrategy;
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

        logSeparator("DEPLOYING INTEREST RATE STRATEGIES");
        console.log("Using PoolAddressesProvider:", poolAddressesProvider);

        InterestRateStrategies memory strategies;

        startBroadcastWithInfo();
        strategies = _deployInterestRateStrategies(poolAddressesProvider);
        stopBroadcastWithInfo();

        _verifyDeployment(strategies);
        _saveDeployment(strategies);

        logSeparator("INTEREST RATE STRATEGIES DEPLOYED SUCCESSFULLY");
        _logDeploymentSummary(strategies);
    }

    function _deployInterestRateStrategies(address poolAddressesProvider)
        internal
        returns (InterestRateStrategies memory strategies)
    {
        // 1. Deploy Default Interest Rate Strategy (for ETH and major assets)
        console.log("\n1. Deploying Default Interest Rate Strategy...");
        InterestRateParams memory defaultParams = InterestRateParams({
            optimalUsageRatio: Constants.OPTIMAL_USAGE_RATIO,
            baseVariableBorrowRate: Constants.BASE_VARIABLE_BORROW_RATE,
            variableRateSlope1: Constants.VARIABLE_RATE_SLOPE1,
            variableRateSlope2: Constants.VARIABLE_RATE_SLOPE2,
            stableRateSlope1: Constants.STABLE_RATE_SLOPE1,
            stableRateSlope2: Constants.STABLE_RATE_SLOPE2,
            baseStableRateOffset: Constants.BASE_STABLE_BORROW_RATE,
            stableRateExcessOffset: Constants.STABLE_RATE_EXCESS_OFFSET,
            optimalStableToTotalDebtRatio: Constants.OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO
        });

        strategies.defaultStrategy = address(
            new DefaultReserveInterestRateStrategy(
                IPoolAddressesProvider(poolAddressesProvider),
                defaultParams.optimalUsageRatio,
                defaultParams.baseVariableBorrowRate,
                defaultParams.variableRateSlope1,
                defaultParams.variableRateSlope2,
                defaultParams.stableRateSlope1,
                defaultParams.stableRateSlope2,
                defaultParams.baseStableRateOffset,
                defaultParams.stableRateExcessOffset,
                defaultParams.optimalStableToTotalDebtRatio
            )
        );
        console.log("   Default Strategy deployed:", strategies.defaultStrategy);
        _logRateParams("Default", defaultParams);

        // 2. Deploy Stablecoin Interest Rate Strategy (lower rates, higher optimal usage)
        console.log("\n2. Deploying Stablecoin Interest Rate Strategy...");
        InterestRateParams memory stablecoinParams = InterestRateParams({
            optimalUsageRatio: 900000000000000000000000000, // 90%
            baseVariableBorrowRate: 0, // 0%
            variableRateSlope1: 25000000000000000000000000, // 2.5%
            variableRateSlope2: 600000000000000000000000000, // 60%
            stableRateSlope1: 10000000000000000000000000, // 1%
            stableRateSlope2: 600000000000000000000000000, // 60%
            baseStableRateOffset: 10000000000000000000000000, // 1%
            stableRateExcessOffset: 100000000000000000000000000, // 10%
            optimalStableToTotalDebtRatio: 200000000000000000000000000 // 20%
        });

        strategies.stablecoinStrategy = address(
            new DefaultReserveInterestRateStrategy(
                IPoolAddressesProvider(poolAddressesProvider),
                stablecoinParams.optimalUsageRatio,
                stablecoinParams.baseVariableBorrowRate,
                stablecoinParams.variableRateSlope1,
                stablecoinParams.variableRateSlope2,
                stablecoinParams.stableRateSlope1,
                stablecoinParams.stableRateSlope2,
                stablecoinParams.baseStableRateOffset,
                stablecoinParams.stableRateExcessOffset,
                stablecoinParams.optimalStableToTotalDebtRatio
            )
        );
        console.log("   Stablecoin Strategy deployed:", strategies.stablecoinStrategy);
        _logRateParams("Stablecoin", stablecoinParams);

        // 3. Deploy Volatile Asset Interest Rate Strategy (higher rates, lower optimal usage)
        console.log("\n3. Deploying Volatile Asset Interest Rate Strategy...");
        InterestRateParams memory volatileParams = InterestRateParams({
            optimalUsageRatio: 700000000000000000000000000, // 70%
            baseVariableBorrowRate: 10000000000000000000000000, // 1%
            variableRateSlope1: 60000000000000000000000000, // 6%
            variableRateSlope2: 800000000000000000000000000, // 80%
            stableRateSlope1: 30000000000000000000000000, // 3%
            stableRateSlope2: 800000000000000000000000000, // 80%
            baseStableRateOffset: 30000000000000000000000000, // 3%
            stableRateExcessOffset: 200000000000000000000000000, // 20%
            optimalStableToTotalDebtRatio: 200000000000000000000000000 // 20%
        });

        strategies.volatileAssetStrategy = address(
            new DefaultReserveInterestRateStrategy(
                IPoolAddressesProvider(poolAddressesProvider),
                volatileParams.optimalUsageRatio,
                volatileParams.baseVariableBorrowRate,
                volatileParams.variableRateSlope1,
                volatileParams.variableRateSlope2,
                volatileParams.stableRateSlope1,
                volatileParams.stableRateSlope2,
                volatileParams.baseStableRateOffset,
                volatileParams.stableRateExcessOffset,
                volatileParams.optimalStableToTotalDebtRatio
            )
        );
        console.log("   Volatile Asset Strategy deployed:", strategies.volatileAssetStrategy);
        _logRateParams("Volatile", volatileParams);

        console.log("\nAll interest rate strategies deployed!");

        return strategies;
    }

    function _logRateParams(string memory strategyName, InterestRateParams memory params) internal view {
        console.log(
            string(
                abi.encodePacked(
                    "   ", strategyName, " - Optimal Usage Ratio: ", vm.toString(params.optimalUsageRatio / 1e25), "%"
                )
            )
        );
        console.log(
            string(
                abi.encodePacked(
                    "   ",
                    strategyName,
                    " - Base Variable Rate: ",
                    vm.toString(params.baseVariableBorrowRate / 1e25),
                    "%"
                )
            )
        );
        console.log(
            string(
                abi.encodePacked(
                    "   ", strategyName, " - Variable Slope 1: ", vm.toString(params.variableRateSlope1 / 1e25), "%"
                )
            )
        );
        console.log(
            string(
                abi.encodePacked(
                    "   ", strategyName, " - Variable Slope 2: ", vm.toString(params.variableRateSlope2 / 1e25), "%"
                )
            )
        );
    }

    function _verifyDeployment(InterestRateStrategies memory strategies) internal view {
        logSeparator("VERIFYING INTEREST RATE STRATEGIES");

        verifyAddress(strategies.defaultStrategy, "Default Strategy");
        verifyAddress(strategies.stablecoinStrategy, "Stablecoin Strategy");
        verifyAddress(strategies.volatileAssetStrategy, "Volatile Asset Strategy");

        // Verify strategy configurations
        DefaultReserveInterestRateStrategy defaultStrat = DefaultReserveInterestRateStrategy(strategies.defaultStrategy);
        require(defaultStrat.OPTIMAL_USAGE_RATIO() > 0, "Default strategy optimal usage ratio not set");

        DefaultReserveInterestRateStrategy stablecoinStrat =
            DefaultReserveInterestRateStrategy(strategies.stablecoinStrategy);
        require(stablecoinStrat.OPTIMAL_USAGE_RATIO() > 0, "Stablecoin strategy optimal usage ratio not set");

        DefaultReserveInterestRateStrategy volatileStrat =
            DefaultReserveInterestRateStrategy(strategies.volatileAssetStrategy);
        require(volatileStrat.OPTIMAL_USAGE_RATIO() > 0, "Volatile strategy optimal usage ratio not set");

        console.log("All interest rate strategy verifications passed!");
    }

    function _saveDeployment(InterestRateStrategies memory strategies) internal {
        // Create JSON with interest rate strategies
        string memory json = "deployment";
        vm.serializeAddress(json, "defaultInterestRateStrategy", strategies.defaultStrategy);
        vm.serializeAddress(json, "stablecoinInterestRateStrategy", strategies.stablecoinStrategy);
        string memory strategiesJson =
            vm.serializeAddress(json, "volatileAssetInterestRateStrategy", strategies.volatileAssetStrategy);

        saveDeployment(strategiesJson);
        console.log("Interest rate strategies added to deployment file");
    }

    function _logDeploymentSummary(InterestRateStrategies memory strategies) internal view {
        logSeparator("INTEREST RATE STRATEGIES SUMMARY");
        console.log("Default Strategy:         ", strategies.defaultStrategy);
        console.log("Stablecoin Strategy:      ", strategies.stablecoinStrategy);
        console.log("Volatile Asset Strategy:  ", strategies.volatileAssetStrategy);

        console.log("\nStrategy Recommendations:");
        console.log("- Use Default Strategy for: ETH, WBTC, major cryptocurrencies");
        console.log("- Use Stablecoin Strategy for: USDC, USDT, DAI, other stablecoins");
        console.log("- Use Volatile Strategy for: Altcoins, new tokens, high-risk assets");

        console.log("\nNext steps:");
        console.log("1. Deploy mock tokens for testing (optional)");
        console.log("2. Configure reserves using config scripts");
        console.log("3. Set up oracles for price feeds");
        console.log("4. Initialize reserves with appropriate strategies");
    }
}
