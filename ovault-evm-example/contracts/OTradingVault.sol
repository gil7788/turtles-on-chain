// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { MyOVault } from "./MyOVault.sol";
import { FlareETHFeed } from "./Flare.sol";
import { TradingStrategy } from "./Strategy.sol";

contract OTradingVault {
    MyOVault public vault;
    FlareETHFeed public feed;
    TradingStrategy public strategy;

    struct Price {
        uint256 price;
        uint256 timestamp;
        uint256 decimals;
    }

    constructor(
        string memory name,
        string memory symbol,
        address asset,
        uint256 updateInterval,
        address strategyAddress
    ) {
        vault = new MyOVault(name, symbol, asset);
        feed = new FlareETHFeed(updateInterval);
        strategy = TradingStrategy(strategyAddress);
    }

    function updatePrice() public {
        feed.updatePrice();
    }

    function getVaultAddress() external view returns (address) {
        return address(vault);
    }

    function getLatestPrice() external view returns (uint256, uint256, uint256) {
        return feed.getLatestPrice();
    }

    function trade() external {
        updatePrice();
        Price[] memory latestPrices = feed.getLatestPrices();
        strategy.main(latestPrices);
    }
}