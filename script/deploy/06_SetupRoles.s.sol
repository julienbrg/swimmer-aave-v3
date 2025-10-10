// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

// Aave V3 Core imports
import {ACLManager} from "aave-v3-core/contracts/protocol/configuration/ACLManager.sol";

// Utils
import {BaseScript} from "../utils/BaseScript.sol";

/**
 * @title Deploy Core Contracts - Step 6: Setup Roles
 * @notice Sets up initial admin roles in ACLManager
 * @dev Run with: forge script script/deploy/06_SetupRoles.s.sol:SetupRoles --rpc-url $RPC_URL --broadcast
 */
contract SetupRoles is BaseScript {
    function run() external {
        // Check if already deployed
        if (_hasBeenDeployed("06_SetupRoles.s.sol")) {
            console.log("Roles setup already exists. Skipping setup.");
            return;
        }

        // Get ACLManager from step 3's broadcast file
        address aclManager = _getACLManager();
        require(aclManager != address(0), "ACLManager not found. Run step 3 first.");

        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        logSeparator("SETTING UP ADMIN ROLES");
        console.log("Using ACLManager:", aclManager);
        console.log("Setting up roles for:", deployer);

        startBroadcastWithInfo();

        ACLManager manager = ACLManager(aclManager);

        // Add deployer as initial admin roles
        // NOTE: In production, these should be changed to multisig/governance contracts
        manager.addPoolAdmin(deployer);
        console.log("Pool Admin set:", deployer);

        manager.addEmergencyAdmin(deployer);
        console.log("Emergency Admin set:", deployer);

        manager.addAssetListingAdmin(deployer);
        console.log("Asset Listing Admin set:", deployer);

        stopBroadcastWithInfo();

        // Contract addresses are automatically saved to broadcast files

        console.log("\nWARNING: In production, transfer admin roles to governance contracts!");
        logSeparator("CORE DEPLOYMENT COMPLETED");
        console.log("Next: Deploy token implementations with 07_DeployTokenImplementations.s.sol");
    }
}
