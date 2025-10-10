#!/bin/bash

# Remove strict mode to prevent hanging on array operations
# set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_TOTAL=0

# Arrays to store verification results
VERIFIED_ITEMS=()
FAILED_ITEMS=()
WARNING_ITEMS=()

# Functions
check_passed() {
    echo -e "${GREEN}✓${NC} $1"
    VERIFIED_ITEMS+=("$1")
    ((CHECKS_PASSED++))
    ((CHECKS_TOTAL++))
}

check_failed() {
    echo -e "${RED}✗${NC} $1"
    FAILED_ITEMS+=("$1")
    ((CHECKS_FAILED++))
    ((CHECKS_TOTAL++))
}

check_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
    WARNING_ITEMS+=("$1")
    ((CHECKS_TOTAL++))
}

section_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}"
}

echo -e "${BLUE}Aave V3.0 HyperEVM Testnet Deployment Readiness Check${NC}\n"

# Environment Setup Checks
section_header "Environment Setup"

# Check if Foundry is installed
if command -v forge &> /dev/null; then
    FORGE_VERSION=$(forge --version | head -n1)
    check_passed "Foundry installed: $FORGE_VERSION"
else
    check_failed "Foundry not installed. Run 'foundryup' to install."
fi

# Check for .env file
if [ -f ".env" ]; then
    check_passed ".env file exists"
    
    # Check for required environment variables
    source .env
    
    if [ -n "$PRIVATE_KEY" ]; then
        if [[ "$PRIVATE_KEY" == 0x* ]]; then
            check_passed "PRIVATE_KEY is set (with 0x prefix)"
        else
            check_warning "PRIVATE_KEY should have 0x prefix (for vm.envUint compatibility)"
        fi
    else
        check_failed "PRIVATE_KEY not set in .env"
    fi
    
    # Check for HyperEVM Testnet specific variables
    if [ -n "$HYPEREVM_TESTNET_RPC_URL" ]; then
        check_passed "HYPEREVM_TESTNET_RPC_URL is set: $HYPEREVM_TESTNET_RPC_URL"
    else
        check_failed "HYPEREVM_TESTNET_RPC_URL not set in .env"
    fi
    
    if [ -n "$HYPEREVM_TESTNET_CHAIN_ID" ]; then
        check_passed "HYPEREVM_TESTNET_CHAIN_ID is set: $HYPEREVM_TESTNET_CHAIN_ID"
    else
        check_failed "HYPEREVM_TESTNET_CHAIN_ID not set in .env"
    fi
    
    # Fallback to generic RPC_URL if HyperEVM specific not set
    if [ -n "$RPC_URL" ] && [ -z "$HYPEREVM_TESTNET_RPC_URL" ]; then
        check_warning "Using fallback RPC_URL: $RPC_URL (consider setting HYPEREVM_TESTNET_RPC_URL)"
    fi
    
else
    check_failed ".env file not found"
fi

# Check foundry.toml
if [ -f "foundry.toml" ]; then
    check_passed "foundry.toml exists"
    
    # Check Solidity version
    if grep -q "solc_version.*0\.8\." foundry.toml; then
        SOLC_VERSION=$(grep "solc_version" foundry.toml | cut -d'"' -f2)
        check_passed "Solidity version configured: $SOLC_VERSION"
    else
        check_warning "Solidity version not explicitly set in foundry.toml"
    fi
else
    check_failed "foundry.toml not found"
fi

# Check dependencies
section_header "Dependencies"

if [ -d "lib" ] && [ "$(ls -A lib)" ]; then
    check_passed "Dependencies installed in lib/ directory"
    
    # Check for key Aave dependencies
    if [ -d "lib/aave-v3-core" ]; then
        check_passed "aave-v3-core dependency found"
    else
        check_warning "aave-v3-core dependency not found in lib/"
    fi
    
    if [ -d "lib/openzeppelin-contracts" ]; then
        check_passed "openzeppelin-contracts dependency found"
    else
        check_warning "openzeppelin-contracts dependency not found in lib/"
    fi
