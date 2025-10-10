// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

// Aave V3 Core imports
import {PoolAddressesProvider} from "aave-v3-core/contracts/protocol/configuration/PoolAddressesProvider.sol";
import {IPool} from "aave-v3-core/contracts/interfaces/IPool.sol";
import {DataTypes} from "aave-v3-core/contracts/protocol/libraries/types/DataTypes.sol";

// Utils
import {BaseScript} from "../utils/BaseScript.sol";
import {Constants} from "../utils/Constants.sol";

/**
 * @title Check Reserves
 * @notice Check what reserves are currently listed in the Aave V3.0 protocol
 * @dev Run with: forge script script/config/CheckReserves.s.sol:CheckReserves --rpc-url $HYPEREVM_TESTNET_RPC_URL -vvvv
 */
contract CheckReserves is BaseScript {
    function run() external {
        console.log("=================================================");
        console.log("        CHECKING AAVE V3.0 RESERVES");
        console.log("=================================================");

        // Verify we're on the correct network
        require(block.chainid == Constants.CHAIN_ID, "Wrong network - expected HyperEVM Testnet");

        // Load deployment file
        string memory deploymentJson = loadDeployment();
        require(bytes(deploymentJson).length > 2, "No valid deployment data found");

        address poolAddressesProvider = vm.parseJsonAddress(deploymentJson, ".poolAddressesProvider");
        require(poolAddressesProvider != address(0), "PoolAddressesProvider not found");

        PoolAddressesProvider provider = PoolAddressesProvider(poolAddressesProvider);
        address poolProxy = provider.getPool();
        require(poolProxy != address(0), "Pool proxy not found");

        console.log("Pool Address:", poolProxy);
        console.log("PoolAddressesProvider:", poolAddressesProvider);

        // Check available mock tokens
        console.log("\n=== AVAILABLE MOCK TOKENS ===");
        _checkMockToken(deploymentJson, "USDC");
        _checkMockToken(deploymentJson, "USDT");
        _checkMockToken(deploymentJson, "DAI");
        _checkMockToken(deploymentJson, "WBTC");
        _checkMockToken(deploymentJson, "LINK");
        _checkMockToken(deploymentJson, "UNI");

        // Try to check reserves for each token
        console.log("\n=== RESERVE STATUS ===");
        IPool pool = IPool(poolProxy);

        _checkReserveStatus(pool, deploymentJson, "USDC");
        _checkReserveStatus(pool, deploymentJson, "USDT");
        _checkReserveStatus(pool, deploymentJson, "DAI");
        _checkReserveStatus(pool, deploymentJson, "WBTC");

        console.log("\n=== PROTOCOL STATUS ===");
        console.log("Protocol is deployed and ready for reserve listing");
        console.log("Next steps: Configure price oracles before listing reserves");

        console.log("=================================================");
    }

    function _checkMockToken(string memory json, string memory symbol) internal view {
        string memory key = string(abi.encodePacked(".mockTokens.", symbol));
        try vm.parseJsonAddress(json, key) returns (address tokenAddress) {
            console.log(string(abi.encodePacked(symbol, " Token:")), tokenAddress);
        } catch {
            console.log(string(abi.encodePacked(symbol, " Token: NOT FOUND")));
        }
    }

    function _checkReserveStatus(IPool pool, string memory json, string memory symbol) internal view {
        string memory key = string(abi.encodePacked(".mockTokens.", symbol));
        try vm.parseJsonAddress(json, key) returns (address tokenAddress) {
            // Try to get reserve data
            try pool.getReserveData(tokenAddress) returns (DataTypes.ReserveData memory reserveData) {
                if (reserveData.aTokenAddress != address(0)) {
                    console.log(string(abi.encodePacked(symbol, " Reserve: LISTED")));
                    console.log("  aToken:", reserveData.aTokenAddress);
                    console.log("  Stable Debt Token:", reserveData.stableDebtTokenAddress);
                    console.log("  Variable Debt Token:", reserveData.variableDebtTokenAddress);
                } else {
                    console.log(string(abi.encodePacked(symbol, " Reserve: NOT LISTED")));
                }
            } catch {
                console.log(string(abi.encodePacked(symbol, " Reserve: NOT LISTED (ERROR)")));
            }
        } catch {
            console.log(string(abi.encodePacked(symbol, " Reserve: TOKEN NOT FOUND")));
        }
    }
}
