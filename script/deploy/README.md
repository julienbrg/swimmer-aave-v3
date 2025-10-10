# Aave V3.0 Deployment Scripts

This directory contains the modular deployment scripts for Aave V3.0 protocol. These scripts work on any EVM network and are designed for both testnet and mainnet deployments.

## Prerequisites

1. **Environment Setup**: Ensure your `.env` file is properly configured:
   ```env
   PRIVATE_KEY=0xyour_private_key_with_0x_prefix
   RPC_URL=https://your-network-rpc-url
   ```

2. **Dependencies**: Run the deployment readiness check:
   ```bash
   ./checklist.sh
   ```

3. **Sufficient Balance**: Ensure your deployer wallet has sufficient ETH for gas fees (recommended: 2+ ETH).

## Deployment Architecture

The deployment is broken into **9 modular steps** to handle network transaction size limits and provide better control:

### Step-by-Step Deployment

#### 1. PoolAddressesProvider
```bash
forge script script/deploy/01_DeployCoreContracts.s.sol:DeployCoreContracts --rpc-url $RPC_URL --broadcast
```
**Deploys:** PoolAddressesProvider (the registry for all protocol contracts)

#### 2. Registry
```bash
forge script script/deploy/02_DeployRegistry.s.sol:DeployRegistry --rpc-url $RPC_URL --broadcast
```
**Deploys:** PoolAddressesProviderRegistry and registers the provider

#### 3. ACL Manager
```bash
forge script script/deploy/03_DeployACL.s.sol:DeployACL --rpc-url $RPC_URL --broadcast
```
**Deploys:** Sets ACL Admin and deploys ACLManager

#### 4. Pool Implementations
```bash
forge script script/deploy/04_DeployPool.s.sol:DeployPool --rpc-url $RPC_URL --broadcast
```
**Deploys:** Pool and PoolConfigurator implementation contracts

#### 5. Oracle & Data Provider
```bash
forge script script/deploy/05_DeployOracle.s.sol:DeployOracle --rpc-url $RPC_URL --broadcast
```
**Deploys:** AaveOracle and AaveProtocolDataProvider

#### 6. Setup Admin Roles
```bash
forge script script/deploy/06_SetupRoles.s.sol:SetupRoles --rpc-url $RPC_URL --broadcast
```
**Configures:** Initial admin roles (Pool Admin, Emergency Admin, Asset Listing Admin)

#### 7. Token Implementations
```bash
forge script script/deploy/07_DeployTokenImplementations.s.sol:DeployTokenImplementations --rpc-url $RPC_URL --broadcast
```
**Deploys:** AToken, StableDebtToken, and VariableDebtToken implementations

#### 8. Interest Rate Strategies
```bash
forge script script/deploy/08_DeployInterestRateStrategy.s.sol:DeployInterestRateStrategy --rpc-url $RPC_URL --broadcast
```
**Deploys:** Default, Stablecoin, and Volatile asset interest rate strategies

#### 9. Mock Tokens (Optional - Testnet Only)
```bash
forge script script/deploy/09_DeployMockTokens.s.sol:DeployMockTokens --rpc-url $RPC_URL --broadcast
```
**Deploys:** Mock ERC20 tokens (USDC, USDT, DAI, WBTC, LINK, UNI) for testing

## Deployment Output

All deployments are saved to `./deployments/hyperevm-testnet.json` with the following structure:

```json
{
  "chainId": 998,
  "network": "hyperevm-testnet", 
  "timestamp": 1234567890,
  "poolAddressesProvider": "0x...",
  "poolAddressesProviderRegistry": "0x...",
  "aclManager": "0x...",
  "pool": "0x...",
  "poolConfigurator": "0x...",
  "oracle": "0x...",
  "protocolDataProvider": "0x...",
  "aTokenImpl": "0x...",
  "stableDebtTokenImpl": "0x...",
  "variableDebtTokenImpl": "0x...",
  "defaultInterestRateStrategy": "0x...",
  "stablecoinInterestRateStrategy": "0x...",
  "volatileAssetInterestRateStrategy": "0x...",
  "mockTokens": {
    "USDC": "0x...",
    "USDT": "0x...",
    "DAI": "0x...",
    "WBTC": "0x...",
    "LINK": "0x...",
    "UNI": "0x..."
  }
}
```

## Verification

All contracts should be automatically verified on HyperEVM Testnet block explorer. If verification fails, you can manually verify using:

```bash
forge verify-contract \
  --chain-id 998 \
  --num-of-optimizations 200 \
  --watch \
  --compiler-version v0.8.10+commit.fc410830 \
  <CONTRACT_ADDRESS> \
  <CONTRACT_NAME> \
  --verifier-url <HYPEREVM_VERIFIER_URL>
```

## Security Considerations

⚠️ **Important Security Notes:**

1. **Initial Admin**: The deployer wallet is set as the initial admin for all roles. This should be changed to a multisig/governance contract before mainnet usage.

2. **Admin Roles Set**:
   - Pool Admin: Can manage pool configurations
   - Emergency Admin: Can pause/unpause protocol
   - Asset Listing Admin: Can add new reserves

3. **Mock Tokens**: Mock tokens are for testing only and have no real value.

## Troubleshooting

### Common Issues

1. **"Wrong network" error**: Ensure you're connected to HyperEVM Testnet (Chain ID: 998)

2. **Insufficient gas**: Increase your ETH balance or adjust gas settings

3. **Contract already exists**: Remove the existing deployment file if redeploying:
   ```bash
   rm ./deployments/hyperevm-testnet.json
   ```

4. **Verification fails**: Sometimes verification takes time. You can manually verify later using the forge verify-contract command.

### Dry Run

Before broadcasting, you can simulate the deployment:

```bash
forge script script/deploy/01_DeployCoreContracts.s.sol:DeployCoreContracts \
  --rpc-url $HYPEREVM_TESTNET_RPC_URL \
  -vvvv
```

## Next Steps

After successful deployment:

1. **Configure Reserves**: Use the `config/` scripts to initialize and configure reserves
2. **Set Up Oracles**: Configure price oracles for each asset  
3. **Manage Roles**: Use the `management/` scripts to transfer admin roles to proper governance
4. **Testing**: Test the protocol functionality with the deployed mock tokens

## Support

For questions or issues:
- Check the [deployment checklist](../../docs/deploy-and-config-checklist.md)
- Review the [Aave V3 documentation](https://github.com/aave/aave-v3-core)
- Ensure all prerequisites are met using `./checklist.sh`