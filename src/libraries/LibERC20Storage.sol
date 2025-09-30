// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library LibERC20Storage {
    bytes32 constant STORAGE_POSITION = keccak256("diamond.storage.erc20");

    struct Storage {
        string name;
        string symbol;
        uint8 decimals;
        uint256 totalSupply;
        mapping(address => uint256) balances;
        mapping(address => mapping(address => uint256)) allowances;
    }

    function getStorage() internal pure returns (Storage storage s) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}
