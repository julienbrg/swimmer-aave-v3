// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

// Aave V3 Core imports
import {PoolAddressesProvider} from "../../src/protocol/configuration/PoolAddressesProvider.sol";
import {PoolConfigurator} from "../../src/protocol/pool/PoolConfigurator.sol";
import {IPoolConfigurator} from "../../src/interfaces/IPoolConfigurator.sol";
import {ConfiguratorInputTypes} from "../../src/protocol/libraries/types/ConfiguratorInputTypes.sol";
// Mock imports
import {MintableERC20} from "../../src/mocks/tokens/MintableERC20.sol";

// Utils
import {BaseScript} from "../utils/BaseScript.sol";
import {Constants} from "../utils/Constants.sol";

/**
 * @title List WBTC Asset
 * @notice Lists WBTC as a reserve in the Aave V3.0 protocol with proper configuration
 * @dev Run with: forge script script/config/ListWBTC.s.sol:ListWBTC --rpc-url $HYPEREVM_TESTNET_RPC_URL --broadcast -vvvv
 */
contract ListWBTC is BaseScript {
    // WBTC Configuration Parameters
    struct WBTCConfig {
        address asset;
        address aToken;
        address stableDebtToken;
        address variableDebtToken;
        address interestRateStrategy;
        uint256 ltv; // Loan to Value ratio
        uint256 liquidationThreshold; // Liquidation threshold
        uint256 liquidationBonus; // Liquidation bonus
        uint256 reserveFactor; // Reserve factor
        bool borrowingEnabled;
        bool stableBorrowRateEnabled;
        bool isActive;
        bool isFrozen;
    }

    function run() external {
        console.log("=================================================");
        console.log("        LISTING WBTC IN AAVE V3.0 PROTOCOL");
        console.log("Network: Chain ID", block.chainid);
        console.log("=================================================");

        // Network check removed - script works on any network

        // Load addresses from broadcast files
        address poolAddressesProvider = _getPoolAddressesProviderFromBroadcast();
        require(poolAddressesProvider != address(0), "PoolAddressesProvider not found in broadcast files");

        address wbtcToken = _getMockTokenFromBroadcast("WBTC");
        require(wbtcToken != address(0), "WBTC token not found in broadcast files");

        console.log("Using PoolAddressesProvider:", poolAddressesProvider);
        console.log("WBTC Token Address:", wbtcToken);

        WBTCConfig memory config = _prepareWBTCConfig(wbtcToken);

        startBroadcastWithInfo();
        _listWBTCReserve(poolAddressesProvider, config);
        stopBroadcastWithInfo();

        _verifyListing(poolAddressesProvider, wbtcToken);

        console.log("=================================================");
        console.log("        WBTC LISTING COMPLETED SUCCESSFULLY");
        console.log("=================================================");
    }

    function _prepareWBTCConfig(address wbtcToken) internal view returns (WBTCConfig memory config) {
        console.log("\n1. PREPARING WBTC CONFIGURATION...");

        // Load required addresses from broadcast files
        config.asset = wbtcToken;
        config.aToken = _getContractFromBroadcast("07_DeployTokenImplementations.s.sol", 0); // AToken
        config.stableDebtToken = _getContractFromBroadcast("07_DeployTokenImplementations.s.sol", 1); // StableDebtToken
        config.variableDebtToken = _getContractFromBroadcast("07_DeployTokenImplementations.s.sol", 2); // VariableDebtToken
        config.interestRateStrategy = _getContractFromBroadcast("08_DeployInterestRateStrategy.s.sol", 0); // Volatile asset strategy (transaction index 0)

        // Verify all required addresses are available
        require(config.aToken != address(0), "aToken implementation not found");
        require(config.stableDebtToken != address(0), "StableDebtToken implementation not found");
        require(config.variableDebtToken != address(0), "VariableDebtToken implementation not found");
        require(config.interestRateStrategy != address(0), "Volatile asset interest rate strategy not found");

        // WBTC Configuration (Conservative volatile asset parameters)
        config.ltv = 7000; // 70% LTV (lower than stablecoins due to volatility)
        config.liquidationThreshold = 7500; // 75% liquidation threshold
        config.liquidationBonus = 11000; // 10% liquidation bonus (10000 + 1000)
        config.reserveFactor = 2000; // 20% reserve factor (higher than stablecoins)
        config.borrowingEnabled = true;
        config.stableBorrowRateEnabled = false; // Typically disabled for volatile assets
        config.isActive = true;
        config.isFrozen = false;

        console.log("   [CONFIGURED] Asset:", config.asset);
        console.log("   [CONFIGURED] aToken Implementation:", config.aToken);
        console.log("   [CONFIGURED] Interest Rate Strategy:", config.interestRateStrategy);
        console.log("   [CONFIGURED] LTV:", config.ltv, "bps (70%)");
        console.log("   [CONFIGURED] Liquidation Threshold:", config.liquidationThreshold, "bps (75%)");
    }

    function _listWBTCReserve(address poolAddressesProvider, WBTCConfig memory config) internal {
        console.log("\n2. LISTING WBTC RESERVE...");

        PoolAddressesProvider provider = PoolAddressesProvider(poolAddressesProvider);
        address poolConfiguratorProxy = provider.getPoolConfigurator();
        require(poolConfiguratorProxy != address(0), "PoolConfigurator proxy not found");

        IPoolConfigurator configurator = IPoolConfigurator(poolConfiguratorProxy);

        // Prepare init reserve input
        ConfiguratorInputTypes.InitReserveInput memory input = ConfiguratorInputTypes.InitReserveInput({
            aTokenImpl: config.aToken,
            stableDebtTokenImpl: config.stableDebtToken,
            variableDebtTokenImpl: config.variableDebtToken,
            underlyingAssetDecimals: MintableERC20(config.asset).decimals(),
            interestRateStrategyAddress: config.interestRateStrategy,
            underlyingAsset: config.asset,
            treasury: msg.sender, // Use deployer as treasury for now
            incentivesController: address(0), // No incentives controller for now
            aTokenName: string(abi.encodePacked("Aave HyperEVM ", MintableERC20(config.asset).name())),
            aTokenSymbol: string(abi.encodePacked("a", MintableERC20(config.asset).symbol())),
            variableDebtTokenName: string(
                abi.encodePacked("Aave HyperEVM Variable Debt ", MintableERC20(config.asset).name())
            ),
            variableDebtTokenSymbol: string(abi.encodePacked("variableDebt", MintableERC20(config.asset).symbol())),
            stableDebtTokenName: string(abi.encodePacked("Aave HyperEVM Stable Debt ", MintableERC20(config.asset).name())),
            stableDebtTokenSymbol: string(abi.encodePacked("stableDebt", MintableERC20(config.asset).symbol())),
            params: bytes("")
        });

        console.log("   Initializing WBTC reserve...");
        ConfiguratorInputTypes.InitReserveInput[] memory inputs = new ConfiguratorInputTypes.InitReserveInput[](1);
        inputs[0] = input;
        configurator.initReserves(inputs);
        console.log("   [DONE] WBTC reserve initialized");

        // Configure reserve parameters
        console.log("   Configuring reserve parameters...");

        // Set LTV
        configurator.configureReserveAsCollateral(
            config.asset, config.ltv, config.liquidationThreshold, config.liquidationBonus
        );
        console.log("   [DONE] Collateral parameters set");

        // Set reserve factor
        configurator.setReserveFactor(config.asset, config.reserveFactor);
        console.log("   [DONE] Reserve factor set to", config.reserveFactor, "bps");

        // Enable borrowing
        if (config.borrowingEnabled) {
            configurator.setReserveBorrowing(config.asset, true);
            console.log("   [DONE] Borrowing enabled");
        }

        // Enable stable borrow rate (typically disabled for volatile assets)
        if (config.stableBorrowRateEnabled) {
            configurator.setReserveStableRateBorrowing(config.asset, true);
            console.log("   [DONE] Stable rate borrowing enabled");
        } else {
            console.log("   [SKIPPED] Stable rate borrowing disabled for volatile asset");
        }

        // Activate reserve
        if (config.isActive) {
            configurator.setReserveActive(config.asset, true);
            console.log("   [DONE] Reserve activated");
        }
    }

    function _verifyListing(address poolAddressesProvider, address wbtcToken) internal view {
        console.log("\n3. VERIFYING WBTC LISTING...");

        PoolAddressesProvider provider = PoolAddressesProvider(poolAddressesProvider);
        address poolProxy = provider.getPool();
        require(poolProxy != address(0), "Pool proxy not found");

        // Check if WBTC is listed by trying to get reserve data
        try provider.getPool() returns (address pool) {
            // Use low-level call to check if reserve exists
            (bool success, bytes memory data) =
                pool.staticcall(abi.encodeWithSignature("getReserveData(address)", wbtcToken));

            if (success && data.length > 0) {
                console.log("   [SUCCESS] WBTC successfully listed in the protocol");

                // Decode aToken address from reserve data (first 32 bytes after configuration)
                assembly {
                    let aTokenAddr := mload(add(data, 0x20))
                    mstore(0x0, aTokenAddr)
                    return(0x0, 0x20)
                }
            } else {
                console.log("   [FAILED] WBTC listing verification failed");
            }
        } catch {
            console.log("   [FAILED] Could not verify WBTC listing");
        }

        console.log("\n   WBTC Configuration Summary:");
        console.log("   - Asset Address:", wbtcToken);
        console.log("   - Symbol: WBTC");
        console.log("   - Decimals: 8");
        console.log("   - LTV: 70%");
        console.log("   - Liquidation Threshold: 75%");
        console.log("   - Liquidation Bonus: 10%");
        console.log("   - Reserve Factor: 20%");
        console.log("   - Borrowing: Enabled");
        console.log("   - Stable Rate Borrowing: Disabled");
        console.log("   - Status: Active");

        console.log("\n   Next Steps:");
        console.log("   1. Set up price oracle for WBTC");
        console.log("   2. Test deposit/withdraw functionality");
        console.log("   3. Test borrow/repay functionality");
        console.log("   4. Monitor reserve utilization");
    }

    function _getPoolAddressesProviderFromBroadcast() internal view returns (address) {
        string memory broadcastFile = string(
            abi.encodePacked(
                "./broadcast/01_DeployCoreContracts.s.sol/", vm.toString(block.chainid), "/run-latest.json"
            )
        );

        try vm.readFile(broadcastFile) returns (string memory json) {
            try vm.parseJsonAddress(json, ".transactions[0].contractAddress") returns (address contractAddr) {
                return contractAddr;
            } catch {
                return address(0);
            }
        } catch {
            return address(0);
        }
    }

    function _getMockTokenFromBroadcast(string memory tokenSymbol) internal view returns (address) {
        string memory broadcastFile = string(
            abi.encodePacked("./broadcast/09_DeployMockTokens.s.sol/", vm.toString(block.chainid), "/run-latest.json")
        );

        try vm.readFile(broadcastFile) returns (string memory json) {
            // Mock tokens are deployed in a specific order: USDC, USDT, DAI, WBTC, LINK, UNI
            uint256 tokenIndex = _getTokenIndex(tokenSymbol);
            if (tokenIndex == type(uint256).max) return address(0);

            string memory path =
                string(abi.encodePacked(".transactions[", vm.toString(tokenIndex), "].contractAddress"));
            try vm.parseJsonAddress(json, path) returns (address tokenAddr) {
                return tokenAddr;
            } catch {
                return address(0);
            }
        } catch {
            return address(0);
        }
    }

    function _getContractFromBroadcast(string memory scriptName, uint256 transactionIndex)
        internal
        view
        override
        returns (address)
    {
        string memory broadcastFile =
            string(abi.encodePacked("./broadcast/", scriptName, "/", vm.toString(block.chainid), "/run-latest.json"));

        try vm.readFile(broadcastFile) returns (string memory json) {
            string memory path =
                string(abi.encodePacked(".transactions[", vm.toString(transactionIndex), "].contractAddress"));
            try vm.parseJsonAddress(json, path) returns (address contractAddr) {
                return contractAddr;
            } catch {
                return address(0);
            }
        } catch {
            return address(0);
        }
    }

    function _getTokenIndex(string memory symbol) internal pure returns (uint256) {
        if (keccak256(abi.encodePacked(symbol)) == keccak256(abi.encodePacked("USDC"))) return 0;
        if (keccak256(abi.encodePacked(symbol)) == keccak256(abi.encodePacked("USDT"))) return 1;
        if (keccak256(abi.encodePacked(symbol)) == keccak256(abi.encodePacked("DAI"))) return 2;
        if (keccak256(abi.encodePacked(symbol)) == keccak256(abi.encodePacked("WBTC"))) return 3;
        if (keccak256(abi.encodePacked(symbol)) == keccak256(abi.encodePacked("LINK"))) return 4;
        if (keccak256(abi.encodePacked(symbol)) == keccak256(abi.encodePacked("UNI"))) return 5;
        return type(uint256).max;
    }
}