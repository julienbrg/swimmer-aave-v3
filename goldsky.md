# Aave V3.0 - HyperEVM Testnet Deployment

**Network**: HyperEVM Testnet  
**Chain ID**: 998  
**RPC URL**: https://rpc.hyperliquid-testnet.xyz/evm  
**Deployment Date**: 2025-01-10  
**Deployer**: 0x9a6586c563D56899d2d84a6b22729870126f62Fb  

## 🏗️ Core Protocol Contracts

### Main Entry Points

| Contract | Type | Address | ABI Location |
|----------|------|---------|--------------|
| **Pool (Main Entry)** | Proxy | `0xd029e2017a76dCA2D2DD354A2A92FBce7e5D2074` | `lib/aave-v3-core/contracts/interfaces/IPool.sol` |
| **PoolConfigurator** | Proxy | `0x3C84e78f59796D1Fe182D606Ce0A95b93d5f73DA` | `lib/aave-v3-core/contracts/interfaces/IPoolConfigurator.sol` |
| **PoolAddressesProvider** | Implementation | `0x97b1E699Fe1E9Ae1e43f2b9845b9233373a4b3dC` | `lib/aave-v3-core/contracts/protocol/configuration/PoolAddressesProvider.sol` |

### Core Infrastructure

| Contract | Type | Address | ABI Location |
|----------|------|---------|--------------|
| **PoolAddressesProviderRegistry** | Implementation | `0x476270053811a993E5D33a31aC97fbA912BD7559` | `lib/aave-v3-core/contracts/protocol/configuration/PoolAddressesProviderRegistry.sol` |
| **ACLManager** | Implementation | `0xd85120Dd1f1eD7957930363F5E668ef6Edfc4905` | `lib/aave-v3-core/contracts/protocol/configuration/ACLManager.sol` |
| **AaveOracle** | Implementation | `0x4A3F56F843EE5C3812fd2751C49aDEf95e544DD2` | `lib/aave-v3-core/contracts/misc/AaveOracle.sol` |
| **AaveProtocolDataProvider** | Implementation | `0x8A5EBDf0031ED72Eb381e4607894aea7038e94D3` | `lib/aave-v3-core/contracts/misc/AaveProtocolDataProvider.sol` |

### Implementation Contracts

| Contract | Type | Address | ABI Location |
|----------|------|---------|--------------|
| **Pool Implementation** | Implementation | `0xe1D5159242038e193015a49890f324a38A75AF04` | `lib/aave-v3-core/contracts/protocol/pool/Pool.sol` |
| **PoolConfigurator Implementation** | Implementation | `0x5Af8c85E111D4A17C5B568Dd20a33b740070f0E2` | `lib/aave-v3-core/contracts/protocol/pool/PoolConfigurator.sol` |

## 🪙 Token Implementations

| Contract | Address | ABI Location |
|----------|---------|--------------|
| **AToken Implementation** | `0x0dbcd5B405B1128bF06E75F937f600ea53D76076` | `lib/aave-v3-core/contracts/protocol/tokenization/AToken.sol` |
| **StableDebtToken Implementation** | `0x84B14AA9b21FA45deD2A5C83990e8769D4df5073` | `lib/aave-v3-core/contracts/protocol/tokenization/StableDebtToken.sol` |
| **VariableDebtToken Implementation** | `0xf2c8b78278B48A9c91b39C86D3990228cEaC5aC0` | `lib/aave-v3-core/contracts/protocol/tokenization/VariableDebtToken.sol` |

## 📈 Interest Rate Strategies

| Strategy | Address | ABI Location |
|----------|---------|--------------|
| **Default Strategy** | `0x60471ABd262E2388e90FbE1f676ed0C762C39a09` | `lib/aave-v3-core/contracts/protocol/pool/DefaultReserveInterestRateStrategy.sol` |
| **Stablecoin Strategy** | `0xa89cc87b458c0C89c8842E44441093d330EfF40F` | `lib/aave-v3-core/contracts/protocol/pool/DefaultReserveInterestRateStrategy.sol` |
| **Volatile Asset Strategy** | `0xD4d76e84E1B0EA4eba09bEE40D06C6cfB89B7cBE` | `lib/aave-v3-core/contracts/protocol/pool/DefaultReserveInterestRateStrategy.sol` |

### Strategy Parameters

| Strategy | Optimal Usage | Base Rate | Slope 1 | Slope 2 | Use Cases |
|----------|---------------|-----------|---------|---------|-----------|
| **Default** | 80% | 0% | 4% | 60% | ETH, WBTC, major crypto |
| **Stablecoin** | 90% | 0% | 2% | 60% | USDC, USDT, DAI |
| **Volatile** | 70% | 1% | 6% | 80% | Altcoins, high-risk assets |

## 🎯 Mock Tokens (Testing Only)

