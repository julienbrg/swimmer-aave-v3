#!/bin/bash

# Foundry Contract Verification Script for HyperEVM Testnet (Purrsec)
# Usage: ./verify_contracts.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CHAIN_ID=998
OPTIMIZER_RUNS=200
VERIFIER_URL="https://sourcify.parsec.finance/verify"
VERIFIER="sourcify"

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  FOUNDRY CONTRACT VERIFICATION${NC}"
echo -e "${BLUE}  HyperEVM Testnet via Purrsec${NC}"
echo -e "${BLUE}======================================${NC}"

# Load environment
if [ -f .env ]; then
    source .env
    echo -e "${GREEN}✅ Environment loaded${NC}"
else
    echo -e "${RED}❌ .env file not found${NC}"
    exit 1
fi

# Function to verify contract with skip logic
verify_contract() {
    local name=$1
    local address=$2
    local contract_path=$3
    local constructor_args=$4
    
    echo -e "\n${YELLOW}🔍 Verifying $name...${NC}"
    echo "Address: $address"
    echo "Contract: $contract_path"
    
    # Build the forge verify-contract command
    local cmd="forge verify-contract"
    cmd="$cmd --chain-id $CHAIN_ID"
    cmd="$cmd --num-of-optimizations $OPTIMIZER_RUNS"
    cmd="$cmd --watch"
    cmd="$cmd --verifier $VERIFIER"
    cmd="$cmd --verifier-url $VERIFIER_URL"
    
    # Add constructor args if provided
    if [ -n "$constructor_args" ]; then
        cmd="$cmd --constructor-args $constructor_args"
    fi
    
    cmd="$cmd $address $contract_path"
    
    echo "Command: $cmd"
    
    # Execute verification and capture output
    local output
    if output=$(eval $cmd 2>&1); then
        echo -e "${GREEN}✅ $name verified successfully${NC}"
    else
        # Check for already verified (409 Conflict) or server errors (500)
        if echo "$output" | grep -q "409\|already verified\|conflict"; then
            echo -e "${BLUE}⚠️ $name already verified - skipping${NC}"
        elif echo "$output" | grep -q "500\|Internal Server Error\|RPC error"; then
            echo -e "${YELLOW}⚠️ $name server error - skipping${NC}"
        else
            echo -e "${RED}❌ $name verification failed${NC}"
            echo -e "${YELLOW}Output: $output${NC}"
        fi
    fi
}

# Helper function to get contract address from broadcast files
get_contract_address() {
    local script_name=$1
    local transaction_index=${2:-0}
    local broadcast_file="./broadcast/${script_name}/${CHAIN_ID}/run-latest.json"
    
    if [ -f "$broadcast_file" ]; then
        jq -r ".transactions[${transaction_index}].contractAddress // empty" "$broadcast_file" 2>/dev/null
    else
        echo ""
    fi
}

# Helper function to get deployer address from environment
get_deployer_address() {
    cast wallet address --private-key "$PRIVATE_KEY" 2>/dev/null || echo ""
}

echo -e "\n${BLUE}Starting contract verification...${NC}"
echo -e "${BLUE}Loading addresses from broadcast files...${NC}"

# Get deployer address
DEPLOYER_ADDRESS=$(get_deployer_address)
if [ -z "$DEPLOYER_ADDRESS" ]; then
    echo -e "${RED}❌ Could not derive deployer address from PRIVATE_KEY${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Deployer address: $DEPLOYER_ADDRESS${NC}"

# 1. PoolAddressesProvider
echo -e "\n${BLUE}=== STEP 1: PoolAddressesProvider ===${NC}"
POOL_ADDRESSES_PROVIDER=$(get_contract_address "01_DeployCoreContracts.s.sol" 0)
if [ -z "$POOL_ADDRESSES_PROVIDER" ]; then
    echo -e "${RED}❌ PoolAddressesProvider address not found in broadcast files${NC}"
    exit 1
fi
echo -e "${GREEN}✅ Found PoolAddressesProvider: $POOL_ADDRESSES_PROVIDER${NC}"

CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(string,address)" "HyperEVM Aave Market" "$DEPLOYER_ADDRESS")
verify_contract \
    "PoolAddressesProvider" \
    "$POOL_ADDRESSES_PROVIDER" \
    "src/protocol/configuration/PoolAddressesProvider.sol:PoolAddressesProvider" \
    "$CONSTRUCTOR_ARGS"

# 2. PoolAddressesProviderRegistry
echo -e "\n${BLUE}=== STEP 2: PoolAddressesProviderRegistry ===${NC}"
REGISTRY_ADDRESS=$(get_contract_address "02_DeployRegistry.s.sol" 0)
if [ -z "$REGISTRY_ADDRESS" ]; then
    echo -e "${YELLOW}⚠️ Registry address not found in broadcast files - skipping${NC}"
