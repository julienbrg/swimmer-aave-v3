// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

abstract contract BaseScript is Script {
    function startBroadcastWithInfo() internal {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(privateKey);

        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("Balance:", deployer.balance / 1e18, "ETH");

        vm.startBroadcast(privateKey);
    }

    function stopBroadcastWithInfo() internal {
        vm.stopBroadcast();
    }

    function loadAddressFromBroadcast(string memory scriptName, string memory contractName) internal view returns (address) {
        string memory broadcastFile = string(abi.encodePacked("./broadcast/", scriptName, "/", vm.toString(block.chainid), "/run-latest.json"));
        
        try vm.readFile(broadcastFile) returns (string memory json) {
            bytes memory jsonBytes = bytes(json);
            if (jsonBytes.length <= 2) {
                return address(0);
            }
            
            // Parse transactions array to find the contract
            string memory transactionsKey = ".transactions";
            try vm.parseJson(json, transactionsKey) returns (bytes memory transactionsData) {
                // For now, return address(0) as we'll implement proper parsing if needed
                // Most scripts can use the direct contract address from their deployment
                return address(0);
            } catch {
                return address(0);
            }
        } catch {
            return address(0);
        }
    }

    /**
     * @dev Get contract address from broadcast file by transaction index
     * @param scriptName The script name (e.g., "01_DeployCoreContracts.s.sol")
     * @param transactionIndex The index of the transaction in the broadcast file (0-based)
     * @return The contract address, or address(0) if not found
     */
    function _getContractFromBroadcast(string memory scriptName, uint256 transactionIndex) internal view virtual returns (address) {
        string memory broadcastFile = string(abi.encodePacked("./broadcast/", scriptName, "/", vm.toString(block.chainid), "/run-latest.json"));
        
        try vm.readFile(broadcastFile) returns (string memory json) {
            bytes memory jsonBytes = bytes(json);
            if (jsonBytes.length <= 2) {
                return address(0);
            }
            
            // Parse the transaction at the specified index
            string memory transactionKey = string(abi.encodePacked(".transactions[", vm.toString(transactionIndex), "].contractAddress"));
            try vm.parseJsonAddress(json, transactionKey) returns (address contractAddress) {
                return contractAddress;
            } catch {
                return address(0);
            }
        } catch {
            return address(0);
        }
    }

    /**
     * @dev Get the PoolAddressesProvider address from step 1's broadcast file
     * @return The PoolAddressesProvider address
     */
    function _getPoolAddressesProvider() internal view virtual returns (address) {
        return _getContractFromBroadcast("01_DeployCoreContracts.s.sol", 0);
    }

    /**
     * @dev Get the ACLManager address from step 3's broadcast file  
     * @return The ACLManager address
     */
    function _getACLManager() internal view returns (address) {
        return _getContractFromBroadcast("03_DeployACL.s.sol", 1); // ACLManager is typically the 2nd transaction (index 1)
    }

    /**
     * @dev Get the Pool implementation address from step 4's broadcast file
     * @return The Pool implementation address
     */
    function _getPoolImplementation() internal view returns (address) {
        return _getContractFromBroadcast("04_DeployPool.s.sol", 0);
    }

    /**
     * @dev Get the PoolConfigurator implementation address from step 4's broadcast file
     * @return The PoolConfigurator implementation address
     */
    function _getPoolConfiguratorImplementation() internal view returns (address) {
        return _getContractFromBroadcast("04_DeployPool.s.sol", 1);
    }

    /**
     * @dev Get the AaveOracle address from step 5's broadcast file
     * @return The AaveOracle address
     */
    function _getAaveOracle() internal view returns (address) {
        return _getContractFromBroadcast("05_DeployOracle.s.sol", 0);
    }

    /**
     * @dev Get the AaveProtocolDataProvider address from step 5's broadcast file
     * @return The AaveProtocolDataProvider address
     */
    function _getAaveProtocolDataProvider() internal view returns (address) {
        return _getContractFromBroadcast("05_DeployOracle.s.sol", 1);
    }

    /**
     * @dev Check if this script has already been deployed by checking its broadcast file
     * @param scriptName The script name to check
     * @return true if the script has been deployed (broadcast file exists with transactions)
     */
    function _hasBeenDeployed(string memory scriptName) internal view returns (bool) {
        return checkDeploymentExists(scriptName);
    }

    function checkDeploymentExists(string memory scriptName) internal view returns (bool) {
        string memory broadcastFile = string(abi.encodePacked("./broadcast/", scriptName, "/", vm.toString(block.chainid), "/run-latest.json"));
        
        try vm.readFile(broadcastFile) returns (string memory json) {
            // Check if the broadcast file contains successful transactions
            return bytes(json).length > 50; // Basic check for non-empty broadcast
        } catch {
            return false;
        }
    }

    function requireEnvVar(string memory name) internal view returns (string memory) {
        try vm.envString(name) returns (string memory value) {
            require(bytes(value).length > 0, string(abi.encodePacked("Empty env var: ", name)));
            return value;
        } catch {
            revert(string(abi.encodePacked("Missing env var: ", name)));
        }
    }

    function logSeparator(string memory title) internal pure {
        console.log("\n================================");
        console.log(title);
        console.log("================================");
    }

    function verifyAddress(address addr, string memory name) internal view {
        require(addr != address(0), string(abi.encodePacked(name, " address is zero")));
        require(addr.code.length > 0, string(abi.encodePacked(name, " has no code")));
        console.log(string(abi.encodePacked(name, " verified at:")), addr);
    }
}
