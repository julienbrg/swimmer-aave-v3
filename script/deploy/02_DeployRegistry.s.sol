// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

// Aave V3 Core imports
import {PoolAddressesProviderRegistry} from
    "aave-v3-core/contracts/protocol/configuration/PoolAddressesProviderRegistry.sol";

// Utils
import {BaseScript} from "../utils/BaseScript.sol";

/**
 * @title Deploy Core Contracts - Step 2: Registry
 * @notice Deploys the PoolAddressesProviderRegistry and registers the provider
 * @dev Run with: forge script script/deploy/02_DeployRegistry.s.sol:DeployRegistry --rpc-url $RPC_URL --broadcast
 */
contract DeployRegistry is BaseScript {
    function run() external {
        // Get PoolAddressesProvider from previous step's broadcast
        address poolAddressesProvider = _getPoolAddressesProvider();
        require(poolAddressesProvider != address(0), "PoolAddressesProvider not found in broadcast files");

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        logSeparator("DEPLOYING REGISTRY");
        console.log("Using PoolAddressesProvider:", poolAddressesProvider);

        startBroadcastWithInfo();

        // Deploy registry
        PoolAddressesProviderRegistry registry = new PoolAddressesProviderRegistry(deployer);

        // Register the provider
        registry.registerAddressesProvider(poolAddressesProvider, 1);

        stopBroadcastWithInfo();

        verifyAddress(address(registry), "PoolAddressesProviderRegistry");

        // Contract addresses are automatically saved to broadcast files

        console.log("Registry deployed at:", address(registry));
        console.log("Provider registered in registry");
        logSeparator("STEP 2 COMPLETED - RUN STEP 3 NEXT");
    }

    function _getPoolAddressesProvider() internal view override returns (address) {
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
}
