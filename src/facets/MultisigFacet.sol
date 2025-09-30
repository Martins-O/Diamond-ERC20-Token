// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibMultisigStorage} from "../libraries/LibMultisigStorage.sol";
import {IMultisig} from "../interfaces/IMultisig.sol";

contract MultisigFacet is IMultisig {
    using LibMultisigStorage for LibMultisigStorage.Storage;

    modifier onlyOwner() {
        LibMultisigStorage.Storage storage s = LibMultisigStorage.getStorage();
        s.validateOwnerExists(msg.sender);
        _;
    }

    modifier notPaused() {
        LibMultisigStorage.Storage storage s = LibMultisigStorage.getStorage();
        s.validateNotPaused();
        _;
    }

    modifier onlyMultisig() {
        require(msg.sender == address(this), "Multisig: Only multisig can call");
        _;
    }

    // =================
    // INITIALIZATION
    // =================

    function initializeMultisig(
        address[] memory _owners,
        string[] memory names,
        uint256 _required
    ) external override {
        LibMultisigStorage.Storage storage s = LibMultisigStorage.getStorage();
        require(!s.initialized, "Multisig: Already initialized");
        require(_owners.length == names.length, "Multisig: Arrays length mismatch");

        LibMultisigStorage.validateRequirement(_owners.length, _required);

        // Add owners
        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            s.validateOwnerDoesNotExist(owner);

            s.owners.push(owner);
            s.isOwner[owner] = true;
            s.ownerIndex[owner] = i;
            s.ownerDetails[owner] = LibMultisigStorage.Owner({
                addr: owner,
                name: names[i],
                isActive: true,
                addedAt: block.timestamp
            });

            emit OwnerAdded(owner, names[i]);
        }

        s.required = _required;
        s.initialized = true;

        emit MultisigInitialized(_owners, _required);
    }

    // =================
    // OWNER MANAGEMENT
    // =================

    function addOwner(address owner, string memory name) external override onlyMultisig {
        LibMultisigStorage.Storage storage s = LibMultisigStorage.getStorage();
        s.validateOwnerDoesNotExist(owner);

        s.owners.push(owner);
        s.isOwner[owner] = true;
        s.ownerIndex[owner] = s.owners.length - 1;
        s.ownerDetails[owner] = LibMultisigStorage.Owner({
            addr: owner,
            name: name,
            isActive: true,
            addedAt: block.timestamp
        });

        emit OwnerAdded(owner, name);
    }

    function removeOwner(address owner) external override onlyMultisig {
        LibMultisigStorage.Storage storage s = LibMultisigStorage.getStorage();
        s.validateOwnerExists(owner);

        uint256 ownerCount = s.owners.length;
        require(ownerCount > 1, "Multisig: Cannot remove last owner");
        require(s.required <= ownerCount - 1, "Multisig: Required would exceed remaining owners");

        uint256 index = s.ownerIndex[owner];
        address lastOwner = s.owners[ownerCount - 1];

        // Move last owner to the position of removed owner
        s.owners[index] = lastOwner;
        s.ownerIndex[lastOwner] = index;

        // Remove the last element
        s.owners.pop();

        // Clean up mappings
        delete s.isOwner[owner];
        delete s.ownerIndex[owner];
        s.ownerDetails[owner].isActive = false;

        emit OwnerRemoved(owner);
    }

    function replaceOwner(
        address oldOwner,
        address newOwner,
        string memory newName
    ) external override onlyMultisig {
        LibMultisigStorage.Storage storage s = LibMultisigStorage.getStorage();
        s.validateOwnerExists(oldOwner);
        s.validateOwnerDoesNotExist(newOwner);

        uint256 index = s.ownerIndex[oldOwner];
        s.owners[index] = newOwner;

        // Update mappings
        s.isOwner[oldOwner] = false;
        s.isOwner[newOwner] = true;
        s.ownerIndex[newOwner] = index;

        // Update owner details
        s.ownerDetails[oldOwner].isActive = false;
        s.ownerDetails[newOwner] = LibMultisigStorage.Owner({
            addr: newOwner,
            name: newName,
            isActive: true,
            addedAt: block.timestamp
        });

        // Clean up old owner
        delete s.ownerIndex[oldOwner];

        emit OwnerReplaced(oldOwner, newOwner);
        emit OwnerAdded(newOwner, newName);
    }

    function changeRequirement(uint256 _required) external override onlyMultisig {
        LibMultisigStorage.Storage storage s = LibMultisigStorage.getStorage();
        LibMultisigStorage.validateRequirement(s.owners.length, _required);

        s.required = _required;
        emit RequirementChanged(_required);
    }

    function addOwnerWithThreshold(
        address owner,
        string memory name,
        uint256 newRequired
    ) external override onlyMultisig {
        this.addOwner(owner, name);
        if (newRequired != getRequired()) {
            this.changeRequirement(newRequired);
        }
    }

    function removeOwnerWithThreshold(
        address owner,
        uint256 newRequired
    ) external override onlyMultisig {
        this.removeOwner(owner);
        if (newRequired != getRequired()) {
            this.changeRequirement(newRequired);
        }
    }

    // =================
    // TRANSACTION MANAGEMENT
    // =================

    function submitTransaction(
        address to,
        uint256 value,
        bytes memory data,
        string memory description
    ) external override onlyOwner notPaused returns (uint256 transactionId) {
        LibMultisigStorage.Storage storage s = LibMultisigStorage.getStorage();

        transactionId = s.transactions.length;
        s.transactions.push(LibMultisigStorage.Transaction({
            to: to,
            value: value,
            data: data,
            executed: false,
            confirmations: 0,
            timestamp: block.timestamp,
            description: description
        }));

        // Track submission in owner stats
        s.ownerStats[msg.sender].transactionsSubmitted++;
        s.ownerTransactionHistory[msg.sender].push(transactionId);

        emit TransactionSubmitted(transactionId, msg.sender);

        // Auto-confirm for submitter
        s.confirmations[transactionId][msg.sender] = true;
        s.transactions[transactionId].confirmations++;
        s.transactionConfirmers[transactionId].push(msg.sender);

        // Track confirmation in owner stats
        s.ownerStats[msg.sender].transactionsConfirmed++;

        emit TransactionConfirmed(transactionId, msg.sender);
    }

    function confirmTransaction(uint256 transactionId) public override onlyOwner {
        LibMultisigStorage.Storage storage s = LibMultisigStorage.getStorage();
        s.validateTransactionExists(transactionId);
        s.validateNotExecuted(transactionId);

        require(!s.confirmations[transactionId][msg.sender], "Multisig: Already confirmed");

        s.confirmations[transactionId][msg.sender] = true;
        s.transactions[transactionId].confirmations++;
        s.transactionConfirmers[transactionId].push(msg.sender);

        // Track confirmation in owner stats
        s.ownerStats[msg.sender].transactionsConfirmed++;

        emit TransactionConfirmed(transactionId, msg.sender);
    }

    function revokeConfirmation(uint256 transactionId) external override onlyOwner {
        LibMultisigStorage.Storage storage s = LibMultisigStorage.getStorage();
        s.validateTransactionExists(transactionId);
        s.validateNotExecuted(transactionId);

        require(s.confirmations[transactionId][msg.sender], "Multisig: Not confirmed");

        s.confirmations[transactionId][msg.sender] = false;
        s.transactions[transactionId].confirmations--;

        // Remove from confirmers array
        address[] storage confirmers = s.transactionConfirmers[transactionId];
        for (uint256 i = 0; i < confirmers.length; i++) {
            if (confirmers[i] == msg.sender) {
                confirmers[i] = confirmers[confirmers.length - 1];
                confirmers.pop();
                break;
            }
        }

        emit TransactionRevoked(transactionId, msg.sender);
    }

    function executeTransaction(uint256 transactionId) external override onlyOwner {
        LibMultisigStorage.Storage storage s = LibMultisigStorage.getStorage();
        s.validateTransactionExists(transactionId);
        s.validateNotExecuted(transactionId);

        // Check if contract is paused and this isn't an unpause transaction
        LibMultisigStorage.Transaction storage txn = s.transactions[transactionId];
        bool isUnpauseTransaction = txn.to == address(this) &&
            keccak256(txn.data) == keccak256(abi.encodeWithSelector(MultisigFacet.unpause.selector));

        if (s.paused && !isUnpauseTransaction) {
            revert("Multisig: Contract is paused");
        }

        require(isExecutable(transactionId), "Multisig: Not enough confirmations");

        txn.executed = true;

        // Track execution in owner stats
        s.ownerStats[msg.sender].transactionsExecuted++;

        // Execute the transaction
        (bool success, ) = txn.to.call{value: txn.value}(txn.data);

        if (success) {
            emit TransactionExecuted(transactionId, msg.sender);
        } else {
            // Revert the execution state if transaction failed
            txn.executed = false;
            emit TransactionFailed(transactionId, "Transaction execution failed");
            revert("Multisig: Transaction execution failed");
        }
    }

    // =================
    // BATCH OPERATIONS
    // =================

    function confirmMultipleTransactions(uint256[] memory transactionIds) external override onlyOwner {
        LibMultisigStorage.Storage storage s = LibMultisigStorage.getStorage();

        for (uint256 i = 0; i < transactionIds.length; i++) {
            uint256 transactionId = transactionIds[i];

            // Check if transaction exists and is not executed
            if (transactionId >= s.transactions.length || s.transactions[transactionId].executed) {
                continue;
            }

            // Check if already confirmed by this owner
            if (s.confirmations[transactionId][msg.sender]) {
                continue;
            }

            // Confirm the transaction
            s.confirmations[transactionId][msg.sender] = true;
            s.transactions[transactionId].confirmations++;
            s.transactionConfirmers[transactionId].push(msg.sender);

            // Track confirmation in owner stats
            s.ownerStats[msg.sender].transactionsConfirmed++;

            emit TransactionConfirmed(transactionId, msg.sender);
        }
    }

    function executeMultipleTransactions(uint256[] memory transactionIds) external override onlyOwner {
        LibMultisigStorage.Storage storage s = LibMultisigStorage.getStorage();

        for (uint256 i = 0; i < transactionIds.length; i++) {
            uint256 transactionId = transactionIds[i];

            // Check if transaction is executable
            if (!isExecutable(transactionId)) {
                continue;
            }

            LibMultisigStorage.Transaction storage txn = s.transactions[transactionId];

            // Check if contract is paused and this isn't an unpause transaction
            bool isUnpauseTransaction = txn.to == address(this) &&
                keccak256(txn.data) == keccak256(abi.encodeWithSelector(MultisigFacet.unpause.selector));

            if (s.paused && !isUnpauseTransaction) {
                continue; // Skip paused transactions that aren't unpause
            }

            // Execute the transaction
            txn.executed = true;

            // Track execution in owner stats
            s.ownerStats[msg.sender].transactionsExecuted++;

            // Execute the transaction
            (bool success, ) = txn.to.call{value: txn.value}(txn.data);

            if (success) {
                emit TransactionExecuted(transactionId, msg.sender);
            } else {
                // Revert the execution state if transaction failed
                txn.executed = false;
                emit TransactionFailed(transactionId, "Transaction execution failed");
                // Don't revert the whole batch, just skip this transaction
            }
        }
    }

    // =================
    // VIEW FUNCTIONS
    // =================

    function getOwners() external view override returns (address[] memory) {
        return LibMultisigStorage.getStorage().owners;
    }

    function getOwnerDetails(address owner) external view override returns (Owner memory) {
        LibMultisigStorage.Owner storage storageOwner = LibMultisigStorage.getStorage().ownerDetails[owner];
        return Owner({
            addr: storageOwner.addr,
            name: storageOwner.name,
            isActive: storageOwner.isActive,
            addedAt: storageOwner.addedAt
        });
    }

    function isOwner(address addr) external view override returns (bool) {
        return LibMultisigStorage.getStorage().isOwner[addr];
    }

    function getRequired() public view override returns (uint256) {
        return LibMultisigStorage.getStorage().required;
    }

    function getTransactionCount() external view override returns (uint256) {
        return LibMultisigStorage.getStorage().transactions.length;
    }

    function getPendingTransactionCount() external view override returns (uint256) {
        LibMultisigStorage.Storage storage s = LibMultisigStorage.getStorage();
        uint256 count = 0;
        for (uint256 i = 0; i < s.transactions.length; i++) {
            if (!s.transactions[i].executed) {
                count++;
            }
        }
        return count;
    }

    function getExecutedTransactionCount() external view override returns (uint256) {
        LibMultisigStorage.Storage storage s = LibMultisigStorage.getStorage();
        uint256 count = 0;
        for (uint256 i = 0; i < s.transactions.length; i++) {
            if (s.transactions[i].executed) {
                count++;
            }
        }
        return count;
    }

    function getTransaction(uint256 transactionId) external view override returns (Transaction memory) {
        LibMultisigStorage.Storage storage s = LibMultisigStorage.getStorage();
        s.validateTransactionExists(transactionId);

        LibMultisigStorage.Transaction storage txn = s.transactions[transactionId];
        return Transaction({
            to: txn.to,
            value: txn.value,
            data: txn.data,
            executed: txn.executed,
            confirmations: txn.confirmations,
            timestamp: txn.timestamp,
            description: txn.description
        });
    }

    function getTransactionConfirmations(uint256 transactionId) external view override returns (address[] memory) {
        LibMultisigStorage.Storage storage s = LibMultisigStorage.getStorage();
        s.validateTransactionExists(transactionId);
        return s.transactionConfirmers[transactionId];
    }

    function isConfirmedBy(uint256 transactionId, address owner) external view override returns (bool) {
        LibMultisigStorage.Storage storage s = LibMultisigStorage.getStorage();
        return s.confirmations[transactionId][owner];
    }

    function isExecutable(uint256 transactionId) public view override returns (bool) {
        LibMultisigStorage.Storage storage s = LibMultisigStorage.getStorage();
        if (transactionId >= s.transactions.length) return false;

        LibMultisigStorage.Transaction storage txn = s.transactions[transactionId];
        return !txn.executed && txn.confirmations >= s.required;
    }

    // =================
    // PAGINATION FUNCTIONS
    // =================

    function getTransactions(
        uint256 from,
        uint256 to,
        bool pending,
        bool executed
    ) external view override returns (Transaction[] memory) {
        LibMultisigStorage.Storage storage s = LibMultisigStorage.getStorage();
        require(from <= to, "Multisig: Invalid range");
        require(to < s.transactions.length, "Multisig: Range exceeds transaction count");

        uint256 count = 0;
        for (uint256 i = from; i <= to; i++) {
            bool isPending = !s.transactions[i].executed;
            bool isExecuted = s.transactions[i].executed;

            if ((pending && isPending) || (executed && isExecuted)) {
                count++;
            }
        }

        Transaction[] memory result = new Transaction[](count);
        uint256 index = 0;

        for (uint256 i = from; i <= to; i++) {
            bool isPending = !s.transactions[i].executed;
            bool isExecuted = s.transactions[i].executed;

            if ((pending && isPending) || (executed && isExecuted)) {
                LibMultisigStorage.Transaction storage txn = s.transactions[i];
                result[index] = Transaction({
                    to: txn.to,
                    value: txn.value,
                    data: txn.data,
                    executed: txn.executed,
                    confirmations: txn.confirmations,
                    timestamp: txn.timestamp,
                    description: txn.description
                });
                index++;
            }
        }

        return result;
    }

    function getTransactionIds(
        uint256 from,
        uint256 to,
        bool pending,
        bool executed
    ) external view override returns (uint256[] memory) {
        LibMultisigStorage.Storage storage s = LibMultisigStorage.getStorage();
        require(from <= to, "Multisig: Invalid range");
        require(to < s.transactions.length, "Multisig: Range exceeds transaction count");

        uint256 count = 0;
        for (uint256 i = from; i <= to; i++) {
            bool isPending = !s.transactions[i].executed;
            bool isExecuted = s.transactions[i].executed;

            if ((pending && isPending) || (executed && isExecuted)) {
                count++;
            }
        }

        uint256[] memory result = new uint256[](count);
        uint256 index = 0;

        for (uint256 i = from; i <= to; i++) {
            bool isPending = !s.transactions[i].executed;
            bool isExecuted = s.transactions[i].executed;

            if ((pending && isPending) || (executed && isExecuted)) {
                result[index] = i;
                index++;
            }
        }

        return result;
    }

    // =================
    // EMERGENCY FUNCTIONS
    // =================

    function pause() external override onlyMultisig {
        LibMultisigStorage.Storage storage s = LibMultisigStorage.getStorage();
        require(!s.paused, "Multisig: Already paused");
        s.paused = true;
        emit EmergencyPause(true);
    }

    function unpause() external override onlyMultisig {
        LibMultisigStorage.Storage storage s = LibMultisigStorage.getStorage();
        require(s.paused, "Multisig: Not paused");
        s.paused = false;
        emit EmergencyPause(false);
    }

    function isPaused() external view override returns (bool) {
        return LibMultisigStorage.getStorage().paused;
    }

    // =================
    // ADVANCED FEATURES
    // =================

    function getTransactionHistory(address owner) external view override returns (uint256[] memory) {
        return LibMultisigStorage.getStorage().ownerTransactionHistory[owner];
    }

    function getOwnerStats(address owner) external view override returns (
        uint256 transactionsSubmitted,
        uint256 transactionsConfirmed,
        uint256 transactionsExecuted
    ) {
        LibMultisigStorage.OwnerStats storage stats = LibMultisigStorage.getStorage().ownerStats[owner];
        return (
            stats.transactionsSubmitted,
            stats.transactionsConfirmed,
            stats.transactionsExecuted
        );
    }

    // =================
    // FALLBACK
    // =================

    receive() external payable {
        // Allow contract to receive ETH
    }
}