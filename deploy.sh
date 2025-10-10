#!/bin/bash

# Aave V3.0 Complete Deployment Script for HyperEVM Testnet
# This script performs a full deployment of Aave V3.0 protocol

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "\n${BLUE}=================================================${NC}"
    echo -e "${BLUE}    $1${NC}"
    echo -e "${BLUE}=================================================${NC}\n"
}

# Function to check prerequisites
check_prerequisites() {
    print_header "CHECKING PREREQUISITES"
    
    # Check if .env file exists
    if [[ ! -f ".env" ]]; then
        print_error ".env file not found!"
        print_status "Please create a .env file with:"
        echo "PRIVATE_KEY=0x..."
        echo "HYPEREVM_TESTNET_RPC_URL=https://rpc.hyperliquid-testnet.xyz/evm"
        echo "HYPEREVM_TESTNET_CHAIN_ID=998"
        exit 1
    fi
    
    # Source environment variables
    source .env
    
    # Check required environment variables
    if [[ -z "$PRIVATE_KEY" ]] || [[ -z "$HYPEREVM_TESTNET_RPC_URL" ]]; then
        print_error "Missing required environment variables!"
        print_status "Please set PRIVATE_KEY and HYPEREVM_TESTNET_RPC_URL in .env"
        exit 1
    fi
    
    # Check if forge is available
    if ! command -v forge &> /dev/null; then
        print_error "Forge not found! Please install Foundry."
        exit 1
    fi
    
    # Check if lib/aave-v3-core exists
    if [[ ! -d "lib/aave-v3-core" ]]; then
        print_error "aave-v3-core dependency not found!"
        print_status "Installing aave-v3-core dependency..."
        forge install aave/aave-v3-core --no-commit
    fi
    
    print_success "All prerequisites met"
}

# Function to clean up previous deployments
cleanup_previous() {
    print_header "CLEANING UP PREVIOUS DEPLOYMENTS"
    
    # Clean forge artifacts
    print_status "Cleaning forge artifacts..."
    forge clean
    
    # Remove old deployment files
    if [[ -d "deployments" ]]; then
        print_status "Removing old deployment files..."
        rm -f deployments/hyperevm-testnet.json
        rm -f deployments/hyperevm-testnet-*.md
    else
        mkdir -p deployments
    fi
    
    # Remove old broadcast files
    if [[ -d "broadcast" ]]; then
        print_status "Removing old broadcast files..."
        rm -rf broadcast/
    fi
    
    print_success "Cleanup completed"
}

# Function to run deployment script with error handling
run_deployment_step() {
    local step_name="$1"
    local script_path="$2"
    local step_number="$3"
    
    print_status "Running Step $step_number: $step_name"
    
    if forge script "$script_path" --rpc-url "$HYPEREVM_TESTNET_RPC_URL" --broadcast -v; then
        print_success "Step $step_number completed: $step_name"
    else
        print_error "Step $step_number failed: $step_name"
        print_status "Check the error above and fix before continuing"
        exit 1
    fi
    
    # Brief pause between steps
    sleep 2
}

# Function to perform full deployment
deploy_protocol() {
    print_header "DEPLOYING AAVE V3.0 PROTOCOL"
    
    # Step 1: Deploy Core Contracts
    run_deployment_step "Core Contracts (PoolAddressesProvider, Registry)" \
                       "script/deploy/01_DeployCoreContracts.s.sol:DeployCoreContracts" "1"
    
    # Step 2: Deploy Oracle
    run_deployment_step "Oracle Deployment" \
                       "script/deploy/02_DeployOracle.s.sol:DeployOracle" "2"
    
    # Step 3: Deploy ACL
    run_deployment_step "ACL Manager Setup" \
                       "script/deploy/03_DeployACL.s.sol:DeployACL" "3"
    
    # Step 4: Deploy Pool
    run_deployment_step "Pool Implementation and Proxies" \
                       "script/deploy/04_DeployPool.s.sol:DeployPool" "4"
    
    # Step 5: Deploy Protocol Data Provider
    run_deployment_step "Protocol Data Provider" \
                       "script/deploy/05_DeployProtocolDataProvider.s.sol:DeployProtocolDataProvider" "5"
    
    # Step 6: Deploy Collector
    run_deployment_step "Collector Contract" \
                       "script/deploy/06_DeployCollector.s.sol:DeployCollector" "6"
    
    # Step 7: Deploy Token Implementations
    run_deployment_step "Token Implementations (aToken, Debt Tokens)" \
                       "script/deploy/07_DeployTokenImplementations.s.sol:DeployTokenImplementations" "7"
    
    # Step 8: Deploy Interest Rate Strategies
    run_deployment_step "Interest Rate Strategies" \
                       "script/deploy/08_DeployInterestRateStrategy.s.sol:DeployInterestRateStrategy" "8"
    
    # Step 9: Deploy Mock Tokens
    run_deployment_step "Mock Tokens for Testing" \
                       "script/deploy/09_DeployMockTokens.s.sol:DeployMockTokens" "9"
    
    print_success "All deployment steps completed successfully!"
}

