// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibERC20Storage} from "../libraries/LibERC20Storage.sol";


contract ERC20MintableFacet {
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
    
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to zero address");
        
        LibERC20Storage.Storage storage s = LibERC20Storage.getStorage();
        s.totalSupply += amount;
        unchecked {
            s.balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);
    }
}


