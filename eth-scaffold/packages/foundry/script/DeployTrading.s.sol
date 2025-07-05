// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "contracts/trading.sol";

contract Deploy is Script {
    function run() external {
        // SparkDEX V3.1 Swap Router on Flare Mainnet
        // Source: https://docs.sparkdex.ai/additional-information/smart-contract-overview/v2-and-v3.1-dex
        address ROUTER_ADDRESS = 0x8a1E35F5c98C4E85B36B7B253222eE17773b2781;

        vm.startBroadcast();

        SparkDEXTrader trader = new SparkDEXTrader(ROUTER_ADDRESS);

        vm.stopBroadcast();

        console.log("SparkDEXTrader deployed to:", address(trader));
    }
}