| Token | Symbol | Address | Decimals | ABI Location |
|-------|--------|---------|----------|--------------|
| **Mock USD Coin** | USDC | `0x83C0F8D4e46E5B81461aC0133B635f57745b464E` | 6 | `lib/aave-v3-core/contracts/mocks/tokens/MintableERC20.sol` |
| **Mock Tether USD** | USDT | `0xEc048DA076f171BcCac90F1CE888FcabC10c6c4b` | 6 | `lib/aave-v3-core/contracts/mocks/tokens/MintableERC20.sol` |
| **Mock Dai Stablecoin** | DAI | `0x610a2f01C74357dcf2117CdFBB07736FEb145167` | 18 | `lib/aave-v3-core/contracts/mocks/tokens/MintableERC20.sol` |
| **Mock Wrapped Bitcoin** | WBTC | `0x63944467f67da637a703A7F3C13F748F3C10958A` | 8 | `lib/aave-v3-core/contracts/mocks/tokens/MintableERC20.sol` |
| **Mock Chainlink** | LINK | `0xB191D82173471ec22098e35CC19C5621861555Cf` | 18 | `lib/aave-v3-core/contracts/mocks/tokens/MintableERC20.sol` |
| **Mock Uniswap** | UNI | `0x7BdBa9B1C27343D105FA39A9c34c340d7549AccB` | 18 | `lib/aave-v3-core/contracts/mocks/tokens/MintableERC20.sol` |

## 🏦 Active Reserves

### USDC Reserve (LISTED)

| Token Type | Address | ABI Location |
|------------|---------|--------------|
| **aUSDC** | `0x85fd9D3a818ad4659d5F28616afd37Fe388a63B1` | `lib/aave-v3-core/contracts/protocol/tokenization/AToken.sol` |
| **Stable Debt USDC** | `0xdD4C652f1b6791eEeeBda1606EE46A277cb6F520` | `lib/aave-v3-core/contracts/protocol/tokenization/StableDebtToken.sol` |
| **Variable Debt USDC** | `0xf3a71fe73C1CF34287BA622156B255914a7e3f07` | `lib/aave-v3-core/contracts/protocol/tokenization/VariableDebtToken.sol` |

**Reserve Configuration:**
- **Underlying Asset**: Mock USD Coin (USDC)
- **LTV**: 80%
- **Liquidation Threshold**: 85%
- **Liquidation Bonus**: 5%
- **Reserve Factor**: 10%
- **Interest Rate Strategy**: Stablecoin Strategy
- **Borrowing Enabled**: Yes
- **Stable Rate Borrowing**: Yes

## 📁 ABI Compilation Artifacts

All ABIs can be found in the compiled artifacts after running:
```bash
forge build
```

### Key ABI Locations:
```
out/
├── Pool.sol/Pool.json                              # Main Pool interface
├── PoolConfigurator.sol/PoolConfigurator.json      # Pool configuration
├── PoolAddressesProvider.sol/PoolAddressesProvider.json # Address provider
├── ACLManager.sol/ACLManager.json                  # Access control
├── AaveOracle.sol/AaveOracle.json                  # Price oracle
├── AToken.sol/AToken.json                          # Interest-bearing tokens
├── StableDebtToken.sol/StableDebtToken.json        # Stable debt tokens
├── VariableDebtToken.sol/VariableDebtToken.json    # Variable debt tokens
├── DefaultReserveInterestRateStrategy.sol/DefaultReserveInterestRateStrategy.json # Interest rates
└── MintableERC20.sol/MintableERC20.json            # Mock tokens
```

## 🔧 Configuration Scripts

Verify and interact with the protocol:

```bash
# Verify deployment (should show 100/100)
forge script script/config/VerifyConfig.s.sol:VerifyConfig --rpc-url $RPC_URL -vvv

# Check reserves status
forge script script/config/CheckReserves.s.sol:CheckReserves --rpc-url $RPC_URL -vvv

# List new reserves
source .env && forge script script/config/ListUSDC.s.sol:ListUSDC --rpc-url $RPC_URL --broadcast -vvv
```

## 🔐 Access Control

| Role | Address | Description |
|------|---------|-------------|
| **ACL Admin** | `0x9a6586c563D56899d2d84a6b22729870126f62Fb` | Master admin for all permissions |
| **Pool Admin** | `0x9a6586c563D56899d2d84a6b22729870126f62Fb` | Can modify pool parameters |
| **Emergency Admin** | `0x9a6586c563D56899d2d84a6b22729870126f62Fb` | Can pause protocol in emergencies |
| **Asset Listing Admin** | `0x9a6586c563D56899d2d84a6b22729870126f62Fb` | Can list new assets as reserves |

## 📋 Deployment Summary

**Total Gas Used**: ~35M gas  
**Total Cost**: ~0.0035 ETH on HyperEVM Testnet  
**Deployment Status**: ✅ **COMPLETE** (100/100 verification score)  
**Protocol Status**: 🚀 **FULLY OPERATIONAL**

## 🔗 Useful Links

- **HyperEVM Testnet Explorer**: https://explorer.hyperliquid-testnet.xyz/
- **Aave V3 Core Repository**: https://github.com/aave/aave-v3-core
- **Deployment Guide**: [README.md](./README.md)
- **Broadcast Files**: `./broadcast/` (contains full deployment transaction history)

---

*⚠️ **Warning**: These are testnet deployments for development and testing only. Do not use in production without proper auditing and security measures.*