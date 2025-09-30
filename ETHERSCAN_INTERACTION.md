# Diamond ERC20 - Etherscan Interaction Guide

## Contract Address
**Diamond (Main Contract):** `0x400BCC394190117FF7e3Bd8b69d16c9C66Fe6E07`

**Etherscan URL:** https://sepolia.etherscan.io/address/0x400BCC394190117FF7e3Bd8b69d16c9C66Fe6E07

## Issue: Functions Not Showing
If Etherscan shows "no public Write functions found", try these solutions:

### Solution 1: Wait and Refresh
- Wait 15-30 minutes for Etherscan to index the proxy
- Clear browser cache
- Refresh the page

### Solution 2: Manual Function Calls
Use the "Contract" > "Write Contract" section and manually add these functions:

#### ERC20 Functions:
```solidity
// Read Functions
name() → string
symbol() → string
decimals() → uint8
totalSupply() → uint256
balanceOf(address) → uint256
allowance(address,address) → uint256

// Write Functions
transfer(address,uint256) → bool
approve(address,uint256) → bool
transferFrom(address,address,uint256) → bool
```

#### Diamond-Specific Functions:
```solidity
// Admin Functions (Owner Only)
mint(address,uint256) → void
transferOwnership(address) → void
owner() → address

// Burn Functions
burn(uint256) → void
burnFrom(address,uint256) → void

// Diamond Loupe Functions
facets() → tuple[]
facetAddresses() → address[]
facetFunctionSelectors(address) → bytes4[]
```

### Solution 3: Direct Function Signatures
If manual entry doesn't work, use these exact function signatures:

**Transfer Tokens:**
- Function: `transfer`
- Signature: `transfer(address,uint256)`
- Input Types: `address,uint256`

**Check Balance:**
- Function: `balanceOf`
- Signature: `balanceOf(address)`
- Input Types: `address`

**Mint Tokens (Owner Only):**
- Function: `mint`
- Signature: `mint(address,uint256)`
- Input Types: `address,uint256`

### Solution 4: Use Cast Commands
If Etherscan doesn't work, use these cast commands:

```bash
# Check your balance
cast call 0x400BCC394190117FF7e3Bd8b69d16c9C66Fe6E07 "balanceOf(address)(uint256)" YOUR_ADDRESS --rpc-url $SEPOLIA_RPC_URL

# Transfer tokens
cast send 0x400BCC394190117FF7e3Bd8b69d16c9C66Fe6E07 "transfer(address,uint256)(bool)" RECIPIENT_ADDRESS AMOUNT --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_RPC_URL

# Mint tokens (owner only)
cast send 0x400BCC394190117FF7e3Bd8b69d16c9C66Fe6E07 "mint(address,uint256)" RECIPIENT_ADDRESS AMOUNT --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_RPC_URL
```

### Solution 5: Alternative Interfaces
Try these alternative interfaces that might recognize the proxy:

1. **Louper Diamond Inspector:** https://louper.dev/
   - Enter your Diamond address
   - View all facets and functions

2. **Direct RPC Calls:** Use web3 libraries or wallets that support custom function calls

## Troubleshooting

### Why This Happens:
- Diamond proxies use `delegatecall` to forward functions to facets
- Etherscan sometimes needs time to detect the proxy pattern
- The verification process doesn't always immediately show all proxy functions

### Expected Behavior After Fix:
- All ERC20 functions become visible
- Write Contract section shows transfer, approve, mint, burn functions
- Read Contract section shows name, symbol, balanceOf, etc.
- Diamond Loupe functions show all connected facets

## Contract Details
- **Name:** DiamondToken
- **Symbol:** DMD
- **Decimals:** 18
- **Initial Supply:** 1,000,000 DMD
- **Owner:** 0x4A78dFC52566063f50F8cf4eD52F513AEB866A0C

## Support
If none of these solutions work, the contract is still fully functional via:
- Web3 libraries (ethers.js, web3.py)
- Wallet applications (MetaMask with custom functions)
- Direct RPC calls using cast or curl