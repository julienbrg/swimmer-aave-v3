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

echo -e "\n${BLUE}Starting contract verification...${NC}"

# 1. PoolAddressesProvider
echo -e "\n${BLUE}=== STEP 1: PoolAddressesProvider ===${NC}"
CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(string,address)" "HyperEVM Aave Market" "0x9a6586c563D56899d2d84a6b22729870126f62Fb")
verify_contract \
    "PoolAddressesProvider" \
    "0x97b1E699Fe1E9Ae1e43f2b9845b9233373a4b3dC" \
    "src/protocol/configuration/PoolAddressesProvider.sol:PoolAddressesProvider" \
    "$CONSTRUCTOR_ARGS"

# 2. PoolAddressesProviderRegistry
echo -e "\n${BLUE}=== STEP 2: PoolAddressesProviderRegistry ===${NC}"
verify_contract \
    "PoolAddressesProviderRegistry" \
    "0x476270053811a993E5D33a31aC97fbA912BD7559" \
    "src/protocol/configuration/PoolAddressesProviderRegistry.sol:PoolAddressesProviderRegistry" \
    ""

# 3. ACLManager
echo -e "\n${BLUE}=== STEP 3: ACLManager ===${NC}"
ACL_CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(address)" "0x97b1E699Fe1E9Ae1e43f2b9845b9233373a4b3dC")
verify_contract \
    "ACLManager" \
    "0xd85120Dd1f1eD7957930363F5E668ef6Edfc4905" \
    "src/protocol/configuration/ACLManager.sol:ACLManager" \
    "$ACL_CONSTRUCTOR_ARGS"

# 4. Pool Implementation
echo -e "\n${BLUE}=== STEP 4: Pool Implementation ===${NC}"
POOL_CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(address)" "0x97b1E699Fe1E9Ae1e43f2b9845b9233373a4b3dC")
verify_contract \
    "Pool" \
    "0xe1D5159242038e193015a49890f324a38A75AF04" \
    "src/protocol/pool/Pool.sol:Pool" \
    "$POOL_CONSTRUCTOR_ARGS"

# 5. PoolConfigurator Implementation  
echo -e "\n${BLUE}=== STEP 5: PoolConfigurator Implementation ===${NC}"
verify_contract \
    "PoolConfigurator" \
    "0x5Af8c85E111D4A17C5B568Dd20a33b740070f0E2" \
    "src/protocol/pool/PoolConfigurator.sol:PoolConfigurator" \
    ""

# 6. AaveOracle
echo -e "\n${BLUE}=== STEP 6: AaveOracle ===${NC}"
ORACLE_CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(address,address[],address[],address,address,uint256)" "0x97b1E699Fe1E9Ae1e43f2b9845b9233373a4b3dC" "[]" "[]" "0x0000000000000000000000000000000000000000" "0x0000000000000000000000000000000000000000" "0")
verify_contract \
    "AaveOracle" \
    "0x4A3F56F843EE5C3812fd2751C49aDEf95e544DD2" \
    "src/misc/AaveOracle.sol:AaveOracle" \
    "$ORACLE_CONSTRUCTOR_ARGS"

# 7. AaveProtocolDataProvider
echo -e "\n${BLUE}=== STEP 7: AaveProtocolDataProvider ===${NC}"
DATA_PROVIDER_ARGS=$(cast abi-encode "constructor(address)" "0x97b1E699Fe1E9Ae1e43f2b9845b9233373a4b3dC")
verify_contract \
    "AaveProtocolDataProvider" \
    "0x8A5EBDf0031ED72Eb381e4607894aea7038e94D3" \
    "src/misc/AaveProtocolDataProvider.sol:AaveProtocolDataProvider" \
    "$DATA_PROVIDER_ARGS"

# 8. Token Implementations
echo -e "\n${BLUE}=== STEP 8: Token Implementations ===${NC}"

# AToken Implementation
ATOKEN_ARGS=$(cast abi-encode "constructor(address)" "0xd029e2017a76dCA2D2DD354A2A92FBce7e5D2074")
verify_contract \
    "AToken" \
    "0x0dbcd5B405B1128bF06E75F937f600ea53D76076" \
    "src/protocol/tokenization/AToken.sol:AToken" \
    "$ATOKEN_ARGS"

# StableDebtToken Implementation
STABLE_DEBT_ARGS=$(cast abi-encode "constructor(address)" "0xd029e2017a76dCA2D2DD354A2A92FBce7e5D2074")
verify_contract \
    "StableDebtToken" \
    "0x84B14AA9b21FA45deD2A5C83990e8769D4df5073" \
    "src/protocol/tokenization/StableDebtToken.sol:StableDebtToken" \
    "$STABLE_DEBT_ARGS"

# VariableDebtToken Implementation  
VARIABLE_DEBT_ARGS=$(cast abi-encode "constructor(address)" "0xd029e2017a76dCA2D2DD354A2A92FBce7e5D2074")
verify_contract \
    "VariableDebtToken" \
    "0xf2c8b78278B48A9c91b39C86D3990228cEaC5aC0" \
    "src/protocol/tokenization/VariableDebtToken.sol:VariableDebtToken" \
    "$VARIABLE_DEBT_ARGS"

# 9. Interest Rate Strategies
echo -e "\n${BLUE}=== STEP 9: Interest Rate Strategies ===${NC}"