else
    echo -e "${GREEN}✅ Found Registry: $REGISTRY_ADDRESS${NC}"
    verify_contract \
        "PoolAddressesProviderRegistry" \
        "$REGISTRY_ADDRESS" \
        "src/protocol/configuration/PoolAddressesProviderRegistry.sol:PoolAddressesProviderRegistry" \
        ""
fi

# 3. ACLManager
echo -e "\n${BLUE}=== STEP 3: ACLManager ===${NC}"
ACL_ADDRESS=$(get_contract_address "03_DeployACL.s.sol" 0)
if [ -z "$ACL_ADDRESS" ]; then
    echo -e "${YELLOW}⚠️ ACLManager address not found in broadcast files - skipping${NC}"
else
    echo -e "${GREEN}✅ Found ACLManager: $ACL_ADDRESS${NC}"
    ACL_CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(address)" "$POOL_ADDRESSES_PROVIDER")
    verify_contract \
        "ACLManager" \
        "$ACL_ADDRESS" \
        "src/protocol/configuration/ACLManager.sol:ACLManager" \
        "$ACL_CONSTRUCTOR_ARGS"
fi

# 4. Pool Implementation
echo -e "\n${BLUE}=== STEP 4: Pool Implementation ===${NC}"
POOL_IMPL_ADDRESS=$(get_contract_address "04_DeployPool.s.sol" 0)
if [ -z "$POOL_IMPL_ADDRESS" ]; then
    echo -e "${YELLOW}⚠️ Pool Implementation address not found in broadcast files - skipping${NC}"
else
    echo -e "${GREEN}✅ Found Pool Implementation: $POOL_IMPL_ADDRESS${NC}"
    POOL_CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(address)" "$POOL_ADDRESSES_PROVIDER")
    verify_contract \
        "Pool" \
        "$POOL_IMPL_ADDRESS" \
        "src/protocol/pool/Pool.sol:Pool" \
        "$POOL_CONSTRUCTOR_ARGS"
fi

# 5. PoolConfigurator Implementation  
echo -e "\n${BLUE}=== STEP 5: PoolConfigurator Implementation ===${NC}"
POOL_CONFIGURATOR_IMPL_ADDRESS=$(get_contract_address "04_DeployPool.s.sol" 1)
if [ -z "$POOL_CONFIGURATOR_IMPL_ADDRESS" ]; then
    echo -e "${YELLOW}⚠️ PoolConfigurator Implementation address not found in broadcast files - skipping${NC}"
else
    echo -e "${GREEN}✅ Found PoolConfigurator Implementation: $POOL_CONFIGURATOR_IMPL_ADDRESS${NC}"
    verify_contract \
        "PoolConfigurator" \
        "$POOL_CONFIGURATOR_IMPL_ADDRESS" \
        "src/protocol/pool/PoolConfigurator.sol:PoolConfigurator" \
        ""
fi

# 6. AaveOracle
echo -e "\n${BLUE}=== STEP 6: AaveOracle ===${NC}"
ORACLE_ADDRESS=$(get_contract_address "05_DeployOracle.s.sol" 0)
if [ -z "$ORACLE_ADDRESS" ]; then
    echo -e "${YELLOW}⚠️ AaveOracle address not found in broadcast files - skipping${NC}"
else
    echo -e "${GREEN}✅ Found AaveOracle: $ORACLE_ADDRESS${NC}"
    ORACLE_CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(address,address[],address[],address,address,uint256)" "$POOL_ADDRESSES_PROVIDER" "[]" "[]" "0x0000000000000000000000000000000000000000" "0x0000000000000000000000000000000000000000" "100000000")
    verify_contract \
        "AaveOracle" \
        "$ORACLE_ADDRESS" \
        "src/misc/AaveOracle.sol:AaveOracle" \
        "$ORACLE_CONSTRUCTOR_ARGS"
fi

# 7. AaveProtocolDataProvider
echo -e "\n${BLUE}=== STEP 7: AaveProtocolDataProvider ===${NC}"
DATA_PROVIDER_ADDRESS=$(get_contract_address "05_DeployOracle.s.sol" 1)
if [ -z "$DATA_PROVIDER_ADDRESS" ]; then
    echo -e "${YELLOW}⚠️ AaveProtocolDataProvider address not found in broadcast files - skipping${NC}"
else
    echo -e "${GREEN}✅ Found AaveProtocolDataProvider: $DATA_PROVIDER_ADDRESS${NC}"
    DATA_PROVIDER_ARGS=$(cast abi-encode "constructor(address)" "$POOL_ADDRESSES_PROVIDER")
    verify_contract \
        "AaveProtocolDataProvider" \
        "$DATA_PROVIDER_ADDRESS" \
        "src/misc/AaveProtocolDataProvider.sol:AaveProtocolDataProvider" \
        "$DATA_PROVIDER_ARGS"
