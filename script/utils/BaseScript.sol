// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

abstract contract BaseScript is Script {
    string internal constant DEPLOYMENT_FILE = "./deployments/hyperevm-testnet.json";

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

    function loadDeployment() internal view returns (string memory) {
        try vm.readFile(DEPLOYMENT_FILE) returns (string memory json) {
            return json;
        } catch {
            return "{}";
        }
    }

    function saveDeployment(string memory json) internal {
        vm.writeJson(json, DEPLOYMENT_FILE);
        console.log("Deployment saved to:", DEPLOYMENT_FILE);
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