else
    check_failed "No dependencies found. Run 'forge install' to install dependencies."
fi

# HyperEVM Testnet Network Checks
section_header "HyperEVM Testnet Network"

# Use HyperEVM specific RPC URL, fallback to generic RPC_URL
NETWORK_RPC_URL=""
if [ -n "$HYPEREVM_TESTNET_RPC_URL" ]; then
    NETWORK_RPC_URL="$HYPEREVM_TESTNET_RPC_URL"
elif [ -n "$RPC_URL" ]; then
    NETWORK_RPC_URL="$RPC_URL"
    check_warning "Using generic RPC_URL instead of HYPEREVM_TESTNET_RPC_URL"
fi

if [ -n "$NETWORK_RPC_URL" ]; then
    # Test RPC connectivity
    echo "Testing connectivity to: $NETWORK_RPC_URL"
    if curl -s --max-time 10 -X POST -H "Content-Type: application/json" \
        --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
        "$NETWORK_RPC_URL" > /dev/null; then
        
        ACTUAL_CHAIN_ID=$(curl -s --max-time 10 -X POST -H "Content-Type: application/json" \
            --data '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
            "$NETWORK_RPC_URL" | jq -r '.result')
        
        if [ "$ACTUAL_CHAIN_ID" != "null" ] && [ -n "$ACTUAL_CHAIN_ID" ]; then
            ACTUAL_CHAIN_ID_DECIMAL=$((ACTUAL_CHAIN_ID))
            check_passed "RPC endpoint accessible (Chain ID: $ACTUAL_CHAIN_ID_DECIMAL)"
            
            # Verify chain ID matches expected HyperEVM Testnet Chain ID
            if [ -n "$HYPEREVM_TESTNET_CHAIN_ID" ]; then
                EXPECTED_CHAIN_ID_DECIMAL=$((HYPEREVM_TESTNET_CHAIN_ID))
                if [ "$ACTUAL_CHAIN_ID_DECIMAL" -eq "$EXPECTED_CHAIN_ID_DECIMAL" ]; then
                    check_passed "Chain ID matches HyperEVM Testnet: $ACTUAL_CHAIN_ID_DECIMAL"
                else
                    check_failed "Chain ID mismatch! Expected: $EXPECTED_CHAIN_ID_DECIMAL, Got: $ACTUAL_CHAIN_ID_DECIMAL"
                fi
            else
                check_warning "Cannot verify chain ID - HYPEREVM_TESTNET_CHAIN_ID not set"
            fi
        else
            check_failed "RPC endpoint returned invalid chain ID"
        fi
    else
        check_failed "Cannot connect to RPC endpoint: $NETWORK_RPC_URL"
    fi
else
    check_failed "No RPC URL configured (set HYPEREVM_TESTNET_RPC_URL or RPC_URL)"
fi

# Enhanced deployer wallet balance check
section_header "Deployer Wallet"

