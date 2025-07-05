// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "contracts/flare.sol";

// To test call
/*
cast send 0x103416cfCD0D0a32b904Ab4fb69dF6E5B5aaDf2b "updatePrice()" --rpc-url coston2 --private-key $INSERT PK
cast call 0x103416cfCD0D0a32b904Ab4fb69dF6E5B5aaDf2b "prices(uint256)" 0 --rpc-url coston2
cast call 0x103416cfCD0D0a32b904Ab4fb69dF6E5B5aaDf2b "getCurrentPrice()" --rpc-url coston2
cast call 0x103416cfCD0D0a32b904Ab4fb69dF6E5B5aaDf2b "getLatestPrice()" --rpc-url coston2
cast call 0x103416cfCD0D0a32b904Ab4fb69dF6E5B5aaDf2b "getPriceCount()" --rpc-url coston2
cast call 0x103416cfCD0D0a32b904Ab4fb69dF6E5B5aaDf2b "interval()" --rpc-url coston2
cast call 0x103416cfCD0D0a32b904Ab4fb69dF6E5B5aaDf2b "lastUpdate()" --rpc-url coston2
cast call 0x103416cfCD0D0a32b904Ab4fb69dF6E5B5aaDf2b "ftsoRegistry()" --rpc-url coston2
cast call 0x103416cfCD0D0a32b904Ab4fb69dF6E5B5aaDf2b "flareRegistry()" --rpc-url coston2
*/

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();
        
        console.log("=== Deploying Flare ETH Feed on Coston2 ===");
        console.log("Deployer:", msg.sender);
        
        FlareETHFeed feed = new FlareETHFeed(86400);
        console.log("FlareETHFeed deployed to:", address(feed));
        
        // Test with testETH
        (uint256 price, uint256 timestamp, uint256 decimals) = feed.getCurrentPrice();
        console.log("Current testETH price:", price);
        console.log("Price decimals:", decimals);
        console.log("USD value:", price / (10**decimals));
        
        feed.updatePrice();
        console.log("Initial price update completed");
        
        vm.stopBroadcast();
    }
}
