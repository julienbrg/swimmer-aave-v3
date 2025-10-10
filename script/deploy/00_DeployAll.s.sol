// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

// Aave V3 Core imports for proxy checking
import {PoolAddressesProvider} from "aave-v3-core/contracts/protocol/configuration/PoolAddressesProvider.sol";

// Utils
import {BaseScript} from "../utils/BaseScript.sol";

/**
 * @title Generate Deployment Summary
 * @notice Creates a markdown file with all deployed addresses (proxies and implementations)
 * @dev Run after deployment completion to generate summary
 */
contract DeployAll is BaseScript {
    function run() external {
        console.log("=================================================");
        console.log("    GENERATING AAVE V3.0 DEPLOYMENT SUMMARY");
        console.log("=================================================");

        // Load deployment file
        string memory deploymentJson = loadDeployment();

        // Check if we have a valid deployment file
        if (bytes(deploymentJson).length <= 2) {
            // Empty JSON is "{}"
            console.log("ERROR: No valid deployment data found.");
            console.log("Please run deployment scripts 01-09 first to create deployments.");
            console.log("=================================================");
            return;
        }

        // Parse network info with error handling
        uint256 chainId;
        string memory network;
        uint256 timestamp;

        try vm.parseJsonUint(deploymentJson, ".chainId") returns (uint256 _chainId) {
            chainId = _chainId;
        } catch {
            chainId = block.chainid; // Fallback to current chain
        }

        try vm.parseJsonString(deploymentJson, ".network") returns (string memory _network) {
            network = _network;
        } catch {
            network = chainId == 998 ? "hyperevm-testnet" : "unknown"; // Fallback
        }

        try vm.parseJsonUint(deploymentJson, ".timestamp") returns (uint256 _timestamp) {
            timestamp = _timestamp;
        } catch {
            timestamp = block.timestamp; // Fallback to current time
        }

        console.log("Network:", network);
        console.log("Chain ID:", chainId);

        // Generate markdown content
        string memory markdown = _generateMarkdown(deploymentJson, network, chainId, timestamp);

        // Save markdown file with network name and timestamp
        string memory filename = string(abi.encodePacked("./deployments/", network, "-", vm.toString(timestamp), ".md"));
        vm.writeFile(filename, markdown);

        console.log("Deployment summary generated:", filename);
        console.log("=================================================");
    }

    function _generateMarkdown(string memory deploymentJson, string memory network, uint256 chainId, uint256 timestamp)
        internal
        view
        returns (string memory)
    {
        // Start building markdown
        string memory markdown = string(
            abi.encodePacked(
                "# Aave V3.0 Deployment Summary\n\n",
                "**Network:** ",
                network,
                "\n",
                "**Chain ID:** ",
                vm.toString(chainId),
                "\n",
                "**Deployment Date:** ",
                _formatTimestamp(timestamp),
                "\n\n"
            )
        );

        // Core Contracts Section
        markdown = string(
            abi.encodePacked(
                markdown,
                "## Core Protocol Contracts\n\n",
                "| Contract | Type | Address | Description |\n",
                "|----------|------|---------|-------------|\n"
            )
        );

        // Add core contracts with proxy detection
        markdown = _addContractRow(
            markdown,
            deploymentJson,
            "poolAddressesProvider",
            "PoolAddressesProvider",
            "Proxy",
            "Main registry for all protocol contracts"
        );
        markdown = _addContractRow(
            markdown,
            deploymentJson,
            "poolAddressesProviderRegistry",
            "PoolAddressesProviderRegistry",
            "Contract",
            "Registry of all PoolAddressesProvider contracts"
        );
        markdown = _addContractRow(
            markdown, deploymentJson, "aclManager", "ACLManager", "Contract", "Access control and permissions manager"
        );

        // Pool contracts (these are implementations, proxies are created by provider)
        address poolAddressesProvider = vm.parseJsonAddress(deploymentJson, ".poolAddressesProvider");
        if (poolAddressesProvider != address(0)) {
            PoolAddressesProvider provider = PoolAddressesProvider(poolAddressesProvider);
            address poolProxy = provider.getPool();
            address poolConfiguratorProxy = provider.getPoolConfigurator();

            if (poolProxy != address(0)) {
                markdown = string(
                    abi.encodePacked(
                        markdown,
                        "| Pool | Proxy | `",
                        vm.toString(poolProxy),
                        "` | Main lending pool contract (proxy) |\n"
                    )
                );
            }

            if (poolConfiguratorProxy != address(0)) {
                markdown = string(
                    abi.encodePacked(
                        markdown,
                        "| PoolConfigurator | Proxy | `",
                        vm.toString(poolConfiguratorProxy),
                        "` | Pool configuration contract (proxy) |\n"
                    )
                );
            }
        }

        markdown =
            _addContractRow(markdown, deploymentJson, "pool", "Pool", "Implementation", "Pool implementation contract");
        markdown = _addContractRow(
            markdown,
            deploymentJson,
            "poolConfigurator",
            "PoolConfigurator",
            "Implementation",
            "PoolConfigurator implementation contract"
        );
        markdown =
            _addContractRow(markdown, deploymentJson, "oracle", "AaveOracle", "Contract", "Price oracle for all assets");
        markdown = _addContractRow(
            markdown,
            deploymentJson,
            "protocolDataProvider",
            "AaveProtocolDataProvider",
            "Contract",
            "Protocol data and statistics provider"
        );

        // Token Implementation Section
        markdown = string(
            abi.encodePacked(
                markdown,
                "\n## Token Implementations\n\n",
                "| Contract | Address | Description |\n",
                "|----------|---------|-------------|\n"
            )
        );

        markdown = _addImplementationRow(
            markdown, deploymentJson, "aTokenImpl", "AToken Implementation", "Template for all aToken contracts"
        );
        markdown = _addImplementationRow(
            markdown,
            deploymentJson,
            "stableDebtTokenImpl",
            "StableDebtToken Implementation",
            "Template for all stable debt token contracts"
        );
        markdown = _addImplementationRow(
            markdown,
            deploymentJson,
            "variableDebtTokenImpl",
            "VariableDebtToken Implementation",
            "Template for all variable debt token contracts"
        );

        // Interest Rate Strategies Section
        markdown = string(
            abi.encodePacked(
                markdown,
                "\n## Interest Rate Strategies\n\n",
                "| Strategy | Address | Optimal Usage | Base Rate | Slope 1 | Slope 2 |\n",
                "|----------|---------|---------------|-----------|---------|----------|\n"
            )
        );

        markdown = _addStrategyRow(
            markdown, deploymentJson, "defaultInterestRateStrategy", "Default Strategy", "80%", "0%", "4%", "75%"
        );
        markdown = _addStrategyRow(
            markdown, deploymentJson, "stablecoinInterestRateStrategy", "Stablecoin Strategy", "90%", "0%", "4%", "60%"
        );
        markdown = _addStrategyRow(
            markdown,
            deploymentJson,
            "volatileAssetInterestRateStrategy",
            "Volatile Asset Strategy",
            "70%",
            "0%",
            "7%",
            "300%"
        );

        // Mock Tokens Section (if they exist)
        if (_hasKey(deploymentJson, ".mockTokens")) {
            markdown = string(
                abi.encodePacked(
                    markdown,
                    "\n## Mock Tokens (Testnet Only)\n\n",
                    "**These are test tokens with no real value**\n\n",
                    "| Token | Symbol | Address | Decimals |\n",
                    "|-------|---------|---------|----------|\n"
                )
            );

            markdown = _addMockTokenRow(markdown, deploymentJson, "USDC", "Mock USD Coin", 6);
            markdown = _addMockTokenRow(markdown, deploymentJson, "USDT", "Mock Tether USD", 6);
            markdown = _addMockTokenRow(markdown, deploymentJson, "DAI", "Mock Dai Stablecoin", 18);
            markdown = _addMockTokenRow(markdown, deploymentJson, "WBTC", "Mock Wrapped Bitcoin", 8);
            markdown = _addMockTokenRow(markdown, deploymentJson, "LINK", "Mock Chainlink", 18);
            markdown = _addMockTokenRow(markdown, deploymentJson, "UNI", "Mock Uniswap", 18);
        }

        // Admin Information Section
        markdown = string(
            abi.encodePacked(
                markdown,
                "\n## Admin Configuration\n\n",
                "**Current Admin Roles:** All roles are currently set to the deployer address\n\n",
                "- **Pool Admin:** Can modify pool parameters and configurations\n",
                "- **Emergency Admin:** Can pause/unpause the protocol in emergencies\n",
                "- **Asset Listing Admin:** Can add new assets to the protocol\n\n",
                "- **IMPORTANT:** In production, these roles should be transferred to multisig or governance contracts.\n\n"
            )
        );

        // Usage Instructions
        markdown = string(
            abi.encodePacked(
                markdown,
                "## Usage\n\n",
                "### Interacting with the Pool\n\n",
                "The main entry point is the Pool proxy contract. Use this address for all user interactions:\n\n"
            )
        );

        if (poolAddressesProvider != address(0)) {
            PoolAddressesProvider provider = PoolAddressesProvider(poolAddressesProvider);
            address poolProxy = provider.getPool();
            if (poolProxy != address(0)) {
                markdown = string(abi.encodePacked(markdown, "**Pool Contract:** `", vm.toString(poolProxy), "`\n\n"));
            }
        }

        markdown = string(
            abi.encodePacked(
                markdown,
                "### Next Steps\n\n",
                "1. **Configure Price Oracles:** Set up price feeds for each asset\n",
                "2. **Initialize Reserves:** Add assets to the lending pool\n",
                "3. **Set Risk Parameters:** Configure LTV, liquidation thresholds, etc.\n",
                "4. **Transfer Admin Rights:** Move admin roles to governance contracts\n",
                "5. **Testing:** Verify all functionality works correctly\n\n",
                "---\n\n",
                "*Generated by Aave V3.0 Deployment Scripts*\n"
            )
        );

        return markdown;
    }

    function _addContractRow(
        string memory markdown,
        string memory json,
        string memory key,
        string memory name,
        string memory contractType,
        string memory description
    ) internal pure returns (string memory) {
        try vm.parseJsonAddress(json, string(abi.encodePacked(".", key))) returns (address contractAddress) {
            if (contractAddress != address(0)) {
                return string(
                    abi.encodePacked(
                        markdown,
                        "| ",
                        name,
                        " | ",
                        contractType,
                        " | `",
                        vm.toString(contractAddress),
                        "` | ",
                        description,
                        " |\n"
                    )
                );
            }
        } catch {
            // Key doesn't exist or invalid format
        }
        return markdown;
    }

    function _addImplementationRow(
        string memory markdown,
        string memory json,
        string memory key,
        string memory name,
        string memory description
    ) internal pure returns (string memory) {
        try vm.parseJsonAddress(json, string(abi.encodePacked(".", key))) returns (address contractAddress) {
            if (contractAddress != address(0)) {
                return string(
                    abi.encodePacked(
                        markdown, "| ", name, " | `", vm.toString(contractAddress), "` | ", description, " |\n"
                    )
                );
            }
        } catch {
            // Key doesn't exist or invalid format
        }
        return markdown;
    }

    function _addStrategyRow(
        string memory markdown,
        string memory json,
        string memory key,
        string memory name,
        string memory optimal,
        string memory base,
        string memory slope1,
        string memory slope2
    ) internal pure returns (string memory) {
        try vm.parseJsonAddress(json, string(abi.encodePacked(".", key))) returns (address contractAddress) {
            if (contractAddress != address(0)) {
                return string(
                    abi.encodePacked(
                        markdown,
                        "| ",
                        name,
                        " | `",
                        vm.toString(contractAddress),
                        "` | ",
                        optimal,
                        " | ",
                        base,
                        " | ",
                        slope1,
                        " | ",
                        slope2,
                        " |\n"
                    )
                );
            }
        } catch {
            // Key doesn't exist or invalid format
        }
        return markdown;
    }

    function _addMockTokenRow(
        string memory markdown,
        string memory json,
        string memory symbol,
        string memory name,
        uint8 decimals
    ) internal pure returns (string memory) {
        string memory key = string(abi.encodePacked(".mockTokens.", symbol));
        if (_hasKey(json, key)) {
            address tokenAddress = vm.parseJsonAddress(json, key);
            return string(
                abi.encodePacked(
                    markdown,
                    "| ",
                    name,
                    " | ",
                    symbol,
                    " | `",
                    vm.toString(tokenAddress),
                    "` | ",
                    vm.toString(decimals),
                    " |\n"
                )
            );
        }
        return markdown;
    }

    function _hasKey(string memory json, string memory key) internal pure returns (bool) {
        // Simple check if key exists in JSON - in practice you might want more robust checking
        bytes memory jsonBytes = bytes(json);
        bytes memory keyBytes = bytes(key);

        if (keyBytes.length == 0 || jsonBytes.length == 0) return false;

        // Look for the key pattern in JSON
        for (uint256 i = 0; i <= jsonBytes.length - keyBytes.length; i++) {
            bool found = true;
            for (uint256 j = 0; j < keyBytes.length; j++) {
                if (jsonBytes[i + j] != keyBytes[j]) {
                    found = false;
                    break;
                }
            }
            if (found) return true;
        }
        return false;
    }

    function _formatTimestamp(uint256 timestamp) internal pure returns (string memory) {
        // Simple timestamp formatting - you could make this more sophisticated
        return string(abi.encodePacked("Unix timestamp: ", vm.toString(timestamp)));
    }
}
