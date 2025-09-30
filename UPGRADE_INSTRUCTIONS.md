# Diamond ERC20 Upgrade Instructions

## Overview
This upgrade removes the owner restriction from the mint function, allowing anyone to mint tokens while keeping the same Diamond contract address.

## Current Diamond Address
**Sepolia**: `0x400BCC394190117FF7e3Bd8b69d16c9C66Fe6E07`

## Prerequisites

1. **Set Environment Variables**:
```bash
export PRIVATE_KEY=your_private_key_here
export SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_PROJECT_ID
export ETHERSCAN_API_KEY=your_etherscan_api_key_here
```

2. **Ensure you have ETH on Sepolia** for gas fees

## Option 1: Automated Upgrade (Recommended)

Run the automated upgrade script:
```bash
./upgrade-diamond.sh
```

## Option 2: Manual Upgrade

Run the upgrade script manually:
```bash
# Build contracts
forge build

# Deploy upgrade to Sepolia
forge script script/Upgrade.s.sol:Upgrade --rpc-url $SEPOLIA_RPC_URL --broadcast --verify
```

## What This Upgrade Does

1. **Deploys** a new `ERC20MintableFacet` contract with updated logic
2. **Replaces** the old mintable facet implementation in the existing Diamond
3. **Preserves** all other functionality and the same Diamond address
4. **Removes** the owner-only restriction from the `mint(address,uint256)` function

## After Upgrade

### Test Public Minting
Anyone can now mint tokens:
```bash
cast send 0x400BCC394190117FF7e3Bd8b69d16c9C66Fe6E07 \
  "mint(address,uint256)" \
  YOUR_ADDRESS \
  1000000000000000000 \
  --private-key $PRIVATE_KEY \
  --rpc-url $SEPOLIA_RPC_URL
```

### Verify on Etherscan
- **Diamond Contract**: https://sepolia.etherscan.io/address/0x400BCC394190117FF7e3Bd8b69d16c9C66Fe6E07
- The new mintable facet address will be shown after deployment

## Key Changes

- ✅ **Before**: Only owner could mint tokens
- ✅ **After**: Anyone can mint tokens
- ✅ **Diamond address remains the same**
- ✅ **All other functions unchanged**

## Verification

The upgrade script will automatically verify the new facet contract on Etherscan. You can also verify manually using the commands shown in the script output.