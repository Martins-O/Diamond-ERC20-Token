// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

library LibSwapStorage {
    bytes32 constant SWAP_STORAGE_POSITION =
        keccak256("diamond.standard.swap.storage");

    struct Storage {
        uint256 ethToTokenRate;
        mapping(address => uint256) erc20ToTokenRates;
        address[] supportedTokens;
        mapping(address => bool) isSupportedToken;
        uint256 ethLiquidity;
        uint256 tokenLiquidity;
        uint256 swapFee;
        address feeRecipient;
    }

    function getStorage() internal pure returns (Storage storage s) {
        bytes32 position = SWAP_STORAGE_POSITION;
        assembly {
            s.slot := position
        }
    }
}
