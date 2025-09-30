// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Diamond} from "../src/Diamond.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";
import {ERC20Facet} from "../src/facets/ERC20Facet.sol";
import {ERC20InitFacet} from "../src/facets/ERC20InitFacet.sol";
import {ERC20MetadataFacet} from "../src/facets/ERC20MetadataFacet.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";

contract MetadataFacetTest is Test {
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    OwnershipFacet ownershipFacet;
    ERC20Facet erc20Facet;
    ERC20InitFacet erc20InitFacet;
    ERC20MetadataFacet erc20MetadataFacet;

    address owner = address(this);
    address user1 = address(0x1);

    // Helper function to convert address to payable ERC20MetadataFacet
    function metadataFacet() internal view returns (ERC20MetadataFacet) {
        return ERC20MetadataFacet(payable(address(diamond)));
    }

    function setUp() public {
        // Deploy all facets
        diamondCutFacet = new DiamondCutFacet();
        diamondLoupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();
        erc20Facet = new ERC20Facet();
        erc20InitFacet = new ERC20InitFacet();
        erc20MetadataFacet = new ERC20MetadataFacet();

        // Deploy Diamond
        diamond = new Diamond(owner, address(diamondCutFacet));

        // Build cut struct for all facets
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](5);

        // DiamondLoupe
        bytes4[] memory loupeSelectors = new bytes4[](5);
        loupeSelectors[0] = DiamondLoupeFacet.facets.selector;
        loupeSelectors[1] = DiamondLoupeFacet.facetFunctionSelectors.selector;
        loupeSelectors[2] = DiamondLoupeFacet.facetAddresses.selector;
        loupeSelectors[3] = DiamondLoupeFacet.facetAddress.selector;
        loupeSelectors[4] = DiamondLoupeFacet.supportsInterface.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: address(diamondLoupeFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: loupeSelectors
        });

        // Ownership
        bytes4[] memory ownershipSelectors = new bytes4[](2);
        ownershipSelectors[0] = OwnershipFacet.transferOwnership.selector;
        ownershipSelectors[1] = OwnershipFacet.owner.selector;
        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(ownershipFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: ownershipSelectors
        });

        // ERC20
        bytes4[] memory erc20Selectors = new bytes4[](9);
        erc20Selectors[0] = ERC20Facet.name.selector;
        erc20Selectors[1] = ERC20Facet.symbol.selector;
        erc20Selectors[2] = ERC20Facet.decimals.selector;
        erc20Selectors[3] = ERC20Facet.totalSupply.selector;
        erc20Selectors[4] = ERC20Facet.balanceOf.selector;
        erc20Selectors[5] = ERC20Facet.transfer.selector;
        erc20Selectors[6] = ERC20Facet.allowance.selector;
        erc20Selectors[7] = ERC20Facet.approve.selector;
        erc20Selectors[8] = ERC20Facet.transferFrom.selector;
        cut[2] = IDiamondCut.FacetCut({
            facetAddress: address(erc20Facet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: erc20Selectors
        });

        // ERC20Init
        bytes4[] memory initSelectors = new bytes4[](1);
        initSelectors[0] = ERC20InitFacet.init.selector;
        cut[3] = IDiamondCut.FacetCut({
            facetAddress: address(erc20InitFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: initSelectors
        });

        // ERC20Metadata
        bytes4[] memory metadataSelectors = new bytes4[](11);
        metadataSelectors[0] = ERC20MetadataFacet.tokenURI.selector;
        metadataSelectors[1] = ERC20MetadataFacet.logoSVG.selector;
        metadataSelectors[2] = ERC20MetadataFacet.description.selector;
        metadataSelectors[3] = ERC20MetadataFacet.website.selector;
        metadataSelectors[4] = ERC20MetadataFacet.twitter.selector;
        metadataSelectors[5] = ERC20MetadataFacet.setDescription.selector;
        metadataSelectors[6] = ERC20MetadataFacet.setWebsite.selector;
        metadataSelectors[7] = ERC20MetadataFacet.setTwitter.selector;
        metadataSelectors[8] = ERC20MetadataFacet.setCustomLogo.selector;
        metadataSelectors[9] = ERC20MetadataFacet.resetToDefaultLogo.selector;
        metadataSelectors[10] = ERC20MetadataFacet.initializeMetadata.selector;
        cut[4] = IDiamondCut.FacetCut({
            facetAddress: address(erc20MetadataFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: metadataSelectors
        });

        // Execute diamondCut with init
        bytes memory initCalldata = abi.encodeWithSelector(
            ERC20InitFacet.init.selector,
            "Test Diamond Token",
            "TDT",
            18,
            1000000 * 10**18
        );

        IDiamondCut(address(diamond)).diamondCut(cut, address(erc20InitFacet), initCalldata);

        // Initialize metadata
        metadataFacet().initializeMetadata(
            "Test Token Description",
            "https://test.com",
            "@testtoken"
        );
    }

    function testMetadataInitialization() public view {
        assertEq(metadataFacet().description(), "Test Token Description");
        assertEq(metadataFacet().website(), "https://test.com");
        assertEq(metadataFacet().twitter(), "@testtoken");
    }

    function testLogoSVGGeneration() public view {
        string memory logo = metadataFacet().logoSVG();

        // Check that logo contains expected SVG elements
        assertTrue(bytes(logo).length > 0);
        assertTrue(contains(logo, "<svg"));
        assertTrue(contains(logo, "TDT")); // Token symbol should be in logo
        assertTrue(contains(logo, "</svg>"));
    }

    function testTokenURIGeneration() public view {
        string memory tokenURI = metadataFacet().tokenURI();

        // Check that tokenURI is base64 encoded JSON
        assertTrue(bytes(tokenURI).length > 0);
        assertTrue(contains(tokenURI, "data:application/json;base64,"));
    }

    function testSetDescription() public {
        string memory newDesc = "Updated description";
        metadataFacet().setDescription(newDesc);
        assertEq(metadataFacet().description(), newDesc);
    }

    function testSetWebsite() public {
        string memory newWebsite = "https://newsite.com";
        metadataFacet().setWebsite(newWebsite);
        assertEq(metadataFacet().website(), newWebsite);
    }

    function testSetTwitter() public {
        string memory newTwitter = "@newhandle";
        metadataFacet().setTwitter(newTwitter);
        assertEq(metadataFacet().twitter(), newTwitter);
    }

    function testSetCustomLogo() public {
        string memory customSVG = '<svg><circle cx="50" cy="50" r="40"/></svg>';
        metadataFacet().setCustomLogo(customSVG);

        string memory logo = metadataFacet().logoSVG();
        assertEq(logo, customSVG);
    }

    function testResetToDefaultLogo() public {
        // First set a custom logo
        string memory customSVG = '<svg><circle cx="50" cy="50" r="40"/></svg>';
        metadataFacet().setCustomLogo(customSVG);
        assertEq(metadataFacet().logoSVG(), customSVG);

        // Reset to default
        metadataFacet().resetToDefaultLogo();
        string memory logo = metadataFacet().logoSVG();
        assertNotEq(logo, customSVG);
        assertTrue(contains(logo, "TDT")); // Should contain token symbol again
    }

    function testOnlyOwnerCanUpdateMetadata() public {
        vm.prank(user1);
        vm.expectRevert("LibDiamond: Must be contract owner");
        metadataFacet().setDescription("Unauthorized update");

        vm.prank(user1);
        vm.expectRevert("LibDiamond: Must be contract owner");
        metadataFacet().setWebsite("https://unauthorized.com");

        vm.prank(user1);
        vm.expectRevert("LibDiamond: Must be contract owner");
        metadataFacet().setTwitter("@unauthorized");

        vm.prank(user1);
        vm.expectRevert("LibDiamond: Must be contract owner");
        metadataFacet().setCustomLogo("<svg></svg>");
    }

    function testMetadataInTokenURI() public view {
        string memory tokenURI = metadataFacet().tokenURI();

        // The tokenURI should be a data URI with base64 encoded JSON
        // We can't easily decode it in Solidity, but we can check the format
        assertTrue(bytes(tokenURI).length > 50); // Should be substantial
        assertTrue(contains(tokenURI, "data:application/json;base64,"));
    }

    // Helper function to check if a string contains a substring
    function contains(string memory str, string memory substr) internal pure returns (bool) {
        bytes memory strBytes = bytes(str);
        bytes memory substrBytes = bytes(substr);

        if (substrBytes.length > strBytes.length) {
            return false;
        }

        for (uint256 i = 0; i <= strBytes.length - substrBytes.length; i++) {
            bool found = true;
            for (uint256 j = 0; j < substrBytes.length; j++) {
                if (strBytes[i + j] != substrBytes[j]) {
                    found = false;
                    break;
                }
            }
            if (found) {
                return true;
            }
        }
        return false;
    }
}