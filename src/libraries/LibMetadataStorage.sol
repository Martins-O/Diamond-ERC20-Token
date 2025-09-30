// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library LibMetadataStorage {
    bytes32 constant METADATA_STORAGE_POSITION = keccak256("diamond.standard.metadata.storage");

    struct Storage {
        string description;
        string website;
        string twitter;
        string customLogoSVG;
        bool useCustomLogo;
    }

    function getStorage() internal pure returns (Storage storage s) {
        bytes32 position = METADATA_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}