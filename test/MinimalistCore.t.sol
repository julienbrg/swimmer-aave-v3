// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {Test} from "forge-std/Test.sol";
import {MintableERC20} from "../src/mocks/tokens/MintableERC20.sol";
import {MockAggregator} from "../src/mocks/oracle/CLAggregators/MockAggregator.sol";
import {DataTypes} from "../src/protocol/libraries/types/DataTypes.sol";

contract MinimalistCoreTest is Test {
    MintableERC20 public token;
    MockAggregator public oracle;

    address public user = makeAddr("user");

    function setUp() public {
        token = new MintableERC20("Test Token", "TEST", 18);
        oracle = new MockAggregator(100000000); // $1.00 with 8 decimals
    }

    function test_TokenBasics() public {
        assertEq(token.name(), "Test Token");
        assertEq(token.symbol(), "TEST");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), 0);
    }

    function test_TokenMinting() public {
        uint256 mintAmount = 1000 ether;
        
        token.mint(user, mintAmount);
        
        assertEq(token.balanceOf(user), mintAmount);
        assertEq(token.totalSupply(), mintAmount);
    }

    function test_TokenTransfer() public {
        uint256 mintAmount = 1000 ether;
        uint256 transferAmount = 300 ether;
        address recipient = makeAddr("recipient");
        
        token.mint(user, mintAmount);
        
        vm.startPrank(user);
        token.transfer(recipient, transferAmount);
        vm.stopPrank();
        
        assertEq(token.balanceOf(user), mintAmount - transferAmount);
        assertEq(token.balanceOf(recipient), transferAmount);
    }

    function test_TokenApprovalAndTransferFrom() public {
        uint256 mintAmount = 1000 ether;
        uint256 transferAmount = 300 ether;
        address spender = makeAddr("spender");
        address recipient = makeAddr("recipient");
        
        token.mint(user, mintAmount);
        
        vm.startPrank(user);
        token.approve(spender, transferAmount);
        vm.stopPrank();
        
        assertEq(token.allowance(user, spender), transferAmount);
        
        vm.startPrank(spender);
        token.transferFrom(user, recipient, transferAmount);
        vm.stopPrank();
        
        assertEq(token.balanceOf(user), mintAmount - transferAmount);
        assertEq(token.balanceOf(recipient), transferAmount);
        assertEq(token.allowance(user, spender), 0);
    }

    function test_OracleBasics() public {
        assertEq(oracle.latestAnswer(), 100000000);
        assertEq(oracle.decimals(), 8);
        assertEq(oracle.getTokenType(), 1);
    }

    function test_DataTypesStructs() public {
        // Test that DataTypes can be used
        DataTypes.ReserveConfigurationMap memory config;
        assertEq(config.data, 0);
        
        DataTypes.UserConfigurationMap memory userConfig;
        assertEq(userConfig.data, 0);
    }

    function testFuzz_TokenOperations(uint256 mintAmount, uint256 transferAmount) public {
        mintAmount = bound(mintAmount, 1, type(uint128).max);
        transferAmount = bound(transferAmount, 1, mintAmount);
        
        address recipient = makeAddr("recipient");
        
        token.mint(user, mintAmount);
        assertEq(token.balanceOf(user), mintAmount);
        
        vm.startPrank(user);
        token.transfer(recipient, transferAmount);
        vm.stopPrank();
        
        assertEq(token.balanceOf(user), mintAmount - transferAmount);
        assertEq(token.balanceOf(recipient), transferAmount);
        assertEq(token.totalSupply(), mintAmount);
    }

    function testFuzz_TokenApproval(uint256 approvalAmount) public {
        approvalAmount = bound(approvalAmount, 0, type(uint256).max);
        address spender = makeAddr("spender");
        
        vm.startPrank(user);
        token.approve(spender, approvalAmount);
        vm.stopPrank();
        
        assertEq(token.allowance(user, spender), approvalAmount);
    }

    function test_RevertOnInsufficientBalance() public {
        uint256 mintAmount = 100 ether;
        uint256 transferAmount = 200 ether; // More than balance
        address recipient = makeAddr("recipient");
        
        token.mint(user, mintAmount);
        
        vm.startPrank(user);
        vm.expectRevert();
        token.transfer(recipient, transferAmount);
        vm.stopPrank();
    }

    function test_RevertOnInsufficientAllowance() public {
        uint256 mintAmount = 1000 ether;
        uint256 approvalAmount = 300 ether;
        uint256 transferAmount = 400 ether; // More than allowance
        address spender = makeAddr("spender");
        address recipient = makeAddr("recipient");
        
        token.mint(user, mintAmount);
        
        vm.startPrank(user);
        token.approve(spender, approvalAmount);
        vm.stopPrank();
        
        vm.startPrank(spender);
        vm.expectRevert();
        token.transferFrom(user, recipient, transferAmount);
        vm.stopPrank();
    }

    function test_Constants() public {
        // Test some basic constants are accessible
        assertTrue(type(uint256).max > 0);
        assertTrue(1 ether == 1e18);
        assertTrue(1 gwei == 1e9);
    }
}