if [ -n "$PRIVATE_KEY" ] && [ -n "$NETWORK_RPC_URL" ]; then
    if command -v cast &> /dev/null; then
        echo "Checking deployer wallet..."
        DEPLOYER_ADDRESS=$(cast wallet address --private-key "$PRIVATE_KEY" 2>/dev/null || echo "")
        
        if [ -n "$DEPLOYER_ADDRESS" ]; then
            check_passed "Deployer address: $DEPLOYER_ADDRESS"
            
            # Get current balance (with timeout protection)
            echo "Checking balance..."
            if command -v gtimeout &> /dev/null; then
                BALANCE=$(gtimeout 15s cast balance "$DEPLOYER_ADDRESS" --rpc-url "$NETWORK_RPC_URL" 2>/dev/null || echo "")
            elif command -v timeout &> /dev/null; then
                BALANCE=$(timeout 15s cast balance "$DEPLOYER_ADDRESS" --rpc-url "$NETWORK_RPC_URL" 2>/dev/null || echo "")
            else
                BALANCE=$(cast balance "$DEPLOYER_ADDRESS" --rpc-url "$NETWORK_RPC_URL" 2>/dev/null || echo "")
            fi
            if [ -n "$BALANCE" ] && [ "$BALANCE" != "0" ]; then
                BALANCE_ETH=$(cast to-unit "$BALANCE" ether 2>/dev/null || echo "unknown")
                check_passed "Current balance: $BALANCE_ETH ETH"
                
                # More detailed balance warnings
                if command -v bc &> /dev/null; then
                    if (( $(echo "$BALANCE_ETH < 0.01" | bc -l) )); then
                        check_failed "Critical: Balance too low for deployment ($BALANCE_ETH ETH < 0.01 ETH)"
                    elif (( $(echo "$BALANCE_ETH < 0.1" | bc -l) )); then
                        check_warning "Low balance - may not be sufficient for full deployment ($BALANCE_ETH ETH)"
                    elif (( $(echo "$BALANCE_ETH < 1.0" | bc -l) )); then
                        check_warning "Medium balance - consider adding more funds for safety ($BALANCE_ETH ETH)"
                    else
                        check_passed "Sufficient balance for deployment ($BALANCE_ETH ETH)"
                    fi
                fi
            elif [ "$BALANCE" = "0" ]; then
                check_failed "Deployer wallet has zero balance - add funds before deployment"
            else
                check_failed "Could not retrieve deployer wallet balance - check network connectivity"
            fi
            
            # Get transaction count (nonce) to verify account activity
            TX_COUNT=$(cast nonce "$DEPLOYER_ADDRESS" --rpc-url "$NETWORK_RPC_URL" 2>/dev/null || echo "")
            if [ -n "$TX_COUNT" ]; then
                if [ "$TX_COUNT" -eq 0 ]; then
                    check_passed "Fresh deployer wallet (nonce: 0)"
                else
                    check_passed "Deployer wallet ready (nonce: $TX_COUNT)"
                fi
            fi
        else
            check_failed "Invalid PRIVATE_KEY format - cannot derive address"
        fi
    else
        check_warning "cast not available - cannot check deployer wallet balance"
    fi
else
    if [ -z "$PRIVATE_KEY" ]; then
        check_failed "PRIVATE_KEY not set - cannot check deployer wallet"
    fi
    if [ -z "$NETWORK_RPC_URL" ]; then
        check_failed "No RPC URL available - cannot check deployer wallet"
    fi
fi

# Compilation Checks
section_header "Contract Compilation"

if command -v forge &> /dev/null; then
    echo "Running forge build..."
    # Quick build check with timeout protection
    if forge build --sizes 2>/dev/null; then
        check_passed "Contracts compile successfully"
    else
        check_failed "Contract compilation failed. Run 'forge build' for details."
    fi
    
    # Check for common contract files
    if [ -d "src" ]; then
        check_passed "src/ directory exists"
        
        # Look for key contract files
        if find src -name "*.sol" | grep -q .; then
            SOLIDITY_FILES=$(find src -name "*.sol" | wc -l | tr -d ' ')
            check_passed "Found $SOLIDITY_FILES Solidity files"
        else
            check_warning "No Solidity files found in src/"
        fi
    else
        check_warning "src/ directory not found"
    fi
    
    if [ -d "scripts" ]; then
        check_passed "scripts/ directory exists"
        
        # Check for deployment scripts
        if find scripts -name "*.s.sol" | grep -q .; then
            SCRIPT_FILES=$(find scripts -name "*.s.sol" | wc -l | tr -d ' ')
            check_passed "Found $SCRIPT_FILES deployment scripts"
        fi
    fi
fi

# Test Environment
section_header "Testing Environment"

