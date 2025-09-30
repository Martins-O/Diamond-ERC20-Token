// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibERC20Storage} from "../libraries/LibERC20Storage.sol";

contract ERC20InitFacet {
    event Transfer(address indexed from, address indexed to, uint256 value);

    function init(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply
    ) external {
        LibERC20Storage.Storage storage s = LibERC20Storage.getStorage();
        require(bytes(s.name).length == 0, "Already initialized");

        s.name = _name;
        s.symbol = _symbol;
        s.decimals = _decimals;

        if (_initialSupply > 0) {
            s.totalSupply = _initialSupply;
            s.balances[msg.sender] = _initialSupply;
            emit Transfer(address(0), msg.sender, _initialSupply);
        }
    }
}
