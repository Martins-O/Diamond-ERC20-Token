// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/Diamond.sol";
import "../src/facets/DiamondCutFacet.sol";
import "../src/facets/DiamondLoupeFacet.sol";
import "../src/facets/OwnershipFacet.sol";
import "../src/facets/ERC20Facet.sol";
import "../src/facets/ERC20MintableFacet.sol";
import "../src/facets/ERC20SwapFacet.sol";
import "../src/facets/ERC20MetadataFacet.sol";
import "../src/facets/MultisigFacet.sol";
import "../src/libraries/LibDiamond.sol";

contract DeployAllFacetsScript is Script {
    address constant DIAMOND_ADDRESS =
        0x400BCC394190117FF7e3Bd8b69d16c9C66Fe6E07;

    function run() external {
        vm.startBroadcast();

        // Deploy new facets
        ERC20MintableFacet mintableFacet = new ERC20MintableFacet();
        ERC20SwapFacet swapFacet = new ERC20SwapFacet();
        ERC20MetadataFacet metadataFacet = new ERC20MetadataFacet();
        MultisigFacet multisigFacet = new MultisigFacet();

        console.log("Deployed ERC20MintableFacet:", address(mintableFacet));
        console.log("Deployed ERC20SwapFacet:", address(swapFacet));
        console.log("Deployed ERC20MetadataFacet:", address(metadataFacet));
        console.log("Deployed MultisigFacet:", address(multisigFacet));

        // Get the diamond cut facet
        IDiamondCut diamondCut = IDiamondCut(DIAMOND_ADDRESS);

        // Prepare function selectors for each facet
        bytes4[] memory mintableSelectors = new bytes4[](1);
        mintableSelectors[0] = ERC20MintableFacet.mint.selector;

        bytes4[] memory swapSelectors = new bytes4[](20);
        swapSelectors[0] = ERC20SwapFacet.swapETHForTokens.selector;
        swapSelectors[1] = ERC20SwapFacet.swapTokensForETH.selector;
        swapSelectors[2] = ERC20SwapFacet.swapERC20ForTokens.selector;
        swapSelectors[3] = ERC20SwapFacet.swapTokensForERC20.selector;
        swapSelectors[4] = ERC20SwapFacet.getETHToTokenRate.selector;
        swapSelectors[5] = ERC20SwapFacet.getTokenToETHRate.selector;
        swapSelectors[6] = ERC20SwapFacet.getERC20ToTokenRate.selector;
        swapSelectors[7] = ERC20SwapFacet.getTokenToERC20Rate.selector;
        swapSelectors[8] = ERC20SwapFacet.getETHBalance.selector;
        swapSelectors[9] = ERC20SwapFacet.getTokenBalance.selector;
        swapSelectors[10] = ERC20SwapFacet.getSupportedTokens.selector;
        swapSelectors[11] = ERC20SwapFacet.getSwapFee.selector;
        swapSelectors[12] = ERC20SwapFacet.getFeeRecipient.selector;
        swapSelectors[13] = ERC20SwapFacet.setETHRate.selector;
        swapSelectors[14] = ERC20SwapFacet.setERC20Rate.selector;
        swapSelectors[15] = ERC20SwapFacet.removeSupportedToken.selector;
        swapSelectors[16] = ERC20SwapFacet.setSwapFee.selector;
        swapSelectors[17] = ERC20SwapFacet.setFeeRecipient.selector;
        swapSelectors[18] = ERC20SwapFacet.addLiquidity.selector;
        swapSelectors[19] = ERC20SwapFacet.removeLiquidity.selector;

        bytes4[] memory metadataSelectors = new bytes4[](10);
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

        bytes4[] memory multisigSelectors = new bytes4[](30);
        multisigSelectors[0] = MultisigFacet.initializeMultisig.selector;
        multisigSelectors[1] = MultisigFacet.addOwner.selector;
        multisigSelectors[2] = MultisigFacet.removeOwner.selector;
        multisigSelectors[3] = MultisigFacet.replaceOwner.selector;
        multisigSelectors[4] = MultisigFacet.changeRequirement.selector;
        multisigSelectors[5] = MultisigFacet.addOwnerWithThreshold.selector;
        multisigSelectors[6] = MultisigFacet.removeOwnerWithThreshold.selector;
        multisigSelectors[7] = MultisigFacet.submitTransaction.selector;
        multisigSelectors[8] = MultisigFacet.confirmTransaction.selector;
        multisigSelectors[9] = MultisigFacet.revokeConfirmation.selector;
        multisigSelectors[10] = MultisigFacet.executeTransaction.selector;
        multisigSelectors[11] = MultisigFacet
            .confirmMultipleTransactions
            .selector;
        multisigSelectors[12] = MultisigFacet
            .executeMultipleTransactions
            .selector;
        multisigSelectors[13] = MultisigFacet.getOwners.selector;
        multisigSelectors[14] = MultisigFacet.getOwnerDetails.selector;
        multisigSelectors[15] = MultisigFacet.isOwner.selector;
        multisigSelectors[16] = MultisigFacet.getRequired.selector;
        multisigSelectors[17] = MultisigFacet.getTransactionCount.selector;
        multisigSelectors[18] = MultisigFacet
            .getPendingTransactionCount
            .selector;
        multisigSelectors[19] = MultisigFacet
            .getExecutedTransactionCount
            .selector;
        multisigSelectors[20] = MultisigFacet.getTransaction.selector;
        multisigSelectors[21] = MultisigFacet
            .getTransactionConfirmations
            .selector;
        multisigSelectors[22] = MultisigFacet.isConfirmedBy.selector;
        multisigSelectors[23] = MultisigFacet.isExecutable.selector;
        multisigSelectors[24] = MultisigFacet.getTransactions.selector;
        multisigSelectors[25] = MultisigFacet.getTransactionIds.selector;
        multisigSelectors[26] = MultisigFacet.pause.selector;
        multisigSelectors[27] = MultisigFacet.unpause.selector;
        multisigSelectors[28] = MultisigFacet.isPaused.selector;
        multisigSelectors[29] = MultisigFacet.getTransactionHistory.selector;

        // Prepare diamond cuts
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](4);

        // Replace mintable facet
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(mintableFacet),
            action: IDiamondCut.FacetCutAction.Replace,
            functionSelectors: mintableSelectors
        });

        // Add swap facet
        cuts[1] = IDiamondCut.FacetCut({
            facetAddress: address(swapFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: swapSelectors
        });

        // Add metadata facet
        cuts[2] = IDiamondCut.FacetCut({
            facetAddress: address(metadataFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: metadataSelectors
        });

        // Add multisig facet
        cuts[3] = IDiamondCut.FacetCut({
            facetAddress: address(multisigFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: multisigSelectors
        });

        // Execute diamond cut
        diamondCut.diamondCut(cuts, address(0), "");

        console.log("Diamond upgraded successfully!");
        console.log("Diamond address:", DIAMOND_ADDRESS);

        vm.stopBroadcast();
    }
}
