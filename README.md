# Aave V3.0 on HyperEVM

## Setup

### Install Dependencies

First, install the required libraries:

```shell
# Install OpenZeppelin contracts
forge install OpenZeppelin/openzeppelin-contracts --no-commit

# Install forge-std (if not already installed)
forge install foundry-rs/forge-std --no-commit
```

### Environment Config

Copy the example environment file and configure it:

```shell
cp .env.example .env
```

The deployment scripts work on both **Local Anvil** and **HyperEVM Testnet**. Switch between them by commenting/uncommenting the relevant sections in `.env`:

```env
# HyperEVM Testnet (uncomment for testnet deployment)
# PRIVATE_KEY=your_private_key_without_0x_prefix
# RPC_URL=https://rpc.hyperliquid-testnet.xyz/evm
# CHAIN_ID=998

# Local Anvil (uncomment for local testing)
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
RPC_URL=http://127.0.0.1:8545
CHAIN_ID=31337
```

**For Local Anvil**: Start anvil in another terminal:
```shell
anvil
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

Deploy the complete Aave V3.0 protocol with the automated deployment script:

```shell
# Deploy complete protocol (all 9 steps)
./deploy.sh
```

The script automatically:
- ✅ Skips already-deployed contracts
- ✅ Handles deployment dependencies and sequencing
- ✅ Works on both Anvil and HyperEVM Testnet
- ✅ Saves all addresses to broadcast files

**Alternative**: Run individual deployment scripts manually:

```shell
# 1. Deploy core contracts
forge script script/deploy/01_DeployCoreContracts.s.sol:DeployCoreContracts \
  --rpc-url $RPC_URL --broadcast -vvvv

# 2. Deploy registry
forge script script/deploy/02_DeployRegistry.s.sol:DeployRegistry \
  --rpc-url $RPC_URL --broadcast -vvvv

# ... (see deploy.sh for complete sequence)
```

### Configuration & Verification

After deployment, verify and configure your protocol:

```shell
# Verify complete deployment configuration (should show 100/100)
forge script script/config/VerifyConfig.s.sol:VerifyConfig --rpc-url $RPC_URL -vvv

# Check which reserves are currently listed
forge script script/config/CheckReserves.s.sol:CheckReserves --rpc-url $RPC_URL -vvv

# List new reserves (will work for unlisted tokens like DAI, WBTC, etc.)
source .env && forge script script/config/ListUSDC.s.sol:ListUSDC --rpc-url $RPC_URL --broadcast -vvv
```

All deployment addresses are automatically saved to broadcast files in `./broadcast/`.

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