// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibERC20Storage} from "../libraries/LibERC20Storage.sol";
import {LibMetadataStorage} from "../libraries/LibMetadataStorage.sol";
import {IERC20} from "../interfaces/IERC20.sol";

contract ERC20MetadataFacet {
    event MetadataUpdated(string indexed field, string value);
    event LogoUpdated(bool isCustom);

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    // =================
    // VIEW FUNCTIONS
    // =================

    function tokenURI() external view returns (string memory) {
        LibERC20Storage.Storage storage erc20Storage = LibERC20Storage.getStorage();
        LibMetadataStorage.Storage storage metaStorage = LibMetadataStorage.getStorage();

        // Create JSON metadata
        string memory json = string(abi.encodePacked(
            '{"name":"', erc20Storage.name, '",',
            '"symbol":"', erc20Storage.symbol, '",',
            '"decimals":', _toString(erc20Storage.decimals), ',',
            '"description":"', metaStorage.description, '",',
            '"image":"data:image/svg+xml;base64,', _base64Encode(bytes(logoSVG())), '",',
            '"website":"', metaStorage.website, '",',
            '"twitter":"', metaStorage.twitter, '",',
            '"type":"ERC20 Diamond Token"}'
        ));

        return string(abi.encodePacked(
            "data:application/json;base64,",
            _base64Encode(bytes(json))
        ));
    }

    function logoSVG() public view returns (string memory) {
        LibMetadataStorage.Storage storage metaStorage = LibMetadataStorage.getStorage();

        if (metaStorage.useCustomLogo && bytes(metaStorage.customLogoSVG).length > 0) {
            return metaStorage.customLogoSVG;
        }

        return _getDefaultLogo();
    }

    function description() external view returns (string memory) {
        return LibMetadataStorage.getStorage().description;
    }

    function website() external view returns (string memory) {
        return LibMetadataStorage.getStorage().website;
    }

    function twitter() external view returns (string memory) {
        return LibMetadataStorage.getStorage().twitter;
    }

    // =================
    // ADMIN FUNCTIONS
    // =================

    function setDescription(string memory newDescription) external onlyOwner {
        LibMetadataStorage.getStorage().description = newDescription;
        emit MetadataUpdated("description", newDescription);
    }

    function setWebsite(string memory newWebsite) external onlyOwner {
        LibMetadataStorage.getStorage().website = newWebsite;
        emit MetadataUpdated("website", newWebsite);
    }

    function setTwitter(string memory newTwitter) external onlyOwner {
        LibMetadataStorage.getStorage().twitter = newTwitter;
        emit MetadataUpdated("twitter", newTwitter);
    }

    function setCustomLogo(string memory newLogoSVG) external onlyOwner {
        LibMetadataStorage.Storage storage metaStorage = LibMetadataStorage.getStorage();
        metaStorage.customLogoSVG = newLogoSVG;
        metaStorage.useCustomLogo = true;
        emit LogoUpdated(true);
    }

    function resetToDefaultLogo() external onlyOwner {
        LibMetadataStorage.Storage storage metaStorage = LibMetadataStorage.getStorage();
        metaStorage.useCustomLogo = false;
        emit LogoUpdated(false);
    }

    function initializeMetadata(
        string memory initialDescription,
        string memory initialWebsite,
        string memory initialTwitter
    ) external onlyOwner {
        LibMetadataStorage.Storage storage metaStorage = LibMetadataStorage.getStorage();

        // Only initialize if not already set
        if (bytes(metaStorage.description).length == 0) {
            metaStorage.description = initialDescription;
            metaStorage.website = initialWebsite;
            metaStorage.twitter = initialTwitter;
            metaStorage.useCustomLogo = false;
        }
    }

    // =================
    // INTERNAL FUNCTIONS
    // =================

    function _getDefaultLogo() internal view returns (string memory) {
        LibERC20Storage.Storage storage erc20Storage = LibERC20Storage.getStorage();

        return string(abi.encodePacked(
            '<svg width="200" height="200" viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg">',
            '<defs>',
            '<linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%">',
            '<stop offset="0%" style="stop-color:#667eea;stop-opacity:1" />',
            '<stop offset="100%" style="stop-color:#764ba2;stop-opacity:1" />',
            '</linearGradient>',
            '<linearGradient id="grad2" x1="0%" y1="0%" x2="100%" y2="0%">',
            '<stop offset="0%" style="stop-color:#f093fb;stop-opacity:1" />',
            '<stop offset="100%" style="stop-color:#f5576c;stop-opacity:1" />',
            '</linearGradient>',
            '</defs>',

            // Outer circle with gradient
            '<circle cx="100" cy="100" r="90" fill="url(#grad1)" stroke="url(#grad2)" stroke-width="4"/>',

            // Diamond shape in center
            '<polygon points="100,40 140,100 100,160 60,100" fill="white" fill-opacity="0.9"/>',
            '<polygon points="100,50 130,100 100,150 70,100" fill="url(#grad2)"/>',

            // Inner diamond detail
            '<polygon points="100,60 120,100 100,140 80,100" fill="white" fill-opacity="0.3"/>',

            // Text
            '<text x="100" y="185" font-family="Arial, sans-serif" font-size="16" font-weight="bold" text-anchor="middle" fill="url(#grad1)">',
            erc20Storage.symbol,
            '</text>',

            // Sparkle effects
            '<circle cx="70" cy="70" r="3" fill="white" opacity="0.8">',
            '<animate attributeName="opacity" values="0.8;0.3;0.8" dur="2s" repeatCount="indefinite"/>',
            '</circle>',
            '<circle cx="130" cy="130" r="2" fill="white" opacity="0.6">',
            '<animate attributeName="opacity" values="0.6;0.2;0.6" dur="1.5s" repeatCount="indefinite"/>',
            '</circle>',
            '<circle cx="140" cy="70" r="2.5" fill="white" opacity="0.7">',
            '<animate attributeName="opacity" values="0.7;0.2;0.7" dur="1.8s" repeatCount="indefinite"/>',
            '</circle>',

            '</svg>'
        ));
    }

    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function _base64Encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        string memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        string memory result = new string(encodedLen + 32);

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let dataPtr := data
                let endPtr := add(dataPtr, mload(data))
            } lt(dataPtr, endPtr) {
            } {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }

            mstore(result, encodedLen)
        }

        return result;
    }
}