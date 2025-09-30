// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Diamond} from "../src/Diamond.sol";
import {DiamondCutFacet} from "../src/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../src/facets/DiamondLoupeFacet.sol";
import {MultisigFacet} from "../src/facets/MultisigFacet.sol";
import {IDiamondCut} from "../src/interfaces/IDiamondCut.sol";
import {IMultisig} from "../src/interfaces/IMultisig.sol";

contract MultisigFacetTest is Test {
    Diamond diamond;
    DiamondCutFacet diamondCutFacet;
    DiamondLoupeFacet diamondLoupeFacet;
    MultisigFacet multisigFacet;

    address owner1 = address(0x1);
    address owner2 = address(0x2);
    address owner3 = address(0x3);
    address owner4 = address(0x4);
    address nonOwner = address(0x999);

    // Helper function to convert address to payable MultisigFacet
    function msig() internal view returns (MultisigFacet) {
        return MultisigFacet(payable(address(diamond)));
    }

    function setUp() public {
        // Deploy all facets
        diamondCutFacet = new DiamondCutFacet();
        diamondLoupeFacet = new DiamondLoupeFacet();
        multisigFacet = new MultisigFacet();

        // Deploy Diamond
        diamond = new Diamond(address(this), address(diamondCutFacet));

        // Build cut struct for facets
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](2);

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

        // Multisig
        bytes4[] memory multisigSelectors = new bytes4[](31);
        multisigSelectors[0] = MultisigFacet.initializeMultisig.selector;
        multisigSelectors[1] = MultisigFacet.addOwner.selector;
        multisigSelectors[2] = MultisigFacet.removeOwner.selector;
        multisigSelectors[3] = MultisigFacet.replaceOwner.selector;
        multisigSelectors[4] = MultisigFacet.changeRequirement.selector;
        multisigSelectors[5] = MultisigFacet.submitTransaction.selector;
        multisigSelectors[6] = MultisigFacet.confirmTransaction.selector;
        multisigSelectors[7] = MultisigFacet.revokeConfirmation.selector;
        multisigSelectors[8] = MultisigFacet.executeTransaction.selector;
        multisigSelectors[9] = MultisigFacet.confirmMultipleTransactions.selector;
        multisigSelectors[10] = MultisigFacet.executeMultipleTransactions.selector;
        multisigSelectors[11] = MultisigFacet.getOwners.selector;
        multisigSelectors[12] = MultisigFacet.getOwnerDetails.selector;
        multisigSelectors[13] = MultisigFacet.isOwner.selector;
        multisigSelectors[14] = MultisigFacet.getRequired.selector;
        multisigSelectors[15] = MultisigFacet.getTransactionCount.selector;
        multisigSelectors[16] = MultisigFacet.getPendingTransactionCount.selector;
        multisigSelectors[17] = MultisigFacet.getExecutedTransactionCount.selector;
        multisigSelectors[18] = MultisigFacet.getTransaction.selector;
        multisigSelectors[19] = MultisigFacet.getTransactionConfirmations.selector;
        multisigSelectors[20] = MultisigFacet.isConfirmedBy.selector;
        multisigSelectors[21] = MultisigFacet.isExecutable.selector;
        multisigSelectors[22] = MultisigFacet.getTransactions.selector;
        multisigSelectors[23] = MultisigFacet.getTransactionIds.selector;
        multisigSelectors[24] = MultisigFacet.pause.selector;
        multisigSelectors[25] = MultisigFacet.unpause.selector;
        multisigSelectors[26] = MultisigFacet.isPaused.selector;
        multisigSelectors[27] = MultisigFacet.addOwnerWithThreshold.selector;
        multisigSelectors[28] = MultisigFacet.removeOwnerWithThreshold.selector;
        multisigSelectors[29] = MultisigFacet.getTransactionHistory.selector;
        multisigSelectors[30] = MultisigFacet.getOwnerStats.selector;

        cut[1] = IDiamondCut.FacetCut({
            facetAddress: address(multisigFacet),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: multisigSelectors
        });

        IDiamondCut(address(diamond)).diamondCut(cut, address(0), "");

        // Initialize multisig with 3 owners, requiring 2 confirmations
        address[] memory owners = new address[](3);
        string[] memory names = new string[](3);
        owners[0] = owner1;
        owners[1] = owner2;
        owners[2] = owner3;
        names[0] = "Owner 1";
        names[1] = "Owner 2";
        names[2] = "Owner 3";

        msig().initializeMultisig(owners, names, 2);

        // Fund the diamond with some ETH for testing
        deal(address(diamond), 10 ether);
    }

    function testInitialization() public view {
        address[] memory owners = msig().getOwners();
        assertEq(owners.length, 3);
        assertEq(owners[0], owner1);
        assertEq(owners[1], owner2);
        assertEq(owners[2], owner3);
        assertEq(msig().getRequired(), 2);

        assertTrue(msig().isOwner(owner1));
        assertTrue(msig().isOwner(owner2));
        assertTrue(msig().isOwner(owner3));
        assertFalse(msig().isOwner(nonOwner));
    }

    function testCannotInitializeTwice() public {
        address[] memory owners = new address[](1);
        string[] memory names = new string[](1);
        owners[0] = owner4;
        names[0] = "Owner 4";

        vm.expectRevert("Multisig: Already initialized");
        msig().initializeMultisig(owners, names, 1);
    }

    function testSubmitTransaction() public {
        vm.prank(owner1);
        uint256 txId = msig().submitTransaction(
            address(0x123),
            1 ether,
            "",
            "Test transaction"
        );

        assertEq(txId, 0);
        assertEq(msig().getTransactionCount(), 1);
        assertEq(msig().getPendingTransactionCount(), 1);
        assertEq(msig().getExecutedTransactionCount(), 0);

        IMultisig.Transaction memory txn = msig().getTransaction(txId);
        assertEq(txn.to, address(0x123));
        assertEq(txn.value, 1 ether);
        assertEq(txn.confirmations, 1); // Auto-confirmed by submitter
        assertFalse(txn.executed);
    }

    function testConfirmTransaction() public {
        vm.prank(owner1);
        uint256 txId = msig().submitTransaction(address(0x123), 1 ether, "", "Test");

        // Confirm with owner2
        vm.prank(owner2);
        msig().confirmTransaction(txId);

        IMultisig.Transaction memory txn = msig().getTransaction(txId);
        assertEq(txn.confirmations, 2); // owner1 (auto) + owner2
        assertTrue(msig().isExecutable(txId));
        assertTrue(msig().isConfirmedBy(txId, owner1));
        assertTrue(msig().isConfirmedBy(txId, owner2));
        assertFalse(msig().isConfirmedBy(txId, owner3));
    }

    function testExecuteTransaction() public {
        address recipient = address(0x123);
        uint256 initialBalance = recipient.balance;

        vm.prank(owner1);
        uint256 txId = msig().submitTransaction(recipient, 1 ether, "", "Send ETH");

        vm.prank(owner2);
        msig().confirmTransaction(txId);

        vm.prank(owner3);
        msig().executeTransaction(txId);

        IMultisig.Transaction memory txn = msig().getTransaction(txId);
        assertTrue(txn.executed);
        assertEq(recipient.balance, initialBalance + 1 ether);
        assertEq(msig().getExecutedTransactionCount(), 1);
        assertEq(msig().getPendingTransactionCount(), 0);
    }

    function testRevokeConfirmation() public {
        vm.prank(owner1);
        uint256 txId = msig().submitTransaction(address(0x123), 1 ether, "", "Test");

        vm.prank(owner2);
        msig().confirmTransaction(txId);

        assertTrue(msig().isExecutable(txId));

        // Revoke confirmation
        vm.prank(owner2);
        msig().revokeConfirmation(txId);

        IMultisig.Transaction memory txn = msig().getTransaction(txId);
        assertEq(txn.confirmations, 1); // Only owner1 remains
        assertFalse(msig().isExecutable(txId));
        assertFalse(msig().isConfirmedBy(txId, owner2));
    }

    function testCannotExecuteWithoutEnoughConfirmations() public {
        vm.prank(owner1);
        uint256 txId = msig().submitTransaction(address(0x123), 1 ether, "", "Test");

        vm.prank(owner1);
        vm.expectRevert("Multisig: Not enough confirmations");
        msig().executeTransaction(txId);
    }

    function testOnlyOwnersCanInteract() public {
        vm.prank(nonOwner);
        vm.expectRevert("Multisig: Owner does not exist");
        msig().submitTransaction(address(0x123), 1 ether, "", "Test");

        vm.prank(owner1);
        uint256 txId = msig().submitTransaction(address(0x123), 1 ether, "", "Test");

        vm.prank(nonOwner);
        vm.expectRevert("Multisig: Owner does not exist");
        msig().confirmTransaction(txId);
    }

    function testAddOwnerViaMultisig() public {
        // Create transaction to add new owner
        bytes memory data = abi.encodeWithSelector(
            MultisigFacet.addOwner.selector,
            owner4,
            "Owner 4"
        );

        vm.prank(owner1);
        uint256 txId = msig().submitTransaction(address(diamond), 0, data, "Add Owner 4");

        vm.prank(owner2);
        msig().confirmTransaction(txId);

        vm.prank(owner3);
        msig().executeTransaction(txId);

        // Verify owner was added
        assertTrue(msig().isOwner(owner4));
        address[] memory owners = msig().getOwners();
        assertEq(owners.length, 4);
    }

    function testRemoveOwnerViaMultisig() public {
        // Create transaction to remove owner
        bytes memory data = abi.encodeWithSelector(
            MultisigFacet.removeOwner.selector,
            owner3
        );

        vm.prank(owner1);
        uint256 txId = msig().submitTransaction(address(diamond), 0, data, "Remove Owner 3");

        vm.prank(owner2);
        msig().confirmTransaction(txId);

        vm.prank(owner3);
        msig().executeTransaction(txId);

        // Verify owner was removed
        assertFalse(msig().isOwner(owner3));
        address[] memory owners = msig().getOwners();
        assertEq(owners.length, 2);
    }

    function testChangeRequirementViaMultisig() public {
        // Create transaction to change requirement
        bytes memory data = abi.encodeWithSelector(
            MultisigFacet.changeRequirement.selector,
            3
        );

        vm.prank(owner1);
        uint256 txId = msig().submitTransaction(address(diamond), 0, data, "Change requirement to 3");

        vm.prank(owner2);
        msig().confirmTransaction(txId);

        vm.prank(owner3);
        msig().executeTransaction(txId);

        // Verify requirement was changed
        assertEq(msig().getRequired(), 3);
    }

    function testPauseAndUnpause() public {
        assertFalse(msig().isPaused());

        // Create transaction to pause
        bytes memory pauseData = abi.encodeWithSelector(MultisigFacet.pause.selector);

        // Create transaction to unpause (submit before pausing)
        bytes memory unpauseData = abi.encodeWithSelector(MultisigFacet.unpause.selector);

        vm.prank(owner1);
        uint256 pauseTxId = msig().submitTransaction(address(diamond), 0, pauseData, "Pause multisig");

        vm.prank(owner1);
        uint256 unpauseTxId = msig().submitTransaction(address(diamond), 0, unpauseData, "Unpause multisig");

        vm.prank(owner2);
        msig().confirmTransaction(pauseTxId);

        vm.prank(owner3);
        msig().executeTransaction(pauseTxId);

        assertTrue(msig().isPaused());

        // Try to submit transaction while paused - should fail
        vm.prank(owner1);
        vm.expectRevert("Multisig: Contract is paused");
        msig().submitTransaction(address(0x123), 1 ether, "", "Should fail");

        // Confirm and execute unpause transaction (should work even when paused)
        vm.prank(owner2);
        msig().confirmTransaction(unpauseTxId);

        vm.prank(owner3);
        msig().executeTransaction(unpauseTxId);

        assertFalse(msig().isPaused());
    }

    function testBatchOperations() public {
        // Submit multiple transactions
        vm.prank(owner1);
        uint256 txId1 = msig().submitTransaction(address(0x123), 1 ether, "", "TX 1");

        vm.prank(owner1);
        uint256 txId2 = msig().submitTransaction(address(0x456), 2 ether, "", "TX 2");

        vm.prank(owner1);
        uint256 txId3 = msig().submitTransaction(address(0x789), 3 ether, "", "TX 3");

        // Batch confirm
        uint256[] memory txIds = new uint256[](3);
        txIds[0] = txId1;
        txIds[1] = txId2;
        txIds[2] = txId3;

        vm.prank(owner2);
        msig().confirmMultipleTransactions(txIds);

        // Check confirmations before testing executability
        IMultisig.Transaction memory tx1 = msig().getTransaction(txId1);
        IMultisig.Transaction memory tx2 = msig().getTransaction(txId2);
        IMultisig.Transaction memory tx3 = msig().getTransaction(txId3);

        // Each should have 2 confirmations (owner1 auto + owner2 batch)
        assertEq(tx1.confirmations, 2);
        assertEq(tx2.confirmations, 2);
        assertEq(tx3.confirmations, 2);

        // Check all are executable
        assertTrue(msig().isExecutable(txId1));
        assertTrue(msig().isExecutable(txId2));
        assertTrue(msig().isExecutable(txId3));

        // Batch execute
        vm.prank(owner3);
        msig().executeMultipleTransactions(txIds);

        // Check all are executed
        assertTrue(msig().getTransaction(txId1).executed);
        assertTrue(msig().getTransaction(txId2).executed);
        assertTrue(msig().getTransaction(txId3).executed);
    }

    function testOwnerStats() public {
        vm.prank(owner1);
        uint256 txId1 = msig().submitTransaction(address(0x123), 1 ether, "", "TX 1");

        vm.prank(owner2);
        uint256 txId2 = msig().submitTransaction(address(0x456), 2 ether, "", "TX 2");

        vm.prank(owner2);
        msig().confirmTransaction(txId1);

        vm.prank(owner1);
        msig().executeTransaction(txId1);

        (uint256 submitted, uint256 confirmed, uint256 executed) = msig().getOwnerStats(owner1);
        assertEq(submitted, 1); // Submitted TX 1
        assertEq(confirmed, 1);  // Auto-confirmed TX 1
        assertEq(executed, 1);   // Executed TX 1

        (submitted, confirmed, executed) = msig().getOwnerStats(owner2);
        assertEq(submitted, 1); // Submitted TX 2
        assertEq(confirmed, 2); // Auto-confirmed TX 2 + confirmed TX 1
        assertEq(executed, 0);  // Executed none
    }

    function testTransactionHistory() public {
        vm.prank(owner1);
        uint256 txId1 = msig().submitTransaction(address(0x123), 1 ether, "", "TX 1");

        vm.prank(owner1);
        uint256 txId2 = msig().submitTransaction(address(0x456), 2 ether, "", "TX 2");

        uint256[] memory history = msig().getTransactionHistory(owner1);
        assertEq(history.length, 2);
        assertEq(history[0], txId1);
        assertEq(history[1], txId2);

        uint256[] memory emptyHistory = msig().getTransactionHistory(owner3);
        assertEq(emptyHistory.length, 0);
    }

    receive() external payable {}
}