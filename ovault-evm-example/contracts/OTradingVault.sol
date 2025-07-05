// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import { MyOVault } from "./MyOVault.sol";
import { FlareETHFeed } from "./Flare.sol";
import { TradingStrategy } from "./Strategy.sol";

contract OTradingVault {
    MyOVault public vault;
    FlareETHFeed public feed;
    TradingStrategy public strategy;

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
        // 1. Get the previous price
        (uint256 prevPrice, , uint256 decimals) = feed.getLatestPrice();

        // 2. Update price
        updatePrice();

        // 3. Get the updated/latest price
        (uint256 newPrice, , ) = feed.getLatestPrice();

        // 4. Calculate % change (assuming no decimals shift)
        if (prevPrice == 0 || newPrice == 0) return;

        int256 priceChange = int256(newPrice) - int256(prevPrice);
        int256 priceChangePct = (priceChange * int256(10 ** decimals)) / int256(prevPrice); // scaled %

        // 5. Call trading strategy (buy/sell/hold)
        strategy.evaluateAndExecute(priceChangePct, address(vault));
    }
}
