# Aave V3.0 - HyperEVM Testnet Deployment

**Network**: HyperEVM Testnet  
**Chain ID**: 998  
**RPC URL**: https://rpc.hyperliquid-testnet.xyz/evm  
**Deployment Date**: 2025-10-10  
**Deployer**: 0x9a6586c563D56899d2d84a6b22729870126f62Fb  

## 🏗️ Core Protocol Contracts

### Main Entry Points

| Contract | Type | Address | ABI Location |
|----------|------|---------|--------------|
| **Pool (Main Entry)** | Proxy | `0x3aCd6c3e7BF09D907D08Dc4499f200005356d0ef` | `src/interfaces/IPool.sol` |
| **PoolConfigurator** | Proxy | `0xC9bF120d5Fe885df20437Da02B41c75cc42Bd6bF` | `src/interfaces/IPoolConfigurator.sol` |
| **PoolAddressesProvider** | Implementation | `0xF8B71cC4313A2e628000E6fEbF58C962671587D2` | `src/protocol/configuration/PoolAddressesProvider.sol` |

### Core Infrastructure

| Contract | Type | Address | ABI Location |
|----------|------|---------|--------------|
| **PoolAddressesProviderRegistry** | Implementation | `0x7346286767ee9285ff3074ab362b62ee299b9fb5` | `src/protocol/configuration/PoolAddressesProviderRegistry.sol` |
| **ACLManager** | Implementation | `0x219b6467b0b5eF7deb98DFEB963EeAA312bc12fd` | `src/protocol/configuration/ACLManager.sol` |
| **AaveOracle** | Implementation | `0x56Cc9AFD307bc532A642a3f253A3d426Fc118Aa3` | `src/misc/AaveOracle.sol` |
| **AaveProtocolDataProvider** | Implementation | `0x2d5062679ff5c01f0db2002da7d9a1f0951fd9bb` | `src/misc/AaveProtocolDataProvider.sol` |

### Implementation Contracts

| Contract | Type | Address | ABI Location |
|----------|------|---------|--------------|
| **Pool Implementation** | Implementation | `0xdC68cAD40F05a2CfF3C06E1b1115844135073947` | `src/protocol/pool/Pool.sol` |
| **PoolConfigurator Implementation** | Implementation | `0x038bB8c03772d95db8dCC1F2CF9c616Bb6cfB721` | `src/protocol/pool/PoolConfigurator.sol` |

## 🪙 Token Implementations

| Contract | Address | ABI Location |
|----------|---------|--------------|
| **AToken Implementation** | `0x2b77f245B2E3074311c16a6566Fc774741e2837B` | `src/protocol/tokenization/AToken.sol` |
| **StableDebtToken Implementation** | `0x395BFa35B24F01B9EC38C44E249850394C3D41be` | `src/protocol/tokenization/StableDebtToken.sol` |
| **VariableDebtToken Implementation** | `0x212c5b766fCf3Aa190165FAdD3491dd3EB033f3e` | `src/protocol/tokenization/VariableDebtToken.sol` |

## 📈 Interest Rate Strategies

| Strategy | Address | ABI Location |
|----------|---------|--------------|
| **Default Strategy** | `0xBb8B3650FC8448571D0e39C14336e3127e11e8D4` | `src/protocol/pool/DefaultReserveInterestRateStrategy.sol` |
| **Stablecoin Strategy** | `0xFF76a41CA163c16d6B1ED1988903f4f1B71Ae3f1` | `src/protocol/pool/DefaultReserveInterestRateStrategy.sol` |
| **Volatile Asset Strategy** | `0x6D6bE9efd2CD9880FB06d357Bce2E568aC11519d` | `src/protocol/pool/DefaultReserveInterestRateStrategy.sol` |

### Strategy Parameters

| Strategy | Optimal Usage | Base Rate | Slope 1 | Slope 2 | Use Cases |
|----------|---------------|-----------|---------|---------|-----------|
| **Default** | 80% | 0% | 4% | 60% | ETH, WBTC, major crypto |
| **Stablecoin** | 90% | 0% | 2% | 60% | USDC, USDT, DAI |
| **Volatile** | 70% | 1% | 6% | 80% | Altcoins, high-risk assets |

## 🎯 Mock Tokens (Testing Only)

