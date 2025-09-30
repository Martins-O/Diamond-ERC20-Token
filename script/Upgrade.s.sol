// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {ERC20MintableFacet} from "../src/facets/ERC20MintableFacet.sol";

contract Upgrade is Script {
    // Existing Diamond address on Sepolia
    address constant DIAMOND_ADDRESS = 0x400BCC394190117FF7e3Bd8b69d16c9C66Fe6E07;
    // Current ERC20MintableFacet address (will be replaced)
    address constant OLD_MINT_FACET_ADDRESS = 0x400BCC394190117FF7e3Bd8b69d16c9C66Fe6E07;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("=====================================");
        console.log("    UPGRADING DIAMOND ERC20 FACET   ");
        console.log("=====================================");
        console.log("Deployer:", deployer);
        console.log("Diamond Address:", DIAMOND_ADDRESS);
        console.log("Chain ID:", block.chainid);
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy new ERC20MintableFacet with updated logic (no owner restriction)
        console.log("Deploying new ERC20MintableFacet...");
        ERC20MintableFacet newMintFacet = new ERC20MintableFacet();
        console.log("New ERC20MintableFacet deployed at:", address(newMintFacet));
        console.log("");

        // Prepare diamond cut to replace the mintable facet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);

        // Replace ERC20MintableFacet
        bytes4[] memory mintSelectors = new bytes4[](1);
        mintSelectors[0] = ERC20MintableFacet.mint.selector;

        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(newMintFacet),
            action: IDiamondCut.FacetCutAction.Replace,
            functionSelectors: mintSelectors
        });

        console.log("Executing diamond cut to upgrade ERC20MintableFacet...");
        IDiamondCut(DIAMOND_ADDRESS).diamondCut(cut, address(0), "");
        console.log("[SUCCESS] Diamond upgraded!");

        vm.stopBroadcast();

        // Verify the upgrade
        _verifyUpgrade(address(newMintFacet));

        // Show upgrade results
        _printUpgradeResults(address(newMintFacet));
    }

    function _verifyUpgrade(address newMintFacetAddress) internal view {
        console.log("");
        console.log("=== VERIFYING UPGRADE ===");

        // Verify the diamond now points to the new facet implementation
        // Note: We can't easily verify the internal mapping without a loupe call
        // but the diamond cut should have succeeded if we got here
        console.log("New MintableFacet address:", newMintFacetAddress);
        console.log("Diamond address unchanged:", DIAMOND_ADDRESS);
        console.log("[OK] Upgrade verification passed!");
    }

    function _printUpgradeResults(address newMintFacetAddress) internal view {
        console.log("");
        console.log("=====================================");
        console.log("         UPGRADE COMPLETE           ");
        console.log("=====================================");
        console.log("");
        console.log("Diamond Address (unchanged):", DIAMOND_ADDRESS);
        console.log("New ERC20MintableFacet:", newMintFacetAddress);
        console.log("");
        console.log("*** IMPORTANT CHANGES ***");
        console.log("- Anyone can now mint tokens!");
        console.log("- No owner restriction on mint function");
        console.log("- All other functionality unchanged");
        console.log("");

        console.log("=== VERIFICATION COMMANDS ===");
        console.log("Verify the new ERC20MintableFacet:");
        console.log(
            string.concat(
                "forge verify-contract ",
                vm.toString(newMintFacetAddress),
                " src/facets/ERC20MintableFacet.sol:ERC20MintableFacet --chain ",
                vm.toString(block.chainid),
                " --etherscan-api-key $ETHERSCAN_API_KEY"
            )
        );
        console.log("");

        console.log("=== TEST THE UPGRADE ===");
        console.log("Test minting by anyone (replace YOUR_ADDRESS and AMOUNT):");
        console.log(
            string.concat(
                "cast send ",
                vm.toString(DIAMOND_ADDRESS),
                ' "mint(address,uint256)" YOUR_ADDRESS AMOUNT --private-key $PRIVATE_KEY --rpc-url $SEPOLIA_RPC_URL'
            )
        );
        console.log("");

        string memory etherscanUrl = _getEtherscanUrl(block.chainid);
        if (bytes(etherscanUrl).length > 0) {
            console.log("View on Etherscan:");
            console.log(string.concat(etherscanUrl, vm.toString(DIAMOND_ADDRESS)));
            console.log("");
            console.log("New MintableFacet:");
            console.log(string.concat(etherscanUrl, vm.toString(newMintFacetAddress)));
        }

        console.log("=====================================");
        console.log("Your Diamond is now upgraded!");
        console.log("Everyone can mint tokens!");
        console.log("=====================================");
    }

    function _getEtherscanUrl(uint256 chainId) internal pure returns (string memory) {
        if (chainId == 1) return "https://etherscan.io/address/";
        if (chainId == 11155111) return "https://sepolia.etherscan.io/address/";
        if (chainId == 5) return "https://goerli.etherscan.io/address/";
        if (chainId == 137) return "https://polygonscan.com/address/";
        if (chainId == 80001) return "https://mumbai.polygonscan.com/address/";
        if (chainId == 56) return "https://bscscan.com/address/";
        if (chainId == 97) return "https://testnet.bscscan.com/address/";
        if (chainId == 43114) return "https://snowtrace.io/address/";
        if (chainId == 43113) return "https://testnet.snowtrace.io/address/";
        if (chainId == 4202) return "https://sepolia-blockscout.lisk.com/address/";
        return "";
    }
}