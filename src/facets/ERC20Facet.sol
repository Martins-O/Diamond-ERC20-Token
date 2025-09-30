// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "../interfaces/IERC20.sol";
import {LibERC20Storage} from "../libraries/LibERC20Storage.sol";

contract ERC20Facet is IERC20 {
    function name() external view override returns (string memory) {
        return LibERC20Storage.getStorage().name;
    }

    function symbol() external view override returns (string memory) {
        return LibERC20Storage.getStorage().symbol;
    }

    function decimals() external view override returns (uint8) {
        return LibERC20Storage.getStorage().decimals;
    }

    function totalSupply() external view override returns (uint256) {
        return LibERC20Storage.getStorage().totalSupply;
    }

    function balanceOf(
        address account
    ) external view override returns (uint256) {
        return LibERC20Storage.getStorage().balances[account];
    }

    function allowance(
        address owner,
        address spender
    ) external view override returns (uint256) {
        return LibERC20Storage.getStorage().allowances[owner][spender];
    }

    function transfer(
        address to,
        uint256 amount
    ) external override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(
        address spender,
        uint256 amount
    ) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        LibERC20Storage.Storage storage s = LibERC20Storage.getStorage();
        uint256 currentAllowance = s.allowances[from][msg.sender];
        require(currentAllowance >= amount, "ERC20: insufficient allowance");

        unchecked {
            _approve(from, msg.sender, currentAllowance - amount);
        }
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from zero address");
        require(to != address(0), "ERC20: transfer to zero address");

        LibERC20Storage.Storage storage s = LibERC20Storage.getStorage();
        uint256 fromBalance = s.balances[from];
        require(fromBalance >= amount, "ERC20: insufficient balance");

        unchecked {
            s.balances[from] = fromBalance - amount;
            s.balances[to] += amount;
        }
        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from zero address");
        require(spender != address(0), "ERC20: approve to zero address");

        LibERC20Storage.getStorage().allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}
