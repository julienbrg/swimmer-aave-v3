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
        console.log("Network: Chain ID", block.chainid);
        console.log("=================================================");

        // Network check removed - script works on any network

        // Load PoolAddressesProvider from broadcast files
        address poolAddressesProvider = _getPoolAddressesProviderFromBroadcast();
        require(poolAddressesProvider != address(0), "PoolAddressesProvider not found in broadcast files");

        PoolAddressesProvider provider = PoolAddressesProvider(poolAddressesProvider);
        address poolProxy = provider.getPool();
        require(poolProxy != address(0), "Pool proxy not found");

        console.log("Pool Address:", poolProxy);
        console.log("PoolAddressesProvider:", poolAddressesProvider);

        // Load mock tokens from broadcast files
        console.log("\n=== AVAILABLE MOCK TOKENS ===");
        address usdcToken = _getMockTokenFromBroadcast("USDC");
        address usdtToken = _getMockTokenFromBroadcast("USDT");
        address daiToken = _getMockTokenFromBroadcast("DAI");
        address wbtcToken = _getMockTokenFromBroadcast("WBTC");
        address linkToken = _getMockTokenFromBroadcast("LINK");
        address uniToken = _getMockTokenFromBroadcast("UNI");

        _checkMockTokenAddress("USDC", usdcToken);
        _checkMockTokenAddress("USDT", usdtToken);
        _checkMockTokenAddress("DAI", daiToken);
        _checkMockTokenAddress("WBTC", wbtcToken);
        _checkMockTokenAddress("LINK", linkToken);
        _checkMockTokenAddress("UNI", uniToken);

        // Try to check reserves for each token
        console.log("\n=== RESERVE STATUS ===");
        IPool pool = IPool(poolProxy);

        _checkReserveStatusByAddress(pool, "USDC", usdcToken);
        _checkReserveStatusByAddress(pool, "USDT", usdtToken);
        _checkReserveStatusByAddress(pool, "DAI", daiToken);
        _checkReserveStatusByAddress(pool, "WBTC", wbtcToken);

        console.log("\n=== PROTOCOL STATUS ===");
        console.log("Protocol is deployed and ready for reserve listing");
        console.log("Next steps: Configure price oracles before listing reserves");

        console.log("=================================================");
    }

    function _checkMockTokenAddress(string memory symbol, address tokenAddress) internal pure {
        if (tokenAddress != address(0)) {
            console.log(string(abi.encodePacked(symbol, " Token:")), tokenAddress);
        } else {
            console.log(string(abi.encodePacked(symbol, " Token: NOT FOUND")));
        }
    }

    function _checkReserveStatusByAddress(IPool pool, string memory symbol, address tokenAddress) internal view {
        if (tokenAddress == address(0)) {
            console.log(string(abi.encodePacked(symbol, " Reserve: TOKEN NOT FOUND")));
            return;
        }

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
    }

    function _getPoolAddressesProviderFromBroadcast() internal view returns (address) {
        string memory broadcastFile = string(abi.encodePacked("./broadcast/01_DeployCoreContracts.s.sol/", vm.toString(block.chainid), "/run-latest.json"));
        
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
        string memory broadcastFile = string(abi.encodePacked("./broadcast/09_DeployMockTokens.s.sol/", vm.toString(block.chainid), "/run-latest.json"));
        
        try vm.readFile(broadcastFile) returns (string memory json) {
            // Mock tokens are deployed in a specific order: USDC, USDT, DAI, WBTC, LINK, UNI
            uint256 tokenIndex = _getTokenIndex(tokenSymbol);
            if (tokenIndex == type(uint256).max) return address(0);
            
            string memory path = string(abi.encodePacked(".transactions[", vm.toString(tokenIndex), "].contractAddress"));
            try vm.parseJsonAddress(json, path) returns (address tokenAddr) {
                return tokenAddr;
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