fi

# 8. Token Implementations
echo -e "\n${BLUE}=== STEP 8: Token Implementations ===${NC}"

# Get Pool proxy address for token constructor args
POOL_PROXY_ADDRESS=$(get_contract_address "04_DeployPool.s.sol" 2)
if [ -z "$POOL_PROXY_ADDRESS" ]; then
    echo -e "${YELLOW}⚠️ Pool proxy address not found - using fallback${NC}"
    POOL_PROXY_ADDRESS="0xd029e2017a76dCA2D2DD354A2A92FBce7e5D2074"
else
    echo -e "${GREEN}✅ Found Pool proxy: $POOL_PROXY_ADDRESS${NC}"
fi

# AToken Implementation
ATOKEN_ADDRESS=$(get_contract_address "07_DeployTokenImplementations.s.sol" 0)
if [ -z "$ATOKEN_ADDRESS" ]; then
    echo -e "${YELLOW}⚠️ AToken Implementation address not found - skipping${NC}"
else
    echo -e "${GREEN}✅ Found AToken Implementation: $ATOKEN_ADDRESS${NC}"
    ATOKEN_ARGS=$(cast abi-encode "constructor(address)" "$POOL_PROXY_ADDRESS")
    verify_contract \
        "AToken" \
        "$ATOKEN_ADDRESS" \
        "src/protocol/tokenization/AToken.sol:AToken" \
        "$ATOKEN_ARGS"
fi

# StableDebtToken Implementation
STABLE_DEBT_ADDRESS=$(get_contract_address "07_DeployTokenImplementations.s.sol" 1)
if [ -z "$STABLE_DEBT_ADDRESS" ]; then
    echo -e "${YELLOW}⚠️ StableDebtToken Implementation address not found - skipping${NC}"
else
    echo -e "${GREEN}✅ Found StableDebtToken Implementation: $STABLE_DEBT_ADDRESS${NC}"
    STABLE_DEBT_ARGS=$(cast abi-encode "constructor(address)" "$POOL_PROXY_ADDRESS")
    verify_contract \
        "StableDebtToken" \
        "$STABLE_DEBT_ADDRESS" \
        "src/protocol/tokenization/StableDebtToken.sol:StableDebtToken" \
        "$STABLE_DEBT_ARGS"
fi

# VariableDebtToken Implementation  
VARIABLE_DEBT_ADDRESS=$(get_contract_address "07_DeployTokenImplementations.s.sol" 2)
if [ -z "$VARIABLE_DEBT_ADDRESS" ]; then
    echo -e "${YELLOW}⚠️ VariableDebtToken Implementation address not found - skipping${NC}"
else
    echo -e "${GREEN}✅ Found VariableDebtToken Implementation: $VARIABLE_DEBT_ADDRESS${NC}"
    VARIABLE_DEBT_ARGS=$(cast abi-encode "constructor(address)" "$POOL_PROXY_ADDRESS")
    verify_contract \
        "VariableDebtToken" \
        "$VARIABLE_DEBT_ADDRESS" \
        "src/protocol/tokenization/VariableDebtToken.sol:VariableDebtToken" \
        "$VARIABLE_DEBT_ARGS"
fi

# 9. Interest Rate Strategies
echo -e "\n${BLUE}=== STEP 9: Interest Rate Strategies ===${NC}"

# Default Strategy (80% optimal usage)
DEFAULT_STRATEGY_ADDRESS=$(get_contract_address "08_DeployInterestRateStrategy.s.sol" 0)
if [ -z "$DEFAULT_STRATEGY_ADDRESS" ]; then
    echo -e "${YELLOW}⚠️ Default Interest Rate Strategy address not found - skipping${NC}"
else
    echo -e "${GREEN}✅ Found Default Strategy: $DEFAULT_STRATEGY_ADDRESS${NC}"
    DEFAULT_STRATEGY_ARGS=$(cast abi-encode "constructor(address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)" "$POOL_ADDRESSES_PROVIDER" "800000000000000000000000000" "0" "40000000000000000000000000" "600000000000000000000000000" "20000000000000000000000000" "600000000000000000000000000" "20000000000000000000000000" "200000000000000000000000000" "200000000000000000000000000")
    verify_contract \
        "DefaultReserveInterestRateStrategy" \
        "$DEFAULT_STRATEGY_ADDRESS" \
        "src/protocol/pool/DefaultReserveInterestRateStrategy.sol:DefaultReserveInterestRateStrategy" \
        "$DEFAULT_STRATEGY_ARGS"
fi

# Stablecoin Strategy (90% optimal usage)
STABLECOIN_STRATEGY_ADDRESS=$(get_contract_address "08_DeployInterestRateStrategy.s.sol" 1)
if [ -z "$STABLECOIN_STRATEGY_ADDRESS" ]; then
    echo -e "${YELLOW}⚠️ Stablecoin Interest Rate Strategy address not found - skipping${NC}"
