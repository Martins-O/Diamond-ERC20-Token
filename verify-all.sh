#!/bin/bash

# Diamond ERC20 - Verify All Contracts Script
# Usage: ./verify-all.sh <CHAIN_ID> [ETHERSCAN_API_KEY]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Contract addresses from deployment - UPDATED WITH NEW DEPLOYMENT
DIAMOND_ADDRESS="0x400BCC394190117FF7e3Bd8b69d16c9C66Fe6E07"
DEPLOYER_ADDRESS="0x4A78dFC52566063f50F8cf4eD52F513AEB866A0C"
CUT_FACET_ADDRESS="0xE662b2b29f7775c7fD4967DD29f077140C679a42"
LOUPE_FACET_ADDRESS="0x9a9e7Ec4EA29bb63fE7c38E124B253b44fF897Cc"
OWNERSHIP_FACET_ADDRESS="0xE28Ca4478300CDA8658Cb9499fd2917bfE5c0E88"
ERC20_FACET_ADDRESS="0xD15D898124A6bA1B32669254D5487BF0c9E3B4De"
INIT_FACET_ADDRESS="0x2AEdd3B64bD2916c11Ca896c354A4CC6ecc672Fe"
MINT_FACET_ADDRESS="0x400BCC394190117FF7e3Bd8b69d16c9C66Fe6E07"
BURN_FACET_ADDRESS="0x9d40b771e87F37Bd01046d91c74DbeBB18e22483"

# Get chain ID from argument
CHAIN_ID=${1:-4202}  # Default to Lisk Sepolia
ETHERSCAN_API_KEY=${2:-$ETHERSCAN_API_KEY}

if [ -z "$ETHERSCAN_API_KEY" ]; then
    echo -e "${YELLOW}Warning: No Etherscan API key provided. Some verifications may fail.${NC}"
    echo "Usage: ./verify-all.sh <CHAIN_ID> [ETHERSCAN_API_KEY]"
    echo "Or set ETHERSCAN_API_KEY environment variable"
    echo ""
fi

echo -e "${BLUE}=======================================${NC}"
echo -e "${BLUE}    VERIFYING ALL DIAMOND CONTRACTS   ${NC}"
echo -e "${BLUE}=======================================${NC}"
echo "Chain ID: $CHAIN_ID"
echo "Diamond Address: $DIAMOND_ADDRESS"
echo ""

# Function to verify a contract
verify_contract() {
    local name=$1
    local address=$2
    local contract_path=$3
    local constructor_args=$4

    echo -e "${YELLOW}Verifying $name...${NC}"

    # Special handling for Lisk Sepolia (chain 4202) - use Blockscout
    if [ "$CHAIN_ID" = "4202" ]; then
        if [ -n "$constructor_args" ]; then
            forge verify-contract "$address" "$contract_path" \
                --verifier blockscout \
                --verifier-url "https://sepolia-blockscout.lisk.com/api" \
                --constructor-args "$constructor_args" || {
                echo -e "${RED}Failed to verify $name${NC}"
                return 1
            }
        else
            forge verify-contract "$address" "$contract_path" \
                --verifier blockscout \
                --verifier-url "https://sepolia-blockscout.lisk.com/api" || {
                echo -e "${RED}Failed to verify $name${NC}"
                return 1
            }
        fi
    else
        # Standard Etherscan verification for other chains
        if [ -n "$constructor_args" ]; then
            forge verify-contract "$address" "$contract_path" \
                --chain "$CHAIN_ID" \
                --constructor-args "$constructor_args" \
                ${ETHERSCAN_API_KEY:+--etherscan-api-key "$ETHERSCAN_API_KEY"} || {
                echo -e "${RED}Failed to verify $name${NC}"
                return 1
            }
        else
            forge verify-contract "$address" "$contract_path" \
                --chain "$CHAIN_ID" \
                ${ETHERSCAN_API_KEY:+--etherscan-api-key "$ETHERSCAN_API_KEY"} || {
                echo -e "${RED}Failed to verify $name${NC}"
                return 1
            }
        fi
    fi

    echo -e "${GREEN}✓ $name verified successfully${NC}"
    echo ""
}

# Generate constructor args for Diamond contract
DIAMOND_CONSTRUCTOR_ARGS=$(cast abi-encode "constructor(address,address)" "$DEPLOYER_ADDRESS" "$CUT_FACET_ADDRESS")

echo -e "${BLUE}Starting verification process...${NC}"
echo ""

# Verify all contracts
verify_contract "Diamond (Main Contract)" "$DIAMOND_ADDRESS" "src/Diamond.sol:Diamond" "$DIAMOND_CONSTRUCTOR_ARGS"
verify_contract "DiamondCutFacet" "$CUT_FACET_ADDRESS" "src/facets/DiamondCutFacet.sol:DiamondCutFacet"
verify_contract "DiamondLoupeFacet" "$LOUPE_FACET_ADDRESS" "src/facets/DiamondLoupeFacet.sol:DiamondLoupeFacet"
verify_contract "OwnershipFacet" "$OWNERSHIP_FACET_ADDRESS" "src/facets/OwnershipFacet.sol:OwnershipFacet"
verify_contract "ERC20Facet" "$ERC20_FACET_ADDRESS" "src/facets/ERC20Facet.sol:ERC20Facet"
verify_contract "ERC20InitFacet" "$INIT_FACET_ADDRESS" "src/facets/ERC20InitFacet.sol:ERC20InitFacet"
verify_contract "ERC20MintableFacet" "$MINT_FACET_ADDRESS" "src/facets/ERC20MintableFacet.sol:ERC20MintableFacet"
verify_contract "ERC20BurnableFacet" "$BURN_FACET_ADDRESS" "src/facets/ERC20BurnableFacet.sol:ERC20BurnableFacet"

echo -e "${GREEN}=======================================${NC}"
echo -e "${GREEN}    ALL CONTRACTS VERIFIED SUCCESS!   ${NC}"
echo -e "${GREEN}=======================================${NC}"
echo ""
echo "Your Diamond contract is now fully verified on Etherscan!"
echo "Main contract address: $DIAMOND_ADDRESS"
echo ""

# Show Etherscan URLs
case $CHAIN_ID in
    1)
        ETHERSCAN_URL="https://etherscan.io/address/"
        ;;
    11155111)
        ETHERSCAN_URL="https://sepolia.etherscan.io/address/"
        ;;
    5)
        ETHERSCAN_URL="https://goerli.etherscan.io/address/"
        ;;
    137)
        ETHERSCAN_URL="https://polygonscan.com/address/"
        ;;
    80001)
        ETHERSCAN_URL="https://mumbai.polygonscan.com/address/"
        ;;
    56)
        ETHERSCAN_URL="https://bscscan.com/address/"
        ;;
    97)
        ETHERSCAN_URL="https://testnet.bscscan.com/address/"
        ;;
    43114)
        ETHERSCAN_URL="https://snowtrace.io/address/"
        ;;
    43113)
        ETHERSCAN_URL="https://testnet.snowtrace.io/address/"
        ;;
    4202)
        ETHERSCAN_URL="https://sepolia-blockscout.lisk.com/address/"
        ;;
    *)
        ETHERSCAN_URL=""
        ;;
esac

if [ -n "$ETHERSCAN_URL" ]; then
    echo -e "${BLUE}View on Etherscan:${NC}"
    echo "${ETHERSCAN_URL}${DIAMOND_ADDRESS}"
    echo ""
    echo -e "${BLUE}All your contracts are now visible and interactive on Etherscan!${NC}"
fi