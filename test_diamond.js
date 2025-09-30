// Simple test to check if Diamond functions work
// Run with: node test_diamond.js

const { ethers } = require('ethers');

// Your deployed Diamond address
const DIAMOND_ADDRESS = "0x400BCC394190117FF7e3Bd8b69d16c9C66Fe6E07";

// Sepolia RPC (you can use any public RPC)
const provider = new ethers.JsonRpcProvider("https://sepolia.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161");

async function testDiamond() {
    console.log("Testing Diamond Contract:", DIAMOND_ADDRESS);
    console.log("");

    // ERC20 ABI for basic functions
    const erc20ABI = [
        "function name() view returns (string)",
        "function symbol() view returns (string)",
        "function totalSupply() view returns (uint256)",
        "function decimals() view returns (uint8)"
    ];

    // Diamond Loupe ABI
    const loupeABI = [
        "function facetAddresses() view returns (address[])",
        "function facetFunctionSelectors(address) view returns (bytes4[])"
    ];

    try {
        console.log("=== Testing ERC20 Functions ===");
        const erc20Contract = new ethers.Contract(DIAMOND_ADDRESS, erc20ABI, provider);

        const name = await erc20Contract.name();
        console.log("✓ Name:", name);

        const symbol = await erc20Contract.symbol();
        console.log("✓ Symbol:", symbol);

        const totalSupply = await erc20Contract.totalSupply();
        console.log("✓ Total Supply:", ethers.formatEther(totalSupply));

        const decimals = await erc20Contract.decimals();
        console.log("✓ Decimals:", decimals.toString());

        console.log("");
        console.log("=== Testing Diamond Loupe Functions ===");

        const loupeContract = new ethers.Contract(DIAMOND_ADDRESS, loupeABI, provider);

        const facetAddresses = await loupeContract.facetAddresses();
        console.log("✓ Facet Addresses:", facetAddresses);

        if (facetAddresses.length > 0) {
            const selectors = await loupeContract.facetFunctionSelectors(facetAddresses[0]);
            console.log("✓ Function Selectors for", facetAddresses[0] + ":", selectors);
        }

        console.log("");
        console.log("🎉 All functions work! The Diamond is properly configured.");
        console.log("The issue is just with Etherscan/Louper interface detection.");

    } catch (error) {
        console.error("❌ Error testing Diamond:", error.message);

        if (error.message.includes("NETWORK_ERROR")) {
            console.log("💡 This might be a network connectivity issue.");
            console.log("Try using a different RPC endpoint or check your internet connection.");
        } else {
            console.log("💡 This might indicate an issue with the Diamond implementation.");
        }
    }
}

testDiamond();