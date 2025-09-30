// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IMultisig {
    // Structs
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

    // Events
    event OwnerAdded(address indexed owner, string name);
    event OwnerRemoved(address indexed owner);
    event OwnerReplaced(address indexed oldOwner, address indexed newOwner);
    event RequirementChanged(uint256 required);

    event TransactionSubmitted(uint256 indexed transactionId, address indexed submitter);
    event TransactionConfirmed(uint256 indexed transactionId, address indexed owner);
    event TransactionRevoked(uint256 indexed transactionId, address indexed owner);
    event TransactionExecuted(uint256 indexed transactionId, address indexed executor);
    event TransactionFailed(uint256 indexed transactionId, string reason);

    event MultisigInitialized(address[] owners, uint256 required);
    event EmergencyPause(bool paused);

    // Owner management functions
    function addOwner(address owner, string memory name) external;
    function removeOwner(address owner) external;
    function replaceOwner(address oldOwner, address newOwner, string memory newName) external;
    function changeRequirement(uint256 required) external;

    // Transaction functions
    function submitTransaction(
        address to,
        uint256 value,
        bytes memory data,
        string memory description
    ) external returns (uint256 transactionId);

    function confirmTransaction(uint256 transactionId) external;
    function revokeConfirmation(uint256 transactionId) external;
    function executeTransaction(uint256 transactionId) external;

    // Batch operations
    function confirmMultipleTransactions(uint256[] memory transactionIds) external;
    function executeMultipleTransactions(uint256[] memory transactionIds) external;

    // View functions
    function getOwners() external view returns (address[] memory);
    function getOwnerDetails(address owner) external view returns (Owner memory);
    function isOwner(address addr) external view returns (bool);
    function getRequired() external view returns (uint256);
    function getTransactionCount() external view returns (uint256);
    function getPendingTransactionCount() external view returns (uint256);
    function getExecutedTransactionCount() external view returns (uint256);

    function getTransaction(uint256 transactionId) external view returns (Transaction memory);
    function getTransactionConfirmations(uint256 transactionId) external view returns (address[] memory);
    function isConfirmedBy(uint256 transactionId, address owner) external view returns (bool);
    function isExecutable(uint256 transactionId) external view returns (bool);

    // Pagination functions
    function getTransactions(
        uint256 from,
        uint256 to,
        bool pending,
        bool executed
    ) external view returns (Transaction[] memory);

    function getTransactionIds(
        uint256 from,
        uint256 to,
        bool pending,
        bool executed
    ) external view returns (uint256[] memory);

    // Emergency functions
    function pause() external;
    function unpause() external;
    function isPaused() external view returns (bool);

    // Initialization
    function initializeMultisig(
        address[] memory owners,
        string[] memory names,
        uint256 required
    ) external;

    // Advanced features
    function addOwnerWithThreshold(
        address owner,
        string memory name,
        uint256 newRequired
    ) external;

    function removeOwnerWithThreshold(
        address owner,
        uint256 newRequired
    ) external;

    function getTransactionHistory(address owner) external view returns (uint256[] memory);
    function getOwnerStats(address owner) external view returns (
        uint256 transactionsSubmitted,
        uint256 transactionsConfirmed,
        uint256 transactionsExecuted
    );
}