| Token | Symbol | Address | Decimals | ABI Location |
|-------|--------|---------|----------|--------------|
| **Mock USD Coin** | USDC | `0x14Ee4343dc75d77446041Be83ae6f3385ccb695A` | 6 | `src/mocks/tokens/MintableERC20.sol` |
| **Mock Tether USD** | USDT | `0x2D9a93AF809Ea53A90b5aC29e15c66F6e2FDcFb5` | 6 | `src/mocks/tokens/MintableERC20.sol` |
| **Mock Dai Stablecoin** | DAI | `0x5D51C1e40eDCb36b2Bb207242587d76CF799Eb05` | 18 | `src/mocks/tokens/MintableERC20.sol` |
| **Mock Wrapped Bitcoin** | WBTC | `0x6353e6A9920C964ae9E485b0B7f1F83dE7403945` | 8 | `src/mocks/tokens/MintableERC20.sol` |
| **Mock Chainlink** | LINK | `0x26D7B0b2852802Fc58d97a0865771318b306BD1C` | 18 | `src/mocks/tokens/MintableERC20.sol` |
| **Mock Uniswap** | UNI | `0x67ad97dfF0b6234F7E3c7e8E48ef035A4119428f` | 18 | `src/mocks/tokens/MintableERC20.sol` |

## 🏦 Active Reserves

✅ **3 reserves are currently listed and active:**

| Reserve | Token Address | aToken | Stable Debt Token | Variable Debt Token | Strategy | LTV | Liq. Threshold |
|---------|---------------|---------|-------------------|---------------------|----------|-----|----------------|
| **USDC** | `0x14Ee4343dc75d77446041Be83ae6f3385ccb695A` | `0xB9D2724344b8641364151D98F7936df3B757967C` | `0x196eBD89dCbADbfa718b6F074510860ccfAe7dd9` | `0x81868016B15387A8d6baE923b5dA49C4295182d8` | Stablecoin Strategy | 80% | 85% |
| **USDT** | `0x2D9a93AF809Ea53A90b5aC29e15c66F6e2FDcFb5` | `0xB9D2724344b8641364151D98F7936df3B757967C` | `0x196eBD89dCbADbfa718b6F074510860ccfAe7dd9` | `0x81868016B15387A8d6baE923b5dA49C4295182d8` | Stablecoin Strategy | 80% | 85% |
| **WBTC** | `0x6353e6A9920C964ae9E485b0B7f1F83dE7403945` | `0x2b77f245B2E3074311c16a6566Fc774741e2837B` | `0x395BFa35B24F01B9EC38C44E249850394C3D41be` | `0x212c5b766fCf3Aa190165FAdD3491dd3EB033f3e` | Default Strategy | 70% | 75% |

### Available but Unlisted Tokens

The following tokens are deployed but not yet listed as reserves:

| Token | Symbol | Address | Status |
|-------|---------|---------|---------|
| **Mock Dai Stablecoin** | DAI | `0x5D51C1e40eDCb36b2Bb207242587d76CF799Eb05` | Ready to list |
| **Mock Chainlink** | LINK | `0x26D7B0b2852802Fc58d97a0865771318b306BD1C` | Ready to list |
| **Mock Uniswap** | UNI | `0x67ad97dfF0b6234F7E3c7e8E48ef035A4119428f` | Ready to list |

To list additional reserves:
```bash
# Example: List DAI as a reserve
source .env && forge script script/config/ListDAI.s.sol:ListDAI --rpc-url $RPC_URL --broadcast -vvv

# List WBTC (already completed)
source .env && forge script script/config/ListWBTC.s.sol:ListWBTC --rpc-url $RPC_URL --broadcast -vvv
```

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

**Total Gas Used**: ~29M gas  
**Total Cost**: ~0.0029 ETH on HyperEVM Testnet  
**Deployment Status**: ✅ **COMPLETE** (100/100 verification score)  
**Protocol Status**: 🚀 **FULLY OPERATIONAL**  
**Active Reserves**: ✅ **3 reserves listed** (USDC, USDT, WBTC)  
**Ready to Use**: ✅ **Yes** - Users can deposit, borrow, and earn interest

## 🔗 Useful Links

- **HyperEVM Testnet Explorer**: https://explorer.hyperliquid-testnet.xyz/
- **Aave V3 Core Repository**: https://github.com/aave/aave-v3-core
- **Deployment Guide**: [README.md](./README.md)
- **Broadcast Files**: `./broadcast/` (contains full deployment transaction history)

---

*⚠️ **Warning**: These are testnet deployments for development and testing only. Do not use in production without proper auditing and security measures.*