# Function to generate deployment summary
generate_summary() {
    print_header "GENERATING DEPLOYMENT SUMMARY"
    
    print_status "Creating deployment summary..."
    if forge script script/deploy/00_DeployAll.s.sol:DeployAll --rpc-url "$HYPEREVM_TESTNET_RPC_URL" -v; then
        print_success "Deployment summary generated"
    else
        print_warning "Failed to generate deployment summary (deployment may still be valid)"
    fi
}

# Function to run verification
run_verification() {
    print_header "VERIFYING DEPLOYMENT"
    
    print_status "Running configuration verification..."
    if forge script script/config/VerifyConfig.s.sol:VerifyConfig --rpc-url "$HYPEREVM_TESTNET_RPC_URL" -v; then
        print_success "Configuration verification completed"
    else
        print_warning "Configuration verification had issues (check output above)"
    fi
    
    print_status "Checking reserves status..."
    if forge script script/config/CheckReserves.s.sol:CheckReserves --rpc-url "$HYPEREVM_TESTNET_RPC_URL" -v; then
        print_success "Reserves check completed"
    else
        print_warning "Reserves check had issues (check output above)"
    fi
}

# Function to display deployment information
show_deployment_info() {
    print_header "DEPLOYMENT COMPLETE"
    
    if [[ -f "deployments/hyperevm-testnet.json" ]]; then
        echo -e "${GREEN}Deployment file:${NC} deployments/hyperevm-testnet.json"
        
        # Extract key addresses
        pool_proxy=$(grep -o '"poolProxy":"[^"]*"' deployments/hyperevm-testnet.json | cut -d'"' -f4)
        provider=$(grep -o '"poolAddressesProvider":"[^"]*"' deployments/hyperevm-testnet.json | cut -d'"' -f4)
        
        echo -e "\n${BLUE}Key Addresses:${NC}"
        echo -e "Pool (Main Entry Point): ${GREEN}$pool_proxy${NC}"
        echo -e "PoolAddressesProvider:   ${GREEN}$provider${NC}"
        
        echo -e "\n${BLUE}Next Steps:${NC}"
        echo "1. Verify deployment: forge script script/config/VerifyConfig.s.sol:VerifyConfig --rpc-url \$HYPEREVM_TESTNET_RPC_URL -v"
        echo "2. Check reserves: forge script script/config/CheckReserves.s.sol:CheckReserves --rpc-url \$HYPEREVM_TESTNET_RPC_URL -v"
        echo "3. List assets: forge script script/config/ListUSDC.s.sol:ListUSDC --rpc-url \$HYPEREVM_TESTNET_RPC_URL --broadcast -v"
        
        echo -e "\n${BLUE}Available Mock Tokens:${NC}"
        echo "- USDC, USDT, DAI, WBTC, LINK, UNI"
        echo "- All tokens have been deployed and are ready for listing as reserves"
        
    else
        print_error "Deployment file not found! Deployment may have failed."
        exit 1
    fi
}

# Main execution
main() {
    print_header "AAVE V3.0 DEPLOYMENT FOR HYPEREVM TESTNET"
    
    # Check if user wants to clean up first
    if [[ "$1" == "--clean" ]]; then
        print_status "Clean deployment requested"
        cleanup_previous
    elif [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
        echo "Usage: ./deploy.sh [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --clean    Clean up previous deployments before starting"
        echo "  --verify   Run verification only (skip deployment)"
        echo "  --help     Show this help message"
        echo ""
        echo "Environment variables required:"
        echo "  PRIVATE_KEY                 Your private key (with 0x prefix)"
        echo "  HYPEREVM_TESTNET_RPC_URL   RPC URL for HyperEVM Testnet"
        echo ""
        exit 0
    elif [[ "$1" == "--verify" ]]; then
        print_status "Verification only requested"
        source .env
        run_verification
        exit 0
    fi
    
    # Run the complete deployment process
    check_prerequisites
    deploy_protocol
    generate_summary
    run_verification
    show_deployment_info
    
    print_success "Aave V3.0 deployment completed successfully!"
    echo -e "\n${GREEN}🎉 Your Aave V3.0 protocol is now deployed and ready for use!${NC}"
}

# Run main function with all arguments
main "$@"