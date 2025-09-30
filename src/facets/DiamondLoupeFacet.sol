// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IDiamondLoupe} from "../interfaces/IDiamondLoupe.sol";
import {IERC165} from "../interfaces/IERC165.sol";
import {LibDiamond} from "../libraries/LibDiamond.sol";

contract DiamondLoupeFacet is IDiamondLoupe, IERC165 {
    function facets() external view override returns (Facet[] memory facets_) {
        // Get unique facet addresses
        address[] memory uniqueFacets = _getUniqueFacetAddresses();
        facets_ = new Facet[](uniqueFacets.length);

        for (uint256 i; i < uniqueFacets.length; i++) {
            address facetAddress_ = uniqueFacets[i];
            facets_[i].facetAddress = facetAddress_;
            facets_[i].functionSelectors = _getFacetFunctionSelectors(facetAddress_);
        }
    }

    function facetFunctionSelectors(
        address _facet
    ) external view override returns (bytes4[] memory facetFunctionSelectors_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 numSelectors = ds.facetFunctionSelectorCount[_facet];
        facetFunctionSelectors_ = new bytes4[](numSelectors);
        uint256 selectorIndex;

        for (uint256 i; i < ds.functionSelectors.length; i++) {
            bytes4 selector = ds.functionSelectors[i];
            address facetAddress_ = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            if (_facet == facetAddress_) {
                facetFunctionSelectors_[selectorIndex] = selector;
                selectorIndex++;
            }
        }
    }

    function facetAddresses()
        external
        view
        override
        returns (address[] memory facetAddresses_)
    {
        return _getUniqueFacetAddresses();
    }

    function facetAddress(
        bytes4 _functionSelector
    ) external view override returns (address facetAddress_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        facetAddress_ = ds
            .selectorToFacetAndPosition[_functionSelector]
            .facetAddress;
    }

    function supportsInterface(
        bytes4 _interfaceId
    ) external view override returns (bool) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // Check registered interfaces
        if (ds.supportedInterfaces[_interfaceId]) {
            return true;
        }

        // Check standard interfaces
        return (
            _interfaceId == type(IERC165).interfaceId ||
            _interfaceId == type(IDiamondLoupe).interfaceId
        );
    }

    function _getUniqueFacetAddresses() internal view returns (address[] memory facetAddresses_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        // Collect unique facet addresses
        address[] memory tempAddresses = new address[](ds.functionSelectors.length);
        uint256 uniqueCount = 0;

        for (uint256 i; i < ds.functionSelectors.length; i++) {
            address facetAddress_ = ds
                .selectorToFacetAndPosition[ds.functionSelectors[i]]
                .facetAddress;

            // Check if address is already in the array
            bool isUnique = true;
            for (uint256 j; j < uniqueCount; j++) {
                if (tempAddresses[j] == facetAddress_) {
                    isUnique = false;
                    break;
                }
            }

            if (isUnique) {
                tempAddresses[uniqueCount] = facetAddress_;
                uniqueCount++;
            }
        }

        // Create result array with correct size
        facetAddresses_ = new address[](uniqueCount);
        for (uint256 i; i < uniqueCount; i++) {
            facetAddresses_[i] = tempAddresses[i];
        }
    }

    function _getFacetFunctionSelectors(address _facet) internal view returns (bytes4[] memory facetFunctionSelectors_) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        uint256 numSelectors = ds.facetFunctionSelectorCount[_facet];
        facetFunctionSelectors_ = new bytes4[](numSelectors);
        uint256 selectorIndex;

        for (uint256 i; i < ds.functionSelectors.length; i++) {
            bytes4 selector = ds.functionSelectors[i];
            address facetAddress_ = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            if (_facet == facetAddress_) {
                facetFunctionSelectors_[selectorIndex] = selector;
                selectorIndex++;
            }
        }
    }
}
