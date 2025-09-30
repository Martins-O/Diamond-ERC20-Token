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
import {ERC20SwapFacet} from "../src/facets/ERC20SwapFacet.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {IERC20} from "../src/interfaces/IERC20.sol";

contract SwapFacetTest is Test {
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    OwnershipFacet ownershipFacet;
    ERC20Facet erc20Facet;
    ERC20InitFacet erc20InitFacet;
    ERC20MintableFacet erc20MintableFacet;
    ERC20BurnableFacet erc20BurnableFacet;
    ERC20SwapFacet erc20SwapFacet;

    address owner = address(this);
    address user1 = address(0x1);
    address user2 = address(0x2);

    // Helper function to convert address to payable ERC20SwapFacet
    function swapFacet() internal view returns (ERC20SwapFacet) {
        return ERC20SwapFacet(payable(address(diamond)));
    }

    function setUp() public {
        // Deploy all facets
        diamondCutFacet = new DiamondCutFacet();
        diamondLoupeFacet = new DiamondLoupeFacet();
        ownershipFacet = new OwnershipFacet();
        erc20Facet = new ERC20Facet();
        erc20InitFacet = new ERC20InitFacet();
        erc20MintableFacet = new ERC20MintableFacet();
        erc20BurnableFacet = new ERC20BurnableFacet();
        erc20SwapFacet = new ERC20SwapFacet();

        // Deploy Diamond
        diamond = new Diamond(owner, address(diamondCutFacet));

        // Build cut struct for all facets
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](7);

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

        // ERC20Swap
        bytes4[] memory swapSelectors = new bytes4[](17);
        swapSelectors[0] = ERC20SwapFacet.swapETHForTokens.selector;
        swapSelectors[1] = ERC20SwapFacet.swapTokensForETH.selector;
        swapSelectors[2] = ERC20SwapFacet.getETHToTokenRate.selector;
        swapSelectors[3] = ERC20SwapFacet.getTokenToETHRate.selector;
        swapSelectors[4] = ERC20SwapFacet.getETHBalance.selector;
        swapSelectors[5] = ERC20SwapFacet.getTokenBalance.selector;
        swapSelectors[6] = ERC20SwapFacet.getSwapFee.selector;
        swapSelectors[7] = ERC20SwapFacet.getFeeRecipient.selector;
        swapSelectors[8] = ERC20SwapFacet.setETHRate.selector;
        swapSelectors[9] = ERC20SwapFacet.setSwapFee.selector;
        swapSelectors[10] = ERC20SwapFacet.setFeeRecipient.selector;
        swapSelectors[11] = ERC20SwapFacet.addLiquidity.selector;
        swapSelectors[12] = ERC20SwapFacet.removeLiquidity.selector;
        swapSelectors[13] = ERC20SwapFacet.initializeSwap.selector;
        swapSelectors[14] = ERC20SwapFacet.swapERC20ForTokens.selector;
        swapSelectors[15] = ERC20SwapFacet.swapTokensForERC20.selector;
        swapSelectors[16] = ERC20SwapFacet.getSupportedTokens.selector;
        cut[6] = IDiamondCut.FacetCut({
            facetAddress: address(erc20SwapFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: swapSelectors
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

        // Initialize swap functionality
        swapFacet().initializeSwap(
            1000 * 1e18,  // 1000 tokens per 1 ETH
            100           // 1% swap fee
        );

        // Add initial liquidity
        deal(address(this), 10 ether);
        swapFacet().addLiquidity{value: 5 ether}();
    }

    function testSwapInitialization() public view {
        assertEq(swapFacet().getETHToTokenRate(), 1000 * 1e18);
        assertEq(swapFacet().getSwapFee(), 100);
        assertEq(swapFacet().getFeeRecipient(), owner);
    }

    function testSwapETHForTokens() public {
        uint256 ethAmount = 1 ether;
        uint256 expectedTokens = 1000 * 1e18; // 1000 tokens per ETH
        uint256 fee = (expectedTokens * 100) / 10000; // 1% fee
        uint256 expectedAfterFee = expectedTokens - fee;

        deal(user1, ethAmount);

        vm.prank(user1);
        uint256 actualTokens = swapFacet().swapETHForTokens{value: ethAmount}();

        assertEq(actualTokens, expectedAfterFee);
        assertEq(IERC20(address(diamond)).balanceOf(user1), expectedAfterFee);
        assertEq(address(diamond).balance, 5 ether + ethAmount);
    }

    function testSwapTokensForETH() public {
        // First buy some tokens
        uint256 ethAmount = 1 ether;
        deal(user1, ethAmount);

        vm.prank(user1);
        uint256 tokenAmount = swapFacet().swapETHForTokens{value: ethAmount}();

        // Now swap tokens back for ETH
        uint256 ethBalanceBefore = user1.balance;

        vm.prank(user1);
        uint256 ethReceived = swapFacet().swapTokensForETH(tokenAmount);

        assertGt(ethReceived, 0);
        assertEq(user1.balance, ethBalanceBefore + ethReceived);
        assertEq(IERC20(address(diamond)).balanceOf(user1), 0);
    }

    function testCannotSwapWithZeroETH() public {
        vm.prank(user1);
        vm.expectRevert("Must send ETH");
        swapFacet().swapETHForTokens{value: 0}();
    }

    function testCannotSwapWithZeroTokens() public {
        vm.prank(user1);
        vm.expectRevert("Must specify token amount");
        swapFacet().swapTokensForETH(0);
    }

    function testOnlyOwnerCanSetRates() public {
        vm.prank(user1);
        vm.expectRevert("LibDiamond: Must be contract owner");
        swapFacet().setETHRate(2000 * 1e18);
    }

    function testOwnerCanSetRates() public {
        uint256 newRate = 2000 * 1e18;
        swapFacet().setETHRate(newRate);
        assertEq(swapFacet().getETHToTokenRate(), newRate);
    }

    function testAddLiquidity() public {
        uint256 liquidityBefore = swapFacet().getETHBalance();
        uint256 addAmount = 1 ether;

        swapFacet().addLiquidity{value: addAmount}();

        uint256 liquidityAfter = swapFacet().getETHBalance();
        assertEq(liquidityAfter, liquidityBefore + addAmount);
    }

    function testRemoveLiquidity() public {
        uint256 liquidityBefore = swapFacet().getETHBalance();
        uint256 removeAmount = 1 ether;

        swapFacet().removeLiquidity(removeAmount);

        uint256 liquidityAfter = swapFacet().getETHBalance();
        assertEq(liquidityAfter, liquidityBefore - removeAmount);
    }

    function testGetRates() public view {
        uint256 ethToToken = swapFacet().getETHToTokenRate();
        uint256 tokenToEth = swapFacet().getTokenToETHRate();

        assertEq(ethToToken, 1000 * 1e18);
        assertGt(tokenToEth, 0);
    }

    receive() external payable {}
}