#!/bin/bash

# Diamond ERC20 - Upgrade to Public Minting Script
# Usage: ./upgrade-diamond.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}    UPGRADING DIAMOND TO PUBLIC MINT  ${NC}"
echo -e "${BLUE}=======================================${NC}"
echo ""

# Check if environment variables are set
if [ -z "$PRIVATE_KEY" ]; then
    echo -e "${RED}Error: PRIVATE_KEY environment variable not set${NC}"
    echo "Please set your private key:"
    echo "export PRIVATE_KEY=your_private_key_here"
    echo ""
    exit 1
fi

if [ -z "$SEPOLIA_RPC_URL" ]; then
    echo -e "${RED}Error: SEPOLIA_RPC_URL environment variable not set${NC}"
    echo "Please set your Sepolia RPC URL:"
    echo "export SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_PROJECT_ID"
    echo "or"
    echo "export SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY"
    echo ""
    exit 1
fi

echo -e "${GREEN}Environment variables set correctly!${NC}"
echo "Using Sepolia RPC: $SEPOLIA_RPC_URL"
echo ""

echo -e "${YELLOW}Building contracts...${NC}"
forge build

echo -e "${YELLOW}Deploying upgrade to Sepolia...${NC}"
echo "This will:"
echo "1. Deploy a new ERC20MintableFacet with no owner restrictions"
echo "2. Replace the old facet in the existing Diamond contract"
echo "3. Keep the same Diamond contract address"
echo ""

# Deploy the upgrade
forge script script/Upgrade.s.sol:Upgrade --rpc-url "$SEPOLIA_RPC_URL" --broadcast --verify

echo ""
echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}    UPGRADE DEPLOYMENT COMPLETE!      ${NC}"
echo -e "${GREEN}=======================================${NC}"
echo ""
echo -e "${GREEN}Your Diamond contract has been upgraded!${NC}"
echo "Diamond Address: 0x400BCC394190117FF7e3Bd8b69d16c9C66Fe6E07"
echo ""
echo -e "${BLUE}*** IMPORTANT CHANGE ***${NC}"
echo "Anyone can now mint tokens using the mint function!"
echo ""
echo -e "${BLUE}Test the upgrade:${NC}"
echo "cast send 0x400BCC394190117FF7e3Bd8b69d16c9C66Fe6E07 \"mint(address,uint256)\" YOUR_ADDRESS AMOUNT --private-key \$PRIVATE_KEY --rpc-url \$SEPOLIA_RPC_URL"
echo ""
echo -e "${BLUE}View on Etherscan:${NC}"
echo "https://sepolia.etherscan.io/address/0x400BCC394190117FF7e3Bd8b69d16c9C66Fe6E07"
echo ""