# Default Strategy (80% optimal usage)
DEFAULT_STRATEGY_ARGS=$(cast abi-encode "constructor(address,uint256,uint256,uint256,uint256,uint256,uint256)" "0x97b1E699Fe1E9Ae1e43f2b9845b9233373a4b3dC" "800000000000000000000000000" "0" "40000000000000000000000000" "600000000000000000000000000" "0" "0")
verify_contract \
    "DefaultReserveInterestRateStrategy" \
    "0x60471ABd262E2388e90FbE1f676ed0C762C39a09" \
    "src/protocol/pool/DefaultReserveInterestRateStrategy.sol:DefaultReserveInterestRateStrategy" \
    "$DEFAULT_STRATEGY_ARGS"

# Stablecoin Strategy (90% optimal usage)
STABLECOIN_STRATEGY_ARGS=$(cast abi-encode "constructor(address,uint256,uint256,uint256,uint256,uint256,uint256)" "0x97b1E699Fe1E9Ae1e43f2b9845b9233373a4b3dC" "900000000000000000000000000" "0" "20000000000000000000000000" "600000000000000000000000000" "0" "0")
verify_contract \
    "StablecoinInterestRateStrategy" \
    "0xa89cc87b458c0C89c8842E44441093d330EfF40F" \
    "src/protocol/pool/DefaultReserveInterestRateStrategy.sol:DefaultReserveInterestRateStrategy" \
    "$STABLECOIN_STRATEGY_ARGS"

# Volatile Asset Strategy (70% optimal usage)
VOLATILE_STRATEGY_ARGS=$(cast abi-encode "constructor(address,uint256,uint256,uint256,uint256,uint256,uint256)" "0x97b1E699Fe1E9Ae1e43f2b9845b9233373a4b3dC" "700000000000000000000000000" "10000000000000000000000000" "60000000000000000000000000" "800000000000000000000000000" "0" "0")
verify_contract \
    "VolatileAssetInterestRateStrategy" \
    "0xD4d76e84E1B0EA4eba09bEE40D06C6cfB89B7cBE" \
    "src/protocol/pool/DefaultReserveInterestRateStrategy.sol:DefaultReserveInterestRateStrategy" \
    "$VOLATILE_STRATEGY_ARGS"

# 10. Mock Tokens
echo -e "\n${BLUE}=== STEP 10: Mock Tokens ===${NC}"

verify_contract \
    "MintableERC20_USDC" \
    "0x83C0F8D4e46E5B81461aC0133B635f57745b464E" \
    "src/mocks/tokens/MintableERC20.sol:MintableERC20" \
    "$(cast abi-encode 'constructor(string,string,uint8)' 'Mock USD Coin' 'USDC' 6)"

verify_contract \
    "MintableERC20_USDT" \
    "0xEc048DA076f171BcCac90F1CE888FcabC10c6c4b" \
    "src/mocks/tokens/MintableERC20.sol:MintableERC20" \
    "$(cast abi-encode 'constructor(string,string,uint8)' 'Mock Tether USD' 'USDT' 6)"

verify_contract \
    "MintableERC20_DAI" \
    "0x610a2f01C74357dcf2117CdFBB07736FEb145167" \
    "src/mocks/tokens/MintableERC20.sol:MintableERC20" \
    "$(cast abi-encode 'constructor(string,string,uint8)' 'Mock Dai Stablecoin' 'DAI' 18)"

verify_contract \
    "MintableERC20_WBTC" \
    "0x63944467f67da637a703A7F3C13F748F3C10958A" \
    "src/mocks/tokens/MintableERC20.sol:MintableERC20" \
    "$(cast abi-encode 'constructor(string,string,uint8)' 'Mock Wrapped Bitcoin' 'WBTC' 8)"

verify_contract \
    "MintableERC20_LINK" \
    "0xB191D82173471ec22098e35CC19C5621861555Cf" \
    "src/mocks/tokens/MintableERC20.sol:MintableERC20" \
    "$(cast abi-encode 'constructor(string,string,uint8)' 'Mock Chainlink' 'LINK' 18)"

verify_contract \
    "MintableERC20_UNI" \
    "0x7BdBa9B1C27343D105FA39A9c34c340d7549AccB" \
    "src/mocks/tokens/MintableERC20.sol:MintableERC20" \
    "$(cast abi-encode 'constructor(string,string,uint8)' 'Mock Uniswap' 'UNI' 18)"

echo -e "\n${GREEN}🎉 Contract verification process completed!${NC}"
echo -e "${BLUE}======================================${NC}"
echo -e "${YELLOW}📋 VERIFICATION SUMMARY:${NC}"
echo -e "• PoolAddressesProvider: 0x97b1E699Fe1E9Ae1e43f2b9845b9233373a4b3dC"
echo -e "• ACLManager: 0xd85120Dd1f1eD7957930363F5E668ef6Edfc4905"
echo -e "• AaveOracle: 0x4A3F56F843EE5C3812fd2751C49aDEf95e544DD2"
echo -e "• Pool Implementation: 0xe1D5159242038e193015a49890f324a38A75AF04"
echo -e "• PoolConfigurator: 0x5Af8c85E111D4A17C5B568Dd20a33b740070f0E2"
echo -e "${BLUE}======================================${NC}"
echo -e "${YELLOW}💡 If any verification failed, check Purrsec manually:${NC}"
echo -e "https://testnet.purrsec.com/"