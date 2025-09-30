// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibERC20Storage} from "../libraries/LibERC20Storage.sol";
import {LibSwapStorage} from "../libraries/LibSwapStorage.sol";
import {IERC20} from "../interfaces/IERC20.sol";

contract ERC20SwapFacet {
    event SwapETHForTokens(
        address indexed buyer,
        uint256 ethAmount,
        uint256 tokenAmount,
        uint256 rate
    );

    event SwapTokensForETH(
        address indexed seller,
        uint256 tokenAmount,
        uint256 ethAmount,
        uint256 rate
    );

    event SwapERC20ForTokens(
        address indexed buyer,
        address indexed inputToken,
        uint256 inputAmount,
        uint256 tokenAmount,
        uint256 rate
    );

    event SwapTokensForERC20(
        address indexed seller,
        address indexed outputToken,
        uint256 tokenAmount,
        uint256 outputAmount,
        uint256 rate
    );

    event RateUpdated(address indexed token, uint256 newRate);
    event LiquidityAdded(
        address indexed provider,
        uint256 ethAmount,
        uint256 tokenAmount
    );
    event LiquidityRemoved(
        address indexed provider,
        uint256 ethAmount,
        uint256 tokenAmount
    );

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    // =================
    // SWAP FUNCTIONS
    // =================

    function swapETHForTokens() external payable returns (uint256 tokenAmount) {
        require(msg.value > 0, "Must send ETH");

        LibSwapStorage.Storage storage swapStorage = LibSwapStorage
            .getStorage();
        require(swapStorage.ethToTokenRate > 0, "ETH rate not set");

        tokenAmount = (msg.value * swapStorage.ethToTokenRate) / 1e18;

        uint256 fee = (tokenAmount * swapStorage.swapFee) / 10000;
        tokenAmount -= fee;

        require(tokenAmount > 0, "Token amount too small");

        swapStorage.ethLiquidity += msg.value;

        _mint(msg.sender, tokenAmount);

        // Mint fee tokens to fee recipient if set
        if (fee > 0 && swapStorage.feeRecipient != address(0)) {
            _mint(swapStorage.feeRecipient, fee);
        }

        emit SwapETHForTokens(
            msg.sender,
            msg.value,
            tokenAmount,
            swapStorage.ethToTokenRate
        );
    }

    function swapTokensForETH(
        uint256 tokenAmount
    ) external returns (uint256 ethAmount) {
        require(tokenAmount > 0, "Must specify token amount");

        LibSwapStorage.Storage storage swapStorage = LibSwapStorage
            .getStorage();
        require(swapStorage.ethToTokenRate > 0, "ETH rate not set");

        // Calculate ETH amount
        ethAmount = (tokenAmount * 1e18) / swapStorage.ethToTokenRate;

        // Apply swap fee
        uint256 fee = (ethAmount * swapStorage.swapFee) / 10000;
        ethAmount -= fee;

        require(ethAmount > 0, "ETH amount too small");
        require(
            address(this).balance >= ethAmount,
            "Insufficient ETH liquidity"
        );

        // Burn tokens from seller
        _burn(msg.sender, tokenAmount);

        // Update liquidity
        swapStorage.ethLiquidity -= ethAmount;

        // Send ETH to seller
        (bool success, ) = payable(msg.sender).call{value: ethAmount}("");
        require(success, "ETH transfer failed");

        // Send fee to fee recipient if set
        if (fee > 0 && swapStorage.feeRecipient != address(0)) {
            (bool feeSuccess, ) = payable(swapStorage.feeRecipient).call{
                value: fee
            }("");
            require(feeSuccess, "Fee transfer failed");
        }

        emit SwapTokensForETH(
            msg.sender,
            tokenAmount,
            ethAmount,
            swapStorage.ethToTokenRate
        );
    }

    function swapERC20ForTokens(
        address inputToken,
        uint256 inputAmount
    ) external returns (uint256 tokenAmount) {
        require(inputToken != address(0), "Invalid token address");
        require(inputAmount > 0, "Must specify input amount");

        LibSwapStorage.Storage storage swapStorage = LibSwapStorage
            .getStorage();
        require(
            swapStorage.isSupportedToken[inputToken],
            "Token not supported"
        );

        uint256 rate = swapStorage.erc20ToTokenRates[inputToken];
        require(rate > 0, "Rate not set for token");

        // Get token decimals for proper calculation
        uint8 inputDecimals = IERC20(inputToken).decimals();

        // Calculate token amount (rate is tokens per 1 unit of input token)
        tokenAmount = (inputAmount * rate) / (10 ** inputDecimals);

        // Apply swap fee
        uint256 fee = (tokenAmount * swapStorage.swapFee) / 10000;
        tokenAmount -= fee;

        require(tokenAmount > 0, "Token amount too small");

        // Transfer input tokens from user
        IERC20(inputToken).transferFrom(msg.sender, address(this), inputAmount);

        // Mint tokens to buyer
        _mint(msg.sender, tokenAmount);

        // Mint fee tokens to fee recipient if set
        if (fee > 0 && swapStorage.feeRecipient != address(0)) {
            _mint(swapStorage.feeRecipient, fee);
        }

        emit SwapERC20ForTokens(
            msg.sender,
            inputToken,
            inputAmount,
            tokenAmount,
            rate
        );
    }

    function swapTokensForERC20(
        address outputToken,
        uint256 tokenAmount
    ) external returns (uint256 outputAmount) {
        require(outputToken != address(0), "Invalid token address");
        require(tokenAmount > 0, "Must specify token amount");

        LibSwapStorage.Storage storage swapStorage = LibSwapStorage
            .getStorage();
        require(
            swapStorage.isSupportedToken[outputToken],
            "Token not supported"
        );

        uint256 rate = swapStorage.erc20ToTokenRates[outputToken];
        require(rate > 0, "Rate not set for token");

        // Get token decimals for proper calculation
        uint8 outputDecimals = IERC20(outputToken).decimals();

        // Calculate output amount
        outputAmount = (tokenAmount * (10 ** outputDecimals)) / rate;

        // Apply swap fee
        uint256 fee = (outputAmount * swapStorage.swapFee) / 10000;
        outputAmount -= fee;

        require(outputAmount > 0, "Output amount too small");
        require(
            IERC20(outputToken).balanceOf(address(this)) >= outputAmount,
            "Insufficient token liquidity"
        );

        // Burn tokens from seller
        _burn(msg.sender, tokenAmount);

        // Transfer output tokens to user
        IERC20(outputToken).transfer(msg.sender, outputAmount);

        // Send fee to fee recipient if set
        if (fee > 0 && swapStorage.feeRecipient != address(0)) {
            IERC20(outputToken).transfer(swapStorage.feeRecipient, fee);
        }

        emit SwapTokensForERC20(
            msg.sender,
            outputToken,
            tokenAmount,
            outputAmount,
            rate
        );
    }

    // =================
    // VIEW FUNCTIONS
    // =================

    function getETHToTokenRate() external view returns (uint256) {
        return LibSwapStorage.getStorage().ethToTokenRate;
    }

    function getTokenToETHRate() external view returns (uint256) {
        LibSwapStorage.Storage storage swapStorage = LibSwapStorage
            .getStorage();
        if (swapStorage.ethToTokenRate == 0) return 0;
        return (1e18 * 1e18) / swapStorage.ethToTokenRate;
    }

    function getERC20ToTokenRate(
        address token
    ) external view returns (uint256) {
        return LibSwapStorage.getStorage().erc20ToTokenRates[token];
    }

    function getTokenToERC20Rate(
        address token
    ) external view returns (uint256) {
        LibSwapStorage.Storage storage swapStorage = LibSwapStorage
            .getStorage();
        uint256 rate = swapStorage.erc20ToTokenRates[token];
        if (rate == 0) return 0;

        uint8 tokenDecimals = IERC20(token).decimals();
        return ((10 ** tokenDecimals) * (10 ** tokenDecimals)) / rate;
    }

    function getETHBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getTokenBalance() external view returns (uint256) {
        LibERC20Storage.Storage storage erc20Storage = LibERC20Storage
            .getStorage();
        return erc20Storage.balances[address(this)];
    }

    function getSupportedTokens() external view returns (address[] memory) {
        return LibSwapStorage.getStorage().supportedTokens;
    }

    function getSwapFee() external view returns (uint256) {
        return LibSwapStorage.getStorage().swapFee;
    }

    function getFeeRecipient() external view returns (address) {
        return LibSwapStorage.getStorage().feeRecipient;
    }

    // =================
    // ADMIN FUNCTIONS
    // =================

    function setETHRate(uint256 rate) external onlyOwner {
        require(rate > 0, "Rate must be positive");
        LibSwapStorage.getStorage().ethToTokenRate = rate;
        emit RateUpdated(address(0), rate);
    }

    function setERC20Rate(address token, uint256 rate) external onlyOwner {
        require(token != address(0), "Invalid token address");
        require(rate > 0, "Rate must be positive");

        LibSwapStorage.Storage storage swapStorage = LibSwapStorage
            .getStorage();

        // Add to supported tokens if not already present
        if (!swapStorage.isSupportedToken[token]) {
            swapStorage.supportedTokens.push(token);
            swapStorage.isSupportedToken[token] = true;
        }

        swapStorage.erc20ToTokenRates[token] = rate;
        emit RateUpdated(token, rate);
    }

    function removeSupportedToken(address token) external onlyOwner {
        require(token != address(0), "Invalid token address");

        LibSwapStorage.Storage storage swapStorage = LibSwapStorage
            .getStorage();
        require(swapStorage.isSupportedToken[token], "Token not supported");

        // Remove from supported tokens array
        address[] storage tokens = swapStorage.supportedTokens;
        for (uint256 i = 0; i < tokens.length; i++) {
            if (tokens[i] == token) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                break;
            }
        }

        swapStorage.isSupportedToken[token] = false;
        swapStorage.erc20ToTokenRates[token] = 0;
    }

    function setSwapFee(uint256 fee) external onlyOwner {
        require(fee <= 1000, "Fee too high (max 10%)"); // Max 10%
        LibSwapStorage.getStorage().swapFee = fee;
    }

    function setFeeRecipient(address recipient) external onlyOwner {
        LibSwapStorage.getStorage().feeRecipient = recipient;
    }

    function addLiquidity() external payable onlyOwner {
        require(msg.value > 0, "Must send ETH");

        LibSwapStorage.Storage storage swapStorage = LibSwapStorage
            .getStorage();
        swapStorage.ethLiquidity += msg.value;

        emit LiquidityAdded(msg.sender, msg.value, 0);
    }

    function removeLiquidity(uint256 ethAmount) external onlyOwner {
        require(ethAmount > 0, "Must specify ETH amount");
        require(address(this).balance >= ethAmount, "Insufficient balance");

        LibSwapStorage.Storage storage swapStorage = LibSwapStorage
            .getStorage();
        swapStorage.ethLiquidity -= ethAmount;

        (bool success, ) = payable(msg.sender).call{value: ethAmount}("");
        require(success, "ETH transfer failed");

        emit LiquidityRemoved(msg.sender, ethAmount, 0);
    }

    function withdrawERC20(address token, uint256 amount) external onlyOwner {
        require(token != address(0), "Invalid token address");
        require(amount > 0, "Must specify amount");

        IERC20(token).transfer(msg.sender, amount);
    }

    function initializeSwap(
        uint256 initialETHRate,
        uint256 initialSwapFee
    ) external onlyOwner {
        LibSwapStorage.Storage storage swapStorage = LibSwapStorage
            .getStorage();
        require(swapStorage.ethToTokenRate == 0, "Already initialized");

        swapStorage.ethToTokenRate = initialETHRate;
        swapStorage.swapFee = initialSwapFee;
        swapStorage.feeRecipient = msg.sender;
    }

    // =================
    // INTERNAL FUNCTIONS
    // =================

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to zero address");

        LibERC20Storage.Storage storage s = LibERC20Storage.getStorage();
        s.totalSupply += amount;
        unchecked {
            s.balances[account] += amount;
        }

        // Emit Transfer event
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from zero address");

        LibERC20Storage.Storage storage s = LibERC20Storage.getStorage();
        uint256 accountBalance = s.balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");

        unchecked {
            s.balances[account] = accountBalance - amount;
            s.totalSupply -= amount;
        }

        // Emit Transfer event
        emit Transfer(account, address(0), amount);
    }

    // Events (needed for internal functions)
    event Transfer(address indexed from, address indexed to, uint256 value);

    // Fallback to receive ETH
    receive() external payable {
        LibSwapStorage.getStorage().ethLiquidity += msg.value;
    }
}
