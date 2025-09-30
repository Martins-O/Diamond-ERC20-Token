// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {Diamond} from "../src/Diamond.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {IDiamondLoupe} from "../src/interfaces/IDiamondLoupe.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";

import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";
import {ERC20Facet} from "../src/facets/ERC20Facet.sol";
import {ERC20InitFacet} from "../src/facets/ERC20InitFacet.sol";
import {ERC20MintableFacet} from "../src/facets/ERC20MintableFacet.sol";
import {ERC20BurnableFacet} from "../src/facets/ERC20BurnableFacet.sol";

contract Deploy is Script {
    struct Deployment {
        Diamond diamond;
        DiamondCutFacet cutFacet;
        DiamondLoupeFacet loupeFacet;
        OwnershipFacet ownershipFacet;
        ERC20Facet erc20Facet;
        ERC20InitFacet initFacet;
        ERC20MintableFacet mintFacet;
        ERC20BurnableFacet burnFacet;
        address deployer;
        uint256 chainId;
    }

    function run() external returns (Deployment memory deployment) {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        deployment.deployer = deployer;
        deployment.chainId = block.chainid;

        console.log("=====================================");
        console.log("       DIAMOND ERC20 DEPLOYMENT     ");
        console.log("=====================================");
        console.log("Deployer:", deployer);
        console.log("Chain ID:", block.chainid);
        console.log("Network:", _getNetworkName(block.chainid));
        console.log("");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy facets
        deployment.cutFacet = new DiamondCutFacet();
        deployment.diamond = new Diamond(
            deployer,
            address(deployment.cutFacet)
        );
        deployment.loupeFacet = new DiamondLoupeFacet();
        deployment.ownershipFacet = new OwnershipFacet();
        deployment.erc20Facet = new ERC20Facet();
        deployment.initFacet = new ERC20InitFacet();
        deployment.mintFacet = new ERC20MintableFacet();
        deployment.burnFacet = new ERC20BurnableFacet();

        // Configure Diamond with all facets
        _configureDiamond(deployment);

        vm.stopBroadcast();

        // Verify deployment works
        _verifyDeployment(deployment);

        // Show results
        _printResults(deployment);

        // Show verification commands
        _printVerificationCommands(deployment);

        // Show interaction guide
        _printInteractionGuide(deployment);

        return deployment;
    }

    function _configureDiamond(Deployment memory d) internal {
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](6);

        // Diamond Loupe Facet
        bytes4[] memory loupeSelectors = new bytes4[](5);
        loupeSelectors[0] = IDiamondLoupe.facets.selector;
        loupeSelectors[1] = IDiamondLoupe.facetFunctionSelectors.selector;
        loupeSelectors[2] = IDiamondLoupe.facetAddresses.selector;
        loupeSelectors[3] = IDiamondLoupe.facetAddress.selector;
        loupeSelectors[4] = DiamondLoupeFacet.supportsInterface.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(d.loupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors
        });

        // Ownership Facet
        bytes4[] memory ownSelectors = new bytes4[](2);
        ownSelectors[0] = OwnershipFacet.transferOwnership.selector;
        ownSelectors[1] = OwnershipFacet.owner.selector;
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(d.ownershipFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: ownSelectors
        });

        // ERC20 Core Functions
        bytes4[] memory erc20Selectors = new bytes4[](9);
        erc20Selectors[0] = IERC20.name.selector;
        erc20Selectors[1] = IERC20.symbol.selector;
        erc20Selectors[2] = IERC20.decimals.selector;
        erc20Selectors[3] = IERC20.totalSupply.selector;
        erc20Selectors[4] = IERC20.balanceOf.selector;
        erc20Selectors[5] = IERC20.allowance.selector;
        erc20Selectors[6] = IERC20.transfer.selector;
        erc20Selectors[7] = IERC20.approve.selector;
        erc20Selectors[8] = IERC20.transferFrom.selector;
        cut[2] = IDiamondCut.FacetCut({
            facetAddress: address(d.erc20Facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: erc20Selectors
        });

        // ERC20 Init
        bytes4[] memory initSelectors = new bytes4[](1);
        initSelectors[0] = ERC20InitFacet.init.selector;
        cut[3] = IDiamondCut.FacetCut({
            facetAddress: address(d.initFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: initSelectors
        });

        // ERC20 Mintable
        bytes4[] memory mintSelectors = new bytes4[](1);
        mintSelectors[0] = ERC20MintableFacet.mint.selector;
        cut[4] = IDiamondCut.FacetCut({
            facetAddress: address(d.mintFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: mintSelectors
        });

        // ERC20 Burnable
        bytes4[] memory burnSelectors = new bytes4[](2);
        burnSelectors[0] = ERC20BurnableFacet.burn.selector;
        burnSelectors[1] = ERC20BurnableFacet.burnFrom.selector;
        cut[5] = IDiamondCut.FacetCut({
            facetAddress: address(d.burnFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: burnSelectors
        });

        // Initialize token
        bytes memory initCalldata = abi.encodeWithSelector(
            ERC20InitFacet.init.selector,
            "MartinsToken",
            "MTT",
            uint8(18),
            uint256(1000000 * 10 ** 18)
        );

        console.log("Configuring Diamond with all facets...");
        IDiamondCut(address(d.diamond)).diamondCut(
            cut,
            address(d.initFacet),
            initCalldata
        );
        console.log("[SUCCESS] Diamond configured!");
    }

    function _verifyDeployment(Deployment memory d) internal view {
        console.log("");
        console.log("=== VERIFYING DEPLOYMENT ===");

        IERC20 token = IERC20(address(d.diamond));
        require(
            keccak256(bytes(token.name())) == keccak256(bytes("MartinsToken")),
            "Token name incorrect"
        );
        require(
            keccak256(bytes(token.symbol())) == keccak256(bytes("MTT")),
            "Token symbol incorrect"
        );
        require(token.decimals() == 18, "Decimals incorrect");
        require(
            token.totalSupply() == 1000000 * 10 ** 18,
            "Total supply incorrect"
        );

        IDiamondLoupe loupe = IDiamondLoupe(address(d.diamond));
        address[] memory facetAddresses = loupe.facetAddresses();
        require(facetAddresses.length >= 6, "Not enough facets");

        OwnershipFacet ownership = OwnershipFacet(address(d.diamond));
        require(ownership.owner() == d.deployer, "Owner incorrect");

        console.log("[OK] All verifications passed!");
    }

    function _printResults(Deployment memory d) internal view {
        console.log("");
        console.log("=====================================");
        console.log("         DEPLOYMENT COMPLETE        ");
        console.log("=====================================");
        console.log("");
        console.log("**** MAIN CONTRACT (USE THIS) ****");
        console.log("");
        console.log("DIAMOND ADDRESS:", address(d.diamond));
        console.log("");
        console.log("***********************************");
        console.log("");

        IERC20 token = IERC20(address(d.diamond));
        console.log("Token Info:");
        console.log(string.concat("- Name: ", token.name()));
        console.log(string.concat("- Symbol: ", token.symbol()));
        console.log(
            string.concat("- Decimals: ", vm.toString(token.decimals()))
        );
        console.log(
            string.concat(
                "- Total Supply: ",
                vm.toString(token.totalSupply() / 10 ** 18)
            )
        );
        console.log(string.concat("- Owner: ", vm.toString(d.deployer)));
        console.log("");

        console.log("Implementation Contracts:");
        console.log(
            string.concat(
                "- DiamondCutFacet: ",
                vm.toString(address(d.cutFacet))
            )
        );
        console.log(
            string.concat(
                "- DiamondLoupeFacet: ",
                vm.toString(address(d.loupeFacet))
            )
        );
        console.log(
            string.concat(
                "- OwnershipFacet: ",
                vm.toString(address(d.ownershipFacet))
            )
        );
        console.log(
            string.concat("- ERC20Facet: ", vm.toString(address(d.erc20Facet)))
        );
        console.log(
            string.concat(
                "- ERC20InitFacet: ",
                vm.toString(address(d.initFacet))
            )
        );
        console.log(
            string.concat(
                "- ERC20MintableFacet: ",
                vm.toString(address(d.mintFacet))
            )
        );
        console.log(
            string.concat(
                "- ERC20BurnableFacet: ",
                vm.toString(address(d.burnFacet))
            )
        );
        console.log("");

        string memory etherscanUrl = _getEtherscanUrl(d.chainId);
        if (bytes(etherscanUrl).length > 0) {
            console.log("View on Etherscan:");
            console.log(
                string.concat(etherscanUrl, vm.toString(address(d.diamond)))
            );
            console.log("");
        }
    }

    function _printVerificationCommands(Deployment memory d) internal view {
        console.log("=== VERIFICATION COMMANDS ===");
        console.log("");
        console.log("Copy and run these commands to verify on Etherscan:");
        console.log("");

        string memory chainId = vm.toString(d.chainId);

        console.log("# Verify Diamond (Main Contract)");
        console.log(
            string.concat(
                "forge verify-contract ",
                vm.toString(address(d.diamond)),
                " src/Diamond.sol:Diamond --chain ",
                chainId,
                ' --constructor-args $(cast abi-encode "constructor(address,address)" ',
                vm.toString(d.deployer),
                " ",
                vm.toString(address(d.cutFacet)),
                ")"
            )
        );
        console.log("");

        console.log("# Verify DiamondCutFacet");
        console.log(
            string.concat(
                "forge verify-contract ",
                vm.toString(address(d.cutFacet)),
                " src/facets/DiamondCutFacet.sol:DiamondCutFacet --chain ",
                chainId
            )
        );
        console.log("");

        console.log("# Verify DiamondLoupeFacet");
        console.log(
            string.concat(
                "forge verify-contract ",
                vm.toString(address(d.loupeFacet)),
                " src/facets/DiamondLoupeFacet.sol:DiamondLoupeFacet --chain ",
                chainId
            )
        );
        console.log("");

        console.log("# Verify OwnershipFacet");
        console.log(
            string.concat(
                "forge verify-contract ",
                vm.toString(address(d.ownershipFacet)),
                " src/facets/OwnershipFacet.sol:OwnershipFacet --chain ",
                chainId
            )
        );
        console.log("");

        console.log("# Verify ERC20Facet");
        console.log(
            string.concat(
                "forge verify-contract ",
                vm.toString(address(d.erc20Facet)),
                " src/facets/ERC20Facet.sol:ERC20Facet --chain ",
                chainId
            )
        );
        console.log("");

        console.log("# Verify ERC20InitFacet");
        console.log(
            string.concat(
                "forge verify-contract ",
                vm.toString(address(d.initFacet)),
                " src/facets/ERC20InitFacet.sol:ERC20InitFacet --chain ",
                chainId
            )
        );
        console.log("");

        console.log("# Verify ERC20MintableFacet");
        console.log(
            string.concat(
                "forge verify-contract ",
                vm.toString(address(d.mintFacet)),
                " src/facets/ERC20MintableFacet.sol:ERC20MintableFacet --chain ",
                chainId
            )
        );
        console.log("");

        console.log("# Verify ERC20BurnableFacet");
        console.log(
            string.concat(
                "forge verify-contract ",
                vm.toString(address(d.burnFacet)),
                " src/facets/ERC20BurnableFacet.sol:ERC20BurnableFacet --chain ",
                chainId
            )
        );
        console.log("");
    }

    function _printInteractionGuide(Deployment memory d) internal view {
        console.log("=== HOW TO INTERACT ===");
        console.log("");
        console.log("1. ADD TOKEN TO WALLET:");
        console.log("   - Contract Address: %s", address(d.diamond));
        console.log("   - Symbol: DMD");
        console.log("   - Decimals: 18");
        console.log("");

        console.log("2. INTERACT VIA CAST COMMANDS:");
        console.log("");
        console.log("   # Check balance");
        console.log(
            string.concat(
                "   cast call ",
                vm.toString(address(d.diamond)),
                ' "balanceOf(address)(uint256)" YOUR_ADDRESS --rpc-url $RPC_URL'
            )
        );
        console.log("");
        console.log("   # Transfer tokens");
        console.log(
            string.concat(
                "   cast send ",
                vm.toString(address(d.diamond)),
                ' "transfer(address,uint256)(bool)" RECIPIENT_ADDRESS AMOUNT --private-key $PRIVATE_KEY --rpc-url $RPC_URL'
            )
        );
        console.log("");
        console.log("   # Mint tokens (anyone can mint)");
        console.log(
            string.concat(
                "   cast send ",
                vm.toString(address(d.diamond)),
                ' "mint(address,uint256)" RECIPIENT_ADDRESS AMOUNT --private-key $PRIVATE_KEY --rpc-url $RPC_URL'
            )
        );
        console.log("");
        console.log("   # Burn tokens");
        console.log(
            string.concat(
                "   cast send ",
                vm.toString(address(d.diamond)),
                ' "burn(uint256)" AMOUNT --private-key $PRIVATE_KEY --rpc-url $RPC_URL'
            )
        );
        console.log("");

        console.log("3. INTERACT VIA ETHERSCAN:");
        string memory etherscanUrl = _getEtherscanUrl(d.chainId);
        if (bytes(etherscanUrl).length > 0) {
            console.log(
                string.concat(
                    "   - Go to: ",
                    etherscanUrl,
                    vm.toString(address(d.diamond))
                )
            );
            console.log("   - Click 'Contract' tab");
            console.log(
                "   - Use 'Read Contract' and 'Write Contract' sections"
            );
        }
        console.log("");

        console.log("IMPORTANT: Always use the DIAMOND ADDRESS above!");
        console.log("The facet addresses are implementation contracts only.");
        console.log("");
        console.log("=====================================");
    }

    function _getNetworkName(
        uint256 chainId
    ) internal pure returns (string memory) {
        if (chainId == 1) return "Ethereum Mainnet";
        if (chainId == 11155111) return "Sepolia Testnet";
        if (chainId == 5) return "Goerli Testnet";
        if (chainId == 137) return "Polygon Mainnet";
        if (chainId == 80001) return "Polygon Mumbai";
        if (chainId == 56) return "BSC Mainnet";
        if (chainId == 97) return "BSC Testnet";
        if (chainId == 43114) return "Avalanche Mainnet";
        if (chainId == 43113) return "Avalanche Fuji";
        if (chainId == 4202) return "Lisk Sepolia Testnet";
        if (chainId == 31337) return "Local Hardhat/Anvil";
        return "Unknown Network";
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
        if (chainId == 4202)
            return "https://sepolia-blockscout.lisk.com/address/";
        return "";
    }
}
