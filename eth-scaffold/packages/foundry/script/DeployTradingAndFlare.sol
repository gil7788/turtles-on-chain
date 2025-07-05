// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "contracts/tradingAndFlare.sol";


contract Deploy is Script {
    function run() external {
        vm.startBroadcast();

        console.log("=== Deploying Turtle Trading Strategy on Coston2 ===");
        console.log("Deployer:", msg.sender);
        console.log("Ultra-fast trading: 4 second intervals (2x block time)");

        // SparkDEX V3.1 Router on Coston2
        address sparkRouter = 0x4a1E5A90e9943467FAd1acea1E7F0e5e88472a1e; // UniswapV2Router02
        address usdtAddress = 0xC1A5B41512496B80903D1f32d6dEa3a73212E71F; // USDT token address
        address wethAddress = 0xE1842E54D5F2D6E230Ee09c68366F2cE395A8849; // Coston2 WETH address

        FlareETHFeed feed = new FlareETHFeed(
            4,      // 4 second interval (2 × 1.8s block time)
            20,     // Buy lookback periods (20 × 4s = 80 seconds)
            10,     // Sell lookback periods (10 × 4s = 40 seconds)
            sparkRouter,
            usdtAddress,
            wethAddress
        );

        console.log("TurtleTradingStrategy deployed to:", address(feed));

        (uint256 price, uint256 timestamp, uint256 decimals) = feed.getCurrentPrice();
        console.log("Current testETH price:", price);
        console.log("Price decimals:", decimals);

        feed.main();
        console.log("Initial main() call completed");

        vm.stopBroadcast();
    }
}