// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20Metadata {
    // Extended metadata functions
    function tokenURI() external view returns (string memory);
    function logoSVG() external view returns (string memory);
    function description() external view returns (string memory);
    function website() external view returns (string memory);
    function twitter() external view returns (string memory);

    // Admin functions for updating metadata
    function setDescription(string memory newDescription) external;
    function setWebsite(string memory newWebsite) external;
    function setTwitter(string memory newTwitter) external;
    function setCustomLogo(string memory newLogoSVG) external;
    function resetToDefaultLogo() external;

    // Events
    event MetadataUpdated(string indexed field, string value);
    event LogoUpdated(bool isCustom);
}