// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibERC20Storage} from "../libraries/LibERC20Storage.sol";

contract ERC20BurnableFacet {
    event Transfer(address indexed from, address indexed to, uint256 value);

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burnFrom(address account, uint256 amount) external {
        LibERC20Storage.Storage storage s = LibERC20Storage.getStorage();
        uint256 currentAllowance = s.allowances[account][msg.sender];
        require(currentAllowance >= amount, "ERC20: insufficient allowance");

        unchecked {
            s.allowances[account][msg.sender] = currentAllowance - amount;
        }
        _burn(account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from zero address");

        LibERC20Storage.Storage storage s = LibERC20Storage.getStorage();
        uint256 accountBalance = s.balances[account];
        require(accountBalance >= amount, "ERC20: burn exceeds balance");

        unchecked {
            s.balances[account] = accountBalance - amount;
            s.totalSupply -= amount;
        }
        emit Transfer(account, address(0), amount);
    }
}