else
    echo -e "${GREEN}✅ Found Stablecoin Strategy: $STABLECOIN_STRATEGY_ADDRESS${NC}"
    STABLECOIN_STRATEGY_ARGS=$(cast abi-encode "constructor(address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)" "$POOL_ADDRESSES_PROVIDER" "900000000000000000000000000" "0" "25000000000000000000000000" "600000000000000000000000000" "10000000000000000000000000" "600000000000000000000000000" "10000000000000000000000000" "100000000000000000000000000" "200000000000000000000000000")
    verify_contract \
        "StablecoinInterestRateStrategy" \
        "$STABLECOIN_STRATEGY_ADDRESS" \
        "src/protocol/pool/DefaultReserveInterestRateStrategy.sol:DefaultReserveInterestRateStrategy" \
        "$STABLECOIN_STRATEGY_ARGS"
fi

# Volatile Asset Strategy (70% optimal usage)
VOLATILE_STRATEGY_ADDRESS=$(get_contract_address "08_DeployInterestRateStrategy.s.sol" 2)
if [ -z "$VOLATILE_STRATEGY_ADDRESS" ]; then
    echo -e "${YELLOW}⚠️ Volatile Asset Interest Rate Strategy address not found - skipping${NC}"
else
    echo -e "${GREEN}✅ Found Volatile Strategy: $VOLATILE_STRATEGY_ADDRESS${NC}"
    VOLATILE_STRATEGY_ARGS=$(cast abi-encode "constructor(address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)" "$POOL_ADDRESSES_PROVIDER" "700000000000000000000000000" "10000000000000000000000000" "60000000000000000000000000" "800000000000000000000000000" "20000000000000000000000000" "600000000000000000000000000" "20000000000000000000000000" "200000000000000000000000000" "200000000000000000000000000")
    verify_contract \
        "VolatileAssetInterestRateStrategy" \
        "$VOLATILE_STRATEGY_ADDRESS" \
        "src/protocol/pool/DefaultReserveInterestRateStrategy.sol:DefaultReserveInterestRateStrategy" \
        "$VOLATILE_STRATEGY_ARGS"
fi

# 10. Mock Tokens
echo -e "\n${BLUE}=== STEP 10: Mock Tokens ===${NC}"

# Mock tokens are deployed in pairs (CREATE + CALL), so we need to get every other transaction
MOCK_TOKENS=(
    "USDC:Mock USD Coin:6:0"
    "USDT:Mock Tether USD:6:2"
    "DAI:Mock Dai Stablecoin:18:4"
    "WBTC:Mock Wrapped Bitcoin:8:6"
    "LINK:Mock Chainlink:18:8"
    "UNI:Mock Uniswap:18:10"
)

for token_info in "${MOCK_TOKENS[@]}"; do
    IFS=':' read -r symbol name decimals tx_index <<< "$token_info"
    
    TOKEN_ADDRESS=$(get_contract_address "09_DeployMockTokens.s.sol" "$tx_index")
    if [ -z "$TOKEN_ADDRESS" ]; then
        echo -e "${YELLOW}⚠️ $symbol token address not found - skipping${NC}"
    else
        echo -e "${GREEN}✅ Found $symbol token: $TOKEN_ADDRESS${NC}"
        verify_contract \
            "MintableERC20_$symbol" \
            "$TOKEN_ADDRESS" \
            "src/mocks/tokens/MintableERC20.sol:MintableERC20" \
            "$(cast abi-encode 'constructor(string,string,uint8)' '$name' '$symbol' $decimals)"
    fi
done

echo -e "\n${GREEN}🎉 Contract verification process completed!${NC}"
echo -e "${BLUE}======================================${NC}"
echo -e "${YELLOW}📋 VERIFICATION SUMMARY:${NC}"
echo -e "• PoolAddressesProvider: ${POOL_ADDRESSES_PROVIDER:-Not Found}"
echo -e "• Registry: ${REGISTRY_ADDRESS:-Not Found}"
echo -e "• ACLManager: ${ACL_ADDRESS:-Not Found}"
echo -e "• Pool Implementation: ${POOL_IMPL_ADDRESS:-Not Found}"
echo -e "• PoolConfigurator Implementation: ${POOL_CONFIGURATOR_IMPL_ADDRESS:-Not Found}"
echo -e "• AaveOracle: ${ORACLE_ADDRESS:-Not Found}"
echo -e "• AaveProtocolDataProvider: ${DATA_PROVIDER_ADDRESS:-Not Found}"
echo -e "${BLUE}======================================${NC}"
echo -e "${YELLOW}💡 If any verification failed, check Purrsec manually:${NC}"
echo -e "https://testnet.purrsec.com/"