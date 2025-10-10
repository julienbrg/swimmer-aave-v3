// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

// Aave V3 Core imports
import {PoolAddressesProvider} from "aave-v3-core/contracts/protocol/configuration/PoolAddressesProvider.sol";
import {ACLManager} from "aave-v3-core/contracts/protocol/configuration/ACLManager.sol";
import {IPoolAddressesProvider} from "aave-v3-core/contracts/interfaces/IPoolAddressesProvider.sol";

// Utils
import {BaseScript} from "../utils/BaseScript.sol";

/**
 * @title Deploy Core Contracts - Step 3: ACL
 * @notice Sets up ACL Admin and deploys ACLManager
 * @dev Run with: forge script script/deploy/03_DeployACL.s.sol:DeployACL --rpc-url $RPC_URL --broadcast
 */
contract DeployACL is BaseScript {
    function run() external {
        // Check if already deployed
        if (_hasBeenDeployed("03_DeployACL.s.sol")) {
            console.log("ACL deployment already exists. Skipping deployment.");
            address aclManager = _getACLManager();
            if (aclManager != address(0)) {
                console.log("Found existing ACLManager at:", aclManager);
                return;
            }
        }

        // Get PoolAddressesProvider from step 1's broadcast file
        address poolAddressesProvider = _getPoolAddressesProvider();
        require(poolAddressesProvider != address(0), "PoolAddressesProvider not found. Run step 1 first.");

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        logSeparator("DEPLOYING ACL MANAGER");
        console.log("Using PoolAddressesProvider:", poolAddressesProvider);

        PoolAddressesProvider provider = PoolAddressesProvider(poolAddressesProvider);

        // Verify deployer is owner
        address currentOwner = provider.owner();
        console.log("Current provider owner:", currentOwner);
        require(currentOwner == deployer, "Deployer is not the owner of PoolAddressesProvider");

        startBroadcastWithInfo();

        // First, set ACL Admin (required before ACLManager deployment)
        console.log("Setting ACL Admin to deployer...");
        provider.setACLAdmin(deployer);
        console.log("ACL Admin set to:", deployer);

        // Deploy ACL Manager (reads ACL admin from provider)
        console.log("Deploying ACLManager...");
        ACLManager aclManager = new ACLManager(IPoolAddressesProvider(poolAddressesProvider));
        console.log("ACLManager deployed at:", address(aclManager));

        // Set ACLManager in provider
        provider.setACLManager(address(aclManager));
        console.log("ACLManager set in provider");

        stopBroadcastWithInfo();

        verifyAddress(address(aclManager), "ACLManager");

        // Contract addresses are automatically saved to broadcast files

        console.log("ACLManager deployed at:", address(aclManager));
        console.log("ACLManager set in provider");
        logSeparator("STEP 3 COMPLETED - RUN STEP 4 NEXT");
    }
}
