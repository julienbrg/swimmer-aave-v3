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
        echo "RPC_URL=https://rpc.hyperliquid-testnet.xyz/evm"
        echo "HYPEREVM_TESTNET_CHAIN_ID=998"
        exit 1
    fi
    
    # Source environment variables
    source .env
    
    # Check required environment variables
    if [[ -z "$PRIVATE_KEY" ]] || [[ -z "$RPC_URL" ]]; then
        print_error "Missing required environment variables!"
        print_status "Please set PRIVATE_KEY and RPC_URL in .env"
        exit 1
    fi
    
    # Check if forge is available
    if ! command -v forge &> /dev/null; then
        print_error "Forge not found! Please install Foundry."
        exit 1
    fi
    
    # Note: Aave V3 contracts are now in src/ directory, no external dependency needed
    
    print_success "All prerequisites met"
}

# Function to clean up previous deployments
cleanup_previous() {
    print_header "CLEANING UP PREVIOUS DEPLOYMENTS"
    
    # Clean forge artifacts
    print_status "Cleaning forge artifacts..."
    forge clean
    
    # Remove old broadcast files
    if [[ -d "broadcast" ]]; then
        print_status "Removing old broadcast files..."
        rm -rf broadcast/
    fi
    
    print_success "Cleanup completed"
}

# Function to check if a deployment step is already completed by checking broadcast files
check_step_completed() {
    local step_number="$1"
    local script_name="$2"
    
    # Check if broadcast file exists for this script
    local broadcast_file="broadcast/${script_name}/998/run-latest.json"
    
    if [[ -f "$broadcast_file" ]]; then
        # Check if the broadcast file contains contract deployments (successful transactions)
        if grep -q '"contractAddress":' "$broadcast_file" && grep -q '"transactionHash":' "$broadcast_file"; then
            return 0  # Completed successfully (has deployed contracts)
        fi
    fi
    
    return 1  # Not completed
}

# Function to run deployment script with error handling and skip logic
run_deployment_step() {
    local step_name="$1"
    local script_path="$2"
    local step_number="$3"
    local script_name="$4"  # Script name for broadcast file check
    
    # Check if step is already completed by checking broadcast files
    if [[ -n "$script_name" ]] && check_step_completed "$step_number" "$script_name"; then
        print_success "Step $step_number already completed: $step_name (skipping)"
        return 0
    fi
    
    print_status "Running Step $step_number: $step_name"
    
    if forge script "$script_path" --rpc-url "$RPC_URL" --broadcast -v; then
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
    run_deployment_step "Core Contracts (PoolAddressesProvider)" \
                       "script/deploy/01_DeployCoreContracts.s.sol:DeployCoreContracts" "1" "01_DeployCoreContracts.s.sol"
    
    # Step 2: Deploy Registry
    run_deployment_step "PoolAddressesProvider Registry" \
                       "script/deploy/02_DeployRegistry.s.sol:DeployRegistry" "2" "02_DeployRegistry.s.sol"
    
    # Step 3: Deploy ACL
    run_deployment_step "ACL Manager Setup" \
                       "script/deploy/03_DeployACL.s.sol:DeployACL" "3" "03_DeployACL.s.sol"
    
    # Step 4: Deploy Pool
    run_deployment_step "Pool Implementation and Proxies" \
                       "script/deploy/04_DeployPool.s.sol:DeployPool" "4" "04_DeployPool.s.sol"
    
    # Step 5: Deploy Oracle
    run_deployment_step "Oracle Deployment" \
                       "script/deploy/05_DeployOracle.s.sol:DeployOracle" "5" "05_DeployOracle.s.sol"
    
    # Step 6: Setup Roles
    run_deployment_step "Setup Admin Roles" \
                       "script/deploy/06_SetupRoles.s.sol:SetupRoles" "6" "06_SetupRoles.s.sol"
    
    # Step 7: Deploy Token Implementations
    run_deployment_step "Token Implementations (aToken, Debt Tokens)" \
                       "script/deploy/07_DeployTokenImplementations.s.sol:DeployTokenImplementations" "7" "07_DeployTokenImplementations.s.sol"
    
    # Step 8: Deploy Interest Rate Strategies
    run_deployment_step "Interest Rate Strategies" \
                       "script/deploy/08_DeployInterestRateStrategy.s.sol:DeployInterestRateStrategy" "8" "08_DeployInterestRateStrategy.s.sol"
    
    # Step 9: Deploy Mock Tokens
    run_deployment_step "Mock Tokens for Testing" \
                       "script/deploy/09_DeployMockTokens.s.sol:DeployMockTokens" "9" "09_DeployMockTokens.s.sol"
    
    print_success "All deployment steps completed successfully!"
}

# Function to generate deployment summary
generate_summary() {
    print_header "GENERATING DEPLOYMENT SUMMARY"
    
    print_status "Creating deployment summary..."
    if forge script script/deploy/00_DeployAll.s.sol:DeployAll --rpc-url "$RPC_URL" -v; then
        print_success "Deployment summary generated"
    else
        print_warning "Failed to generate deployment summary (deployment may still be valid)"
    fi
}

# Function to run verification
run_verification() {
    print_header "VERIFYING DEPLOYMENT"
    
    print_status "Running configuration verification..."
    if forge script script/config/VerifyConfig.s.sol:VerifyConfig --rpc-url "$RPC_URL" -v; then
        print_success "Configuration verification completed"
    else
        print_warning "Configuration verification had issues (check output above)"
    fi
    
    print_status "Checking reserves status..."
    if forge script script/config/CheckReserves.s.sol:CheckReserves --rpc-url "$RPC_URL" -v; then
        print_success "Reserves check completed"
    else
        print_warning "Reserves check had issues (check output above)"
    fi
}

# Function to display deployment information
show_deployment_info() {
    print_header "DEPLOYMENT COMPLETE"
    
    # Check if broadcast files exist
    if [[ -d "broadcast" ]]; then
        echo -e "${GREEN}Deployment files:${NC} broadcast/ directory contains deployment records"
        
        # Extract PoolAddressesProvider address from first step
        if [[ -f "broadcast/01_DeployCoreContracts.s.sol/998/run-latest.json" ]]; then
            provider=$(grep -o '"contractAddress":"[^"]*"' broadcast/01_DeployCoreContracts.s.sol/998/run-latest.json | head -1 | cut -d'"' -f4)
            if [[ -n "$provider" ]]; then
                echo -e "\n${BLUE}Key Addresses:${NC}"
                echo -e "PoolAddressesProvider:   ${GREEN}$provider${NC}"
                echo -e "Note: Use VerifyConfig to get all deployed addresses"
            fi
        fi
        
        echo -e "\n${BLUE}Next Steps:${NC}"
        echo "1. Verify deployment: forge script script/config/VerifyConfig.s.sol:VerifyConfig --rpc-url \$RPC_URL -v"
        echo "2. Check reserves: forge script script/config/CheckReserves.s.sol:CheckReserves --rpc-url \$RPC_URL -v"
        echo "3. List assets: forge script script/config/ListUSDC.s.sol:ListUSDC --rpc-url \$RPC_URL --broadcast -v"
        
        echo -e "\n${BLUE}Available Mock Tokens:${NC}"
        echo "- USDC, USDT, DAI, WBTC, LINK, UNI"
        echo "- All tokens have been deployed and are ready for listing as reserves"
        
    else
        print_error "Broadcast directory not found! Deployment may have failed."
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
        echo "  RPC_URL                   RPC URL for target network"
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