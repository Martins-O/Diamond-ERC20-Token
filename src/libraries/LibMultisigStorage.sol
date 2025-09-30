// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library LibMultisigStorage {
    bytes32 constant MULTISIG_STORAGE_POSITION = keccak256("diamond.standard.multisig.storage");

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 confirmations;
        uint256 timestamp;
        string description;
    }

    struct Owner {
        address addr;
        string name;
        bool isActive;
        uint256 addedAt;
    }

    struct OwnerStats {
        uint256 transactionsSubmitted;
        uint256 transactionsConfirmed;
        uint256 transactionsExecuted;
    }

    struct Storage {
        // Owner management
        address[] owners;
        mapping(address => bool) isOwner;
        mapping(address => Owner) ownerDetails;
        mapping(address => uint256) ownerIndex; // Index in owners array
        uint256 required; // Number of confirmations required

        // Transaction management
        Transaction[] transactions;
        mapping(uint256 => mapping(address => bool)) confirmations;
        mapping(uint256 => address[]) transactionConfirmers;

        // Statistics and history
        mapping(address => OwnerStats) ownerStats;
        mapping(address => uint256[]) ownerTransactionHistory;

        // State management
        bool paused;
        bool initialized;
        uint256 transactionCounter;

        // Nonce for preventing replay attacks
        mapping(address => uint256) nonces;
    }

    function getStorage() internal pure returns (Storage storage s) {
        bytes32 position = MULTISIG_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }

    // Helper functions for validation
    function validateOwnerExists(Storage storage s, address owner) internal view {
        require(s.isOwner[owner], "Multisig: Owner does not exist");
    }

    function validateOwnerDoesNotExist(Storage storage s, address owner) internal view {
        require(!s.isOwner[owner], "Multisig: Owner already exists");
        require(owner != address(0), "Multisig: Invalid owner address");
    }

    function validateTransactionExists(Storage storage s, uint256 transactionId) internal view {
        require(transactionId < s.transactions.length, "Multisig: Transaction does not exist");
    }

    function validateNotExecuted(Storage storage s, uint256 transactionId) internal view {
        require(!s.transactions[transactionId].executed, "Multisig: Transaction already executed");
    }

    function validateNotPaused(Storage storage s) internal view {
        require(!s.paused, "Multisig: Contract is paused");
    }

    function validateRequirement(uint256 ownerCount, uint256 required) internal pure {
        require(required > 0, "Multisig: Required must be greater than 0");
        require(required <= ownerCount, "Multisig: Required exceeds owner count");
        require(ownerCount > 0, "Multisig: Must have at least one owner");
    }
}