// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library Constants {
    // HyperEVM Testnet specific
    string public constant MARKET_ID = "HyperEVM Aave Market";
    uint256 public constant CHAIN_ID = 998;

    // Oracle Configuration
    uint256 public constant BASE_CURRENCY_UNIT = 100000000; // 8 decimals for USD
    address public constant BASE_CURRENCY = address(0); // ETH as base

    // Interest Rate Strategy Defaults (in ray units: 1e27)
    uint256 public constant OPTIMAL_USAGE_RATIO = 800000000000000000000000000; // 80%
    uint256 public constant BASE_VARIABLE_BORROW_RATE = 0; // 0%
    uint256 public constant VARIABLE_RATE_SLOPE1 = 40000000000000000000000000; // 4%
    uint256 public constant VARIABLE_RATE_SLOPE2 = 600000000000000000000000000; // 60%
    uint256 public constant STABLE_RATE_SLOPE1 = 20000000000000000000000000; // 2%
    uint256 public constant STABLE_RATE_SLOPE2 = 600000000000000000000000000; // 60%
    uint256 public constant BASE_STABLE_BORROW_RATE = 20000000000000000000000000; // 2%
    uint256 public constant STABLE_RATE_EXCESS_OFFSET = 200000000000000000000000000; // 20%
    uint256 public constant OPTIMAL_STABLE_TO_TOTAL_DEBT_RATIO = 200000000000000000000000000; // 20%

    // Default Reserve Configuration (in basis points: 10000 = 100%)
    uint256 public constant DEFAULT_LTV = 8000; // 80%
    uint256 public constant DEFAULT_LIQUIDATION_THRESHOLD = 8500; // 85%
    uint256 public constant DEFAULT_LIQUIDATION_BONUS = 10500; // 105% (5% bonus)
    uint256 public constant DEFAULT_RESERVE_FACTOR = 1000; // 10%

    // Risk Parameters for different asset types

    // Stablecoin parameters
    uint256 public constant STABLECOIN_LTV = 8000; // 80%
    uint256 public constant STABLECOIN_LIQUIDATION_THRESHOLD = 8500; // 85%
    uint256 public constant STABLECOIN_LIQUIDATION_BONUS = 10500; // 105%
    uint256 public constant STABLECOIN_RESERVE_FACTOR = 1000; // 10%

    // ETH/Major crypto parameters
    uint256 public constant ETH_LTV = 8000; // 80%
    uint256 public constant ETH_LIQUIDATION_THRESHOLD = 8250; // 82.5%
    uint256 public constant ETH_LIQUIDATION_BONUS = 10500; // 105%
    uint256 public constant ETH_RESERVE_FACTOR = 1500; // 15%

    // Volatile asset parameters
    uint256 public constant VOLATILE_LTV = 7000; // 70%
    uint256 public constant VOLATILE_LIQUIDATION_THRESHOLD = 7500; // 75%
    uint256 public constant VOLATILE_LIQUIDATION_BONUS = 11000; // 110%
    uint256 public constant VOLATILE_RESERVE_FACTOR = 2000; // 20%

    // Default caps (0 = no cap)
    uint256 public constant DEFAULT_BORROW_CAP = 0;
    uint256 public constant DEFAULT_SUPPLY_CAP = 0;

    // Role identifiers
    bytes32 public constant POOL_ADMIN_ROLE = keccak256("POOL_ADMIN");
    bytes32 public constant EMERGENCY_ADMIN_ROLE = keccak256("EMERGENCY_ADMIN");
    bytes32 public constant RISK_ADMIN_ROLE = keccak256("RISK_ADMIN");
    bytes32 public constant ASSET_LISTING_ADMIN_ROLE = keccak256("ASSET_LISTING_ADMIN");
}
