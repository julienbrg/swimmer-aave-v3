// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

// Aave V3 Core imports
import {MintableERC20} from "../../src/mocks/tokens/MintableERC20.sol";

// Utils
import {BaseScript} from "../utils/BaseScript.sol";
import {Constants} from "../utils/Constants.sol";

/**
 * @title Deploy Mock Tokens
 * @notice Deploys mock ERC20 tokens for testing on HyperEVM Testnet
 * @dev Run with: forge script script/deploy/04_DeployMockTokens.s.sol:DeployMockTokens --rpc-url $HYPEREVM_TESTNET_RPC_URL --broadcast -vvvv
 */
contract DeployMockTokens is BaseScript {
    struct MockToken {
        string name;
        string symbol;
        uint8 decimals;
        address tokenAddress;
    }

    struct MockTokens {
        MockToken[] tokens;
    }

    function run() external {
        // Check if already deployed
        if (_hasBeenDeployed("09_DeployMockTokens.s.sol")) {
            console.log("Mock tokens deployment already exists. Skipping deployment.");
            return;
        }

        // Network check removed - script works on any network

        logSeparator("DEPLOYING MOCK TOKENS FOR TESTING");
        console.log("WARNING: These are mock tokens for testing only!");

        MockTokens memory mockTokens;
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        startBroadcastWithInfo();
        mockTokens = _deployMockTokens(deployer);
        stopBroadcastWithInfo();

        _verifyDeployment(mockTokens);
        _saveDeployment(mockTokens);

        logSeparator("MOCK TOKENS DEPLOYED SUCCESSFULLY");
        _logDeploymentSummary(mockTokens, deployer);
    }

    function _deployMockTokens(address owner) internal returns (MockTokens memory mockTokens) {
        // Define tokens to deploy
        string[6] memory names = [
            "Mock USD Coin",
            "Mock Tether USD",
            "Mock Dai Stablecoin",
            "Mock Wrapped Bitcoin",
            "Mock Chainlink",
            "Mock Uniswap"
        ];
        string[6] memory symbols = ["USDC", "USDT", "DAI", "WBTC", "LINK", "UNI"];
        uint8[6] memory decimals = [6, 6, 18, 8, 18, 18];

        mockTokens.tokens = new MockToken[](6);

        for (uint256 i = 0; i < 6; i++) {
            console.log(string(abi.encodePacked("\n", vm.toString(i + 1), ". Deploying Mock ", names[i], "...")));

            MintableERC20 token = new MintableERC20(names[i], symbols[i], decimals[i]);

            mockTokens.tokens[i] =
                MockToken({name: names[i], symbol: symbols[i], decimals: decimals[i], tokenAddress: address(token)});

            console.log(string(abi.encodePacked("   ", symbols[i], " deployed:")), address(token));

            // Mint initial supply to deployer for testing (1M tokens each)
            uint256 initialSupply;
            if (decimals[i] == 6) {
                initialSupply = 1_000_000 * 10 ** 6; // 1M USDC/USDT
            } else if (decimals[i] == 8) {
                initialSupply = 1_000 * 10 ** 8; // 1K WBTC
            } else {
                initialSupply = 1_000_000 * 10 ** 18; // 1M for 18 decimal tokens
            }

            token.mint(owner, initialSupply);
            console.log(
                string(
                    abi.encodePacked(
                        "   Minted ", vm.toString(initialSupply / 10 ** decimals[i]), " ", symbols[i], " to:"
                    )
                ),
                owner
            );
        }

        console.log("\nAll mock tokens deployed and minted!");

        return mockTokens;
    }

    function _verifyDeployment(MockTokens memory mockTokens) internal view {
        logSeparator("VERIFYING MOCK TOKENS");

        for (uint256 i = 0; i < mockTokens.tokens.length; i++) {
            MockToken memory token = mockTokens.tokens[i];
            verifyAddress(token.tokenAddress, string(abi.encodePacked("Mock ", token.symbol)));

            // Verify token properties
            MintableERC20 tokenContract = MintableERC20(token.tokenAddress);
            require(keccak256(bytes(tokenContract.name())) == keccak256(bytes(token.name)), "Token name mismatch");
            require(keccak256(bytes(tokenContract.symbol())) == keccak256(bytes(token.symbol)), "Token symbol mismatch");
            require(tokenContract.decimals() == token.decimals, "Token decimals mismatch");
        }

        console.log("All mock token verifications passed!");
    }

    function _saveDeployment(MockTokens memory mockTokens) internal {
        // Contract addresses are automatically saved to broadcast files
        console.log("Mock tokens deployed - addresses saved to broadcast files");
    }

    function _logDeploymentSummary(MockTokens memory mockTokens, address owner) internal view {
        logSeparator("MOCK TOKENS SUMMARY");

        for (uint256 i = 0; i < mockTokens.tokens.length; i++) {
            MockToken memory token = mockTokens.tokens[i];
            console.log(string(abi.encodePacked(token.symbol, " (", token.name, "):")), token.tokenAddress);
        }

        console.log("\nToken holder:", owner);
        console.log("Initial supply minted to deployer for testing purposes");

        console.log("\nNext steps:");
        console.log("1. Deploy mock price oracles for these tokens");
        console.log("2. Initialize these tokens as reserves in Aave");
        console.log("3. Configure risk parameters for each token");

        console.log("\nUseful commands:");
        console.log("# Check token balance");
        console.log(
            "cast call <TOKEN_ADDRESS> \"balanceOf(address)(uint256)\" <YOUR_ADDRESS> --rpc-url $HYPEREVM_TESTNET_RPC_URL"
        );
        console.log("\n# Transfer tokens");
        console.log(
            "cast send <TOKEN_ADDRESS> \"transfer(address,uint256)(bool)\" <RECIPIENT> <AMOUNT> --private-key $PRIVATE_KEY --rpc-url $HYPEREVM_TESTNET_RPC_URL"
        );
    }
}
