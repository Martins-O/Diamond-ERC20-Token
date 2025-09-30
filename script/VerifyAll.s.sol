// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";

contract VerifyAll is Script {
    // Contract addresses from deployment - UPDATE THESE WITH YOUR ACTUAL ADDRESSES
    address constant DIAMOND_ADDRESS =
        0x917Cd8F3a598a5828a83b7b1911BEfc8382B4c97;
    address constant DEPLOYER_ADDRESS =
        0x4A78dFC52566063f50F8cf4eD52F513AEB866A0C;
    address constant CUT_FACET_ADDRESS =
        0xE662b2b29f7775c7fD4967DD29f077140C679a42;
    address constant LOUPE_FACET_ADDRESS =
        0x9a9e7Ec4EA29bb63fE7c38E124B253b44fF897Cc;
    address constant OWNERSHIP_FACET_ADDRESS =
        0xE28Ca4478300CDA8658Cb9499fd2917bfE5c0E88;
    address constant ERC20_FACET_ADDRESS =
        0xD15D898124A6bA1B32669254D5487BF0c9E3B4De;
    address constant INIT_FACET_ADDRESS =
        0x2AEdd3B64bD2916c11Ca896c354A4CC6ecc672Fe;
    address constant MINT_FACET_ADDRESS =
        0x400BCC394190117FF7e3Bd8b69d16c9C66Fe6E07;
    address constant BURN_FACET_ADDRESS =
        0x9d40b771e87F37Bd01046d91c74DbeBB18e22483;

    function run() external view {
        string memory chainId = vm.toString(block.chainid);

        console.log("===============================================");
        console.log("       VERIFY ALL CONTRACTS COMMANDS        ");
        console.log("===============================================");
        console.log("Chain ID:", chainId);
        console.log("Diamond Address:", DIAMOND_ADDRESS);
        console.log("");
        console.log("Copy and run ALL these commands in sequence:");
        console.log("");

        // Diamond (Main Contract) - with constructor args
        console.log("# 1. Verify Diamond (Main Contract)");
        console.log(
            string.concat(
                "forge verify-contract ",
                vm.toString(DIAMOND_ADDRESS),
                " src/Diamond.sol:Diamond --chain ",
                chainId,
                ' --constructor-args $(cast abi-encode "constructor(address,address)" ',
                vm.toString(DEPLOYER_ADDRESS),
                " ",
                vm.toString(CUT_FACET_ADDRESS),
                ")"
            )
        );
        console.log("");

        // All facets (no constructor args needed)
        console.log("# 2. Verify DiamondCutFacet");
        console.log(
            string.concat(
                "forge verify-contract ",
                vm.toString(CUT_FACET_ADDRESS),
                " src/facets/DiamondCutFacet.sol:DiamondCutFacet --chain ",
                chainId
            )
        );
        console.log("");

        console.log("# 3. Verify DiamondLoupeFacet");
        console.log(
            string.concat(
                "forge verify-contract ",
                vm.toString(LOUPE_FACET_ADDRESS),
                " src/facets/DiamondLoupeFacet.sol:DiamondLoupeFacet --chain ",
                chainId
            )
        );
        console.log("");

        console.log("# 4. Verify OwnershipFacet");
        console.log(
            string.concat(
                "forge verify-contract ",
                vm.toString(OWNERSHIP_FACET_ADDRESS),
                " src/facets/OwnershipFacet.sol:OwnershipFacet --chain ",
                chainId
            )
        );
        console.log("");

        console.log("# 5. Verify ERC20Facet");
        console.log(
            string.concat(
                "forge verify-contract ",
                vm.toString(ERC20_FACET_ADDRESS),
                " src/facets/ERC20Facet.sol:ERC20Facet --chain ",
                chainId
            )
        );
        console.log("");

        console.log("# 6. Verify ERC20InitFacet");
        console.log(
            string.concat(
                "forge verify-contract ",
                vm.toString(INIT_FACET_ADDRESS),
                " src/facets/ERC20InitFacet.sol:ERC20InitFacet --chain ",
                chainId
            )
        );
        console.log("");

        console.log("# 7. Verify ERC20MintableFacet");
        console.log(
            string.concat(
                "forge verify-contract ",
                vm.toString(MINT_FACET_ADDRESS),
                " src/facets/ERC20MintableFacet.sol:ERC20MintableFacet --chain ",
                chainId
            )
        );
        console.log("");

        console.log("# 8. Verify ERC20BurnableFacet");
        console.log(
            string.concat(
                "forge verify-contract ",
                vm.toString(BURN_FACET_ADDRESS),
                " src/facets/ERC20BurnableFacet.sol:ERC20BurnableFacet --chain ",
                chainId
            )
        );
        console.log("");

        console.log("===============================================");
        console.log("After running all commands above, your Diamond");
        console.log("contract will be fully verified and interactive");
        console.log("on Etherscan!");
        console.log("");

        string memory etherscanUrl = _getEtherscanUrl(block.chainid);
        if (bytes(etherscanUrl).length > 0) {
            console.log("View verified contract:");
            console.log(
                string.concat(etherscanUrl, vm.toString(DIAMOND_ADDRESS))
            );
        }
        console.log("===============================================");
    }

    function _getEtherscanUrl(
        uint256 chainId
    ) internal pure returns (string memory) {
        if (chainId == 1) return "https://etherscan.io/address/";
        if (chainId == 11155111) return "https://sepolia.etherscan.io/address/";
        if (chainId == 5) return "https://goerli.etherscan.io/address/";
        if (chainId == 137) return "https://polygonscan.com/address/";
        if (chainId == 80001) return "https://mumbai.polygonscan.com/address/";
        if (chainId == 56) return "https://bscscan.com/address/";
        if (chainId == 97) return "https://testnet.bscscan.com/address/";
        if (chainId == 43114) return "https://snowtrace.io/address/";
        if (chainId == 43113) return "https://testnet.snowtrace.io/address/";
        return "";
    }
}
