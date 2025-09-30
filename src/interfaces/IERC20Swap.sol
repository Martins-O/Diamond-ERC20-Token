// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20Swap {
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
    event LiquidityAdded(address indexed provider, uint256 ethAmount, uint256 tokenAmount);
    event LiquidityRemoved(address indexed provider, uint256 ethAmount, uint256 tokenAmount);

    function swapETHForTokens() external payable returns (uint256 tokenAmount);
    function swapTokensForETH(uint256 tokenAmount) external returns (uint256 ethAmount);
    function swapERC20ForTokens(address inputToken, uint256 inputAmount) external returns (uint256 tokenAmount);
    function swapTokensForERC20(address outputToken, uint256 tokenAmount) external returns (uint256 outputAmount);

    function getETHToTokenRate() external view returns (uint256);
    function getTokenToETHRate() external view returns (uint256);
    function getERC20ToTokenRate(address token) external view returns (uint256);
    function getTokenToERC20Rate(address token) external view returns (uint256);

    function setETHRate(uint256 rate) external;
    function setERC20Rate(address token, uint256 rate) external;

    function addLiquidity() external payable;
    function removeLiquidity(uint256 ethAmount) external;

    function getETHBalance() external view returns (uint256);
    function getTokenBalance() external view returns (uint256);
    function getSupportedTokens() external view returns (address[] memory);
}