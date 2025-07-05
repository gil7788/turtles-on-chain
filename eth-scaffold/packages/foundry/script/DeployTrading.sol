// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "contracts/trading.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        console.log("=== Deploying Simple Swap System on Coston2 ===");
        console.log("Deployer:", msg.sender);

        // 1. Deploy test tokens
        TestToken usdt = new TestToken(
            "Test USDT",
            "USDT",
            6,
            1000000 * 10**6  // 1M USDT
        );

        TestToken weth = new TestToken(
            "Test WETH",
            "WETH",
            18,
            1000 * 10**18    // 1K WETH
        );

        console.log("USDT deployed to:", address(usdt));
        console.log("WETH deployed to:", address(weth));

        // 2. Deploy mock DEX
        SimpleMockDEX dex = new SimpleMockDEX();
        console.log("Mock DEX deployed to:", address(dex));

        // 3. Set up exchange rate (1 USDT = 0.0004 ETH, assuming ETH = $2500)
        uint256 exchangeRate = 400000000000000; // 0.0004 ETH per USDT
        dex.setExchangeRate(address(usdt), address(weth), exchangeRate);
        console.log("Exchange rate set: 1 USDT = 0.0004 ETH");

        // 4. Fund DEX with WETH
        uint256 dexWethAmount = 100 * 10**18; // 100 WETH
        weth.transfer(address(dex), dexWethAmount);
        console.log("DEX funded with WETH:", dexWethAmount);

        // 5. Deploy swap contract
        SimpleSwapper swapper = new SimpleSwapper(
            address(usdt),
            address(weth),
            address(dex)
        );
        console.log("SimpleSwapper deployed to:", address(swapper));

        // 6. Fund swapper with USDT for testing
        uint256 swapperUsdtAmount = 1000 * 10**6; // 1000 USDT
        usdt.transfer(address(swapper), swapperUsdtAmount);
        console.log("Swapper funded with USDT:", swapperUsdtAmount);

        // 7. Test the setup
        console.log("");
        console.log("=== Testing Setup ===");

        // Check ETH price
        (uint256 ethPrice, uint256 decimals) = swapper.getCurrentETHPrice();
        console.log("Current ETH price:", ethPrice / (10**decimals));

        // Check balances
        (uint256 usdtBal, uint256 wethBal) = swapper.getBalances();
        console.log("Swapper USDT balance:", usdtBal);
        console.log("Swapper WETH balance:", wethBal);

        // Get swap quote
        uint256 quote = swapper.getSwapQuote(100 * 10**6); // 100 USDT
        console.log("Quote for 100 USDT:", quote);

        // Execute first swap
        console.log("");
        console.log("=== Executing Test Swap ===");
        swapper.main();

        // Check results
        (uint256 newUsdtBal, uint256 newWethBal) = swapper.getBalances();
        console.log("After swap - USDT:", newUsdtBal);
        console.log("After swap - WETH:", newWethBal);

        (uint256 lastPrice, uint256 lastAmount, uint256 swapCount) = swapper.getLastSwap();
        console.log("Last swap price:", lastPrice);
        console.log("Last swap amount:", lastAmount);
        console.log("Total swaps:", swapCount);

        console.log("");
        console.log("Deployment and test completed successfully!");
        console.log("SimpleSwapper address:", address(swapper));

        vm.stopBroadcast();
    }
}