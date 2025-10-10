# Aave V3.0 Deployment Scripts

This directory contains the deployment scripts for Aave V3.0 protocol on HyperEVM Testnet.

## Prerequisites

1. **Environment Setup**: Ensure your `.env` file is properly configured:
   ```env
   PRIVATE_KEY=your_private_key_without_0x_prefix
   HYPEREVM_TESTNET_RPC_URL=https://rpc.hyperliquid-testnet.xyz/evm
   HYPEREVM_TESTNET_CHAIN_ID=998
   ```

2. **Dependencies**: Run the deployment readiness check:
   ```bash
   ./checklist.sh
   ```

3. **Sufficient Balance**: Ensure your deployer wallet has sufficient ETH for gas fees (recommended: 2+ ETH).

## Deployment Order

Deploy the contracts in the following order:

### 1. Core Contracts
```bash
forge script script/deploy/01_DeployCoreContracts.s.sol:DeployCoreContracts \
  --rpc-url $HYPEREVM_TESTNET_RPC_URL \
  --broadcast \
  --verify \
  -vvvv
```

**Deploys:**
- PoolAddressesProvider
- PoolAddressesProviderRegistry  
- Pool (implementation)
- PoolConfigurator (implementation)
- ACLManager
- AaveOracle
- AaveProtocolDataProvider

### 2. Token Implementations
```bash
forge script script/deploy/02_DeployTokenImplementations.s.sol:DeployTokenImplementations \
  --rpc-url $HYPEREVM_TESTNET_RPC_URL \
  --broadcast \
  --verify \
  -vvvv
```

**Deploys:**
- AToken implementation
- StableDebtToken implementation
- VariableDebtToken implementation

### 3. Interest Rate Strategies
```bash
forge script script/deploy/03_DeployInterestRateStrategy.s.sol:DeployInterestRateStrategy \
  --rpc-url $HYPEREVM_TESTNET_RPC_URL \
  --broadcast \
  --verify \
  -vvvv
```

**Deploys:**
- Default Interest Rate Strategy (for ETH, major crypto)
- Stablecoin Interest Rate Strategy (for USDC, USDT, DAI)
- Volatile Asset Interest Rate Strategy (for altcoins)

### 4. Mock Tokens (Optional - For Testing)
```bash
forge script script/deploy/04_DeployMockTokens.s.sol:DeployMockTokens \
  --rpc-url $HYPEREVM_TESTNET_RPC_URL \
  --broadcast \
  --verify \
  -vvvv
```

**Deploys:**
- Mock USDC, USDT, DAI, WBTC, LINK, UNI tokens
- Mints initial supply to deployer for testing

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