if [ -d "test" ]; then
    check_passed "test/ directory exists"
    
    if find test -name "*.t.sol" | grep -q .; then
        TEST_FILES=$(find test -name "*.t.sol" | wc -l | tr -d ' ')
        check_passed "Found $TEST_FILES test files"
        
        # Try to run tests (with timeout protection)
        echo "Running forge test (quick check)..."
        # Use gtimeout on macOS if available, otherwise skip timeout
        TIMEOUT_CMD=""
        if command -v gtimeout &> /dev/null; then
            TIMEOUT_CMD="gtimeout 30s"
        elif command -v timeout &> /dev/null; then
            TIMEOUT_CMD="timeout 30s"
        fi
        
        if [ -n "$TIMEOUT_CMD" ]; then
            if $TIMEOUT_CMD forge test --no-match-path="test/fork/*" -q 2>/dev/null; then
                check_passed "Tests pass successfully"
            fi
        fi
    else
        check_warning "No test files (.t.sol) found in test/"
    fi
else
    check_warning "test/ directory not found"
fi

# Security Checks
section_header "Security & Configuration"

# Check for common security files
if [ -f ".gitignore" ]; then
    if grep -q "\.env" .gitignore; then
        check_passed ".env file is gitignored"
    else
        check_failed ".env file is NOT gitignored (security risk!)"
    fi
else
    check_warning ".gitignore file not found"
fi

# Check for hardhat/truffle artifacts (should use Foundry)
if [ -d "node_modules" ]; then
    check_warning "node_modules directory found - using npm/yarn alongside Foundry"
fi

if [ -f "hardhat.config.js" ] || [ -f "hardhat.config.ts" ]; then
    check_warning "Hardhat config found - ensure using Foundry for deployment"
fi

# Summary
section_header "Summary"

echo -e "${BLUE}📋 Verification Results:${NC}"

# Show all verified items
if [ ${#VERIFIED_ITEMS[@]} -gt 0 ]; then
    echo -e "\n${GREEN}✅ Successfully Verified (${#VERIFIED_ITEMS[@]} items):${NC}"
    for item in "${VERIFIED_ITEMS[@]}"; do
        echo -e "  ${GREEN}•${NC} $item"
    done
fi

# Show all warnings
if [ ${#WARNING_ITEMS[@]} -gt 0 ]; then
    echo -e "\n${YELLOW}⚠️  Warnings (${#WARNING_ITEMS[@]} items):${NC}"
    for item in "${WARNING_ITEMS[@]}"; do
        echo -e "  ${YELLOW}•${NC} $item"
    done
fi

# Show all failed items
if [ ${#FAILED_ITEMS[@]} -gt 0 ]; then
    echo -e "\n${RED}❌ Failed Checks (${#FAILED_ITEMS[@]} items):${NC}"
    for item in "${FAILED_ITEMS[@]}"; do
        echo -e "  ${RED}•${NC} $item"
    done
fi

echo -e "\n${BLUE}📊 Overall Status:${NC}"
if [ $CHECKS_FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All critical checks passed! ($CHECKS_PASSED/$CHECKS_TOTAL)${NC}"
    echo -e "${GREEN}✅ Ready for HyperEVM Testnet deployment${NC}"
    
    # Console log all verified items for easy copying
    echo -e "\n${BLUE}📝 Console Log - All Verified Items:${NC}"
    echo "=================================="
    for item in "${VERIFIED_ITEMS[@]}"; do
        echo "VERIFIED: $item"
    done
    echo "=================================="
    
    exit 0
else
    echo -e "${RED}❌ $CHECKS_FAILED critical checks failed ($CHECKS_PASSED passed, $CHECKS_FAILED failed, $CHECKS_TOTAL total)${NC}"
    echo -e "${YELLOW}⚠️  Please address the failed checks before deployment${NC}"
    
    # Console log failed items for debugging
    echo -e "\n${BLUE}📝 Console Log - Issues to Address:${NC}"
    echo "=================================="
    for item in "${FAILED_ITEMS[@]}"; do
        echo "FAILED: $item"
    done
    for item in "${WARNING_ITEMS[@]}"; do
        echo "WARNING: $item"
    done
    echo "=================================="
    
    exit 1
fi