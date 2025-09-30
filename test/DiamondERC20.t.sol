// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Diamond} from "../src/Diamond.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../src/facets/OwnershipFacet.sol";
import {ERC20Facet} from "../src/facets/ERC20Facet.sol";
import {ERC20InitFacet} from "../src/facets/ERC20InitFacet.sol";
import {ERC20MintableFacet} from "../src/facets/ERC20MintableFacet.sol";
import {ERC20BurnableFacet} from "../src/facets/ERC20BurnableFacet.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";

contract DiamondERC20Test is Test {
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    OwnershipFacet ownershipFacet;
    ERC20Facet erc20Facet;
    ERC20InitFacet erc20InitFacet;
    ERC20MintableFacet erc20MintableFacet;
    ERC20BurnableFacet erc20BurnableFacet;
    
    address owner = address(this);
    address user1 = address(0x1);
    address user2 = address(0x2);
    
    function setUp() public {
        // Deploy all facets
        diamondCutFacet = new DiamondCutFacet();
        diamondLoupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();
        erc20Facet = new ERC20Facet();
        erc20InitFacet = new ERC20InitFacet();
        erc20MintableFacet = new ERC20MintableFacet();
        erc20BurnableFacet = new ERC20BurnableFacet();
        
        // Deploy Diamond
        diamond = new Diamond(owner, address(diamondCutFacet));
        
        // Build cut struct
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](6);
        
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
        
        // ERC20Mintable
        bytes4[] memory mintableSelectors = new bytes4[](1);
        mintableSelectors[0] = ERC20MintableFacet.mint.selector;
        cut[4] = IDiamondCut.FacetCut({
            facetAddress: address(erc20MintableFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: mintableSelectors
        });
        
        // ERC20Burnable
        bytes4[] memory burnableSelectors = new bytes4[](2);
        burnableSelectors[0] = ERC20BurnableFacet.burn.selector;
        burnableSelectors[1] = ERC20BurnableFacet.burnFrom.selector;
        cut[5] = IDiamondCut.FacetCut({
            facetAddress: address(erc20BurnableFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: burnableSelectors
        });
        
        // Execute diamondCut with init
        bytes memory initCalldata = abi.encodeWithSelector(
            ERC20InitFacet.init.selector,
            "Diamond Token",
            "DMD",
            18,
            1000000 * 10**18
        );
        
        IDiamondCut(address(diamond)).diamondCut(cut, address(erc20InitFacet), initCalldata);
    }
    
    function testInitialization() public view {
        IERC20 token = IERC20(address(diamond));
        assertEq(token.name(), "Diamond Token");
        assertEq(token.symbol(), "DMD");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), 1000000 * 10**18);
        assertEq(token.balanceOf(owner), 1000000 * 10**18);
    }
    
    function testTransfer() public {
        IERC20 token = IERC20(address(diamond));
        
        uint256 amount = 100 * 10**18;
        bool ok = token.transfer(user1, amount);
        assertTrue(ok);
        
        assertEq(token.balanceOf(user1), amount);
        assertEq(token.balanceOf(owner), 1000000 * 10**18 - amount);
    }
    
    function testApproveAndTransferFrom() public {
        IERC20 token = IERC20(address(diamond));
        
        uint256 amount = 100 * 10**18;
        token.approve(user1, amount);
        
        assertEq(token.allowance(owner, user1), amount);
        
        vm.prank(user1);
        bool ok2 = token.transferFrom(owner, user2, amount);
        assertTrue(ok2);
        
        assertEq(token.balanceOf(user2), amount);
        assertEq(token.allowance(owner, user1), 0);
    }
    
    function testMint() public {
        IERC20 token = IERC20(address(diamond));
        
        uint256 mintAmount = 1000 * 10**18;
        uint256 totalSupplyBefore = token.totalSupply();
        
        ERC20MintableFacet(address(diamond)).mint(user1, mintAmount);
        
        assertEq(token.balanceOf(user1), mintAmount);
        assertEq(token.totalSupply(), totalSupplyBefore + mintAmount);
    }
    
    function testMintByAnyone() public {
        IERC20 token = IERC20(address(diamond));

        uint256 mintAmount = 1000 * 10**18;
        uint256 totalSupplyBefore = token.totalSupply();

        vm.prank(user1);
        ERC20MintableFacet(address(diamond)).mint(user1, mintAmount);

        assertEq(token.balanceOf(user1), mintAmount);
        assertEq(token.totalSupply(), totalSupplyBefore + mintAmount);
    }
    
    function testBurn() public {
        IERC20 token = IERC20(address(diamond));
        
        uint256 burnAmount = 100 * 10**18;
        uint256 balanceBefore = token.balanceOf(owner);
        uint256 totalSupplyBefore = token.totalSupply();
        
        ERC20BurnableFacet(address(diamond)).burn(burnAmount);
        
        assertEq(token.balanceOf(owner), balanceBefore - burnAmount);
        assertEq(token.totalSupply(), totalSupplyBefore - burnAmount);
    }
    
    function testBurnFrom() public {
        IERC20 token = IERC20(address(diamond));
        
        uint256 burnAmount = 100 * 10**18;
        token.approve(user1, burnAmount);
        
        uint256 balanceBefore = token.balanceOf(owner);
        uint256 totalSupplyBefore = token.totalSupply();
        
        vm.prank(user1);
        ERC20BurnableFacet(address(diamond)).burnFrom(owner, burnAmount);
        
        assertEq(token.balanceOf(owner), balanceBefore - burnAmount);
        assertEq(token.totalSupply(), totalSupplyBefore - burnAmount);
        assertEq(token.allowance(owner, user1), 0);
    }
    
    function testOwnership() public {
        OwnershipFacet ownership = OwnershipFacet(address(diamond));
        assertEq(ownership.owner(), owner);
        
        ownership.transferOwnership(user1);
        assertEq(ownership.owner(), user1);
    }
    
    function testDiamondLoupe() public view {
        DiamondLoupeFacet loupe = DiamondLoupeFacet(address(diamond));
        
        address[] memory addresses = loupe.facetAddresses();
        assertTrue(addresses.length > 0);
        
        bytes4[] memory selectors = loupe.facetFunctionSelectors(address(erc20Facet));
        assertEq(selectors.length, 9);
    }
    
    function testCannotTransferMoreThanBalance() public {
        IERC20 token = IERC20(address(diamond));
        uint256 amount = token.balanceOf(owner) + 1;
        vm.expectRevert();
        token.transfer(user1, amount);
    }
    
    function testCannotTransferFromWithoutAllowance() public {
        IERC20 token = IERC20(address(diamond));
        
        vm.prank(user1);
        vm.expectRevert();
        token.transferFrom(owner, user2, 100 * 10**18);
    }
    
    function testCannotBurnMoreThanBalance() public {
        IERC20 token = IERC20(address(diamond));
        uint256 amount = token.balanceOf(owner) + 1;
        vm.expectRevert();
        ERC20BurnableFacet(address(diamond)).burn(amount);
    }
}