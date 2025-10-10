# Aave V3.0 on HyperEVM

## Setup

### Install Dependencies

First, install the required libraries:

```shell
# Install Aave V3 Core contracts
forge install aave/aave-v3-core --no-commit

# Install OpenZeppelin contracts
forge install OpenZeppelin/openzeppelin-contracts --no-commit

# Install forge-std (if not already installed)
forge install foundry-rs/forge-std --no-commit
```

### Environment Config

Create a `.env` file with your HyperEVM Testnet configuration:

```env
# Remove 0x prefix from private key
PRIVATE_KEY=your_private_key_without_0x_prefix

# HyperEVM Testnet
HYPEREVM_TESTNET_RPC_URL=https://rpc.hyperliquid-testnet.xyz/evm
HYPEREVM_TESTNET_CHAIN_ID=998
```

### Check readiness

Run the deployment checklist to verify your setup:

```shell
./checklist.sh
```

This will verify:
- ✅ Foundry installation
- ✅ Environment variables
- ✅ HyperEVM Testnet connectivity  
- ✅ Deployer wallet balance
- ✅ Contract compilation
- ✅ Dependencies

## Deployment Scripts

The repository includes comprehensive deployment scripts organized by function:

```
script/
├── deploy/          # Core deployment scripts
├── config/          # Configuration scripts  
├── management/      # Role management scripts
├── utils/           # Common utilities
└── verify/          # Contract verification
```

### Deployment

Deploy the complete Aave V3.0 protocol:

```shell
# 1. Deploy core contracts
forge script script/deploy/01_DeployCoreContracts.s.sol:DeployCoreContracts \
  --rpc-url $HYPEREVM_TESTNET_RPC_URL --broadcast -vvvv

# 2. Deploy token implementations
forge script script/deploy/02_DeployTokenImplementations.s.sol:DeployTokenImplementations \
  --rpc-url $HYPEREVM_TESTNET_RPC_URL --broadcast -vvvv

# 3. Deploy interest rate strategies
forge script script/deploy/03_DeployInterestRateStrategy.s.sol:DeployInterestRateStrategy \
  --rpc-url $HYPEREVM_TESTNET_RPC_URL --broadcast -vvvv

# 4. Deploy mock tokens (optional - for testing)
forge script script/deploy/04_DeployMockTokens.s.sol:DeployMockTokens \
  --rpc-url $HYPEREVM_TESTNET_RPC_URL --broadcast -vvvv
```

All deployment addresses are automatically saved to `./deployments/hyperevm-testnet.json`.

**📖 See [deployment guide](script/deploy/README.md) for detailed instructions.**

## References

- [Aave V3 Core repo](https://github.com/aave/aave-v3-core/releases/tag/v1.19.0)
- [HyperEVM tools](https://hyperliquid.gitbook.io/hyperliquid-docs/builder-tools/hyperevm-tools)
- [Deployment Checklist](docs/deploy-and-config-checklist.md)

## Support

Feel free to reach out to [Julien](https://github.com/julienbrg) on [Farcaster](https://warpcast.com/julien-), [Element](https://matrix.to/#/@julienbrg:matrix.org), [Status](https://status.app/u/iwSACggKBkp1bGllbgM=#zQ3shmh1sbvE6qrGotuyNQB22XU5jTrZ2HFC8bA56d5kTS2fy), [Telegram](https://t.me/julienbrg), [Twitter](https://twitter.com/julienbrg), [Discord](https://discordapp.com/users/julienbrg), or [LinkedIn](https://www.linkedin.com/in/julienberanger/).

## Credits

The contracts were forked from [Aave V3 Core (v1.19.0)](https://github.com/aave/aave-v3-core/releases/tag/v1.19.0)

<img src="https://bafkreid5xwxz4bed67bxb2wjmwsec4uhlcjviwy7pkzwoyu5oesjd3sp64.ipfs.w3s.link" alt="built-with-ethereum-w3hc" width="100"/>