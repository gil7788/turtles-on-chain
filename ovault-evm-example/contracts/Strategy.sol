interface ISparkDEXRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

contract TradingStrategy {
    ISparkDEXRouter public immutable sparkRouter;
    IERC20 public immutable usdt;
    IERC20 public immutable weth;

    uint256 public interval;
    uint256 public buyLookbackPeriods = 20;
    uint256 public sellLookbackPeriods = 10;
    uint256 public ethPosition;
    bool public hasPosition;

    struct Price {
        uint256 price;
        uint256 timestamp;
        uint256 decimals;
    }

    uint256 public lastUpdate;

    event PriceUpdated(uint256 price, uint256 timestamp, uint256 decimals);
    event PositionOpened(uint256 ethBought, uint256 usdtSpent);
    event PositionClosed(uint256 ethSold, uint256 usdtReceived);

    constructor(
        uint256 _interval,
        uint256 _buyLookbackPeriods,
        uint256 _sellLookbackPeriods,
        address _sparkRouter,
        address _usdt,
        address _weth
    ) {
        interval = _interval;
        buyLookbackPeriods = _buyLookbackPeriods;
        sellLookbackPeriods = _sellLookbackPeriods;
        sparkRouter = ISparkDEXRouter(_sparkRouter);
        usdt = IERC20(_usdt);
        weth = IERC20(_weth);
    }

    function main(Price[] calldata prices) external {
        executeStrategy(prices);
    }

    function executeStrategy(Price[] calldata prices) internal {
        if (prices.length < buyLookbackPeriods) return;

        // Buy signal: current price > all last buyLookbackPeriods
        if (!hasPosition && shouldBuy(prices)) {
            buyETH();
        }

        // Sell signal: current price < all last sellLookbackPeriods
        if (hasPosition && shouldSell(prices)) {
            sellETH();
        }
    }

    function shouldBuy(Price[] calldata prices) internal view returns (bool) {
        uint256 currentPrice = getCurrentPrice(prices);
        if (prices.length < buyLookbackPeriods) return false;

        uint256 startIndex = prices.length - buyLookbackPeriods;
        for (uint256 i = startIndex; i < prices.length - 1; i++) {
            if (currentPrice <= prices[i].price) {
                return false;
            }
        }
        return true;
    }

    function shouldSell(Price[] calldata prices) internal view returns (bool) {
        uint256 currentPrice = getCurrentPrice(prices);
        if (prices.length < sellLookbackPeriods) return false;

        uint256 startIndex = prices.length - sellLookbackPeriods;
        for (uint i = startIndex; i < prices.length - 1; i++) {
            if (currentPrice >= prices[i].price) {
                return false;
            }
        }
        return true;
    }

    function buyETH() internal {
        uint256 usdtBalance = usdt.balanceOf(address(this));
        if (usdtBalance == 0) return;

        address[] memory path = new address[](2);
        path[0] = address(usdt);
        path[1] = address(weth);

        usdt.approve(address(sparkRouter), usdtBalance);

        uint256[] memory amounts = sparkRouter.swapExactTokensForTokens(
            usdtBalance,
            0,
            path,
            address(this),
            block.timestamp + 300
        );

        ethPosition = amounts[1];
        hasPosition = true;

        emit PositionOpened(amounts[1], usdtBalance);
    }

    function buyMoreETH() internal {
        uint256 usdtBalance = usdt.balanceOf(address(this));
        if (usdtBalance == 0) return;

        uint256 amountToSpend = usdtBalance / 4; // 25% of remaining USDT
        if (amountToSpend < 1e18) return; // Minimum 1 USDT

        address[] memory path = new address[](2);
        path[0] = address(usdt);
        path[1] = address(weth);

        usdt.approve(address(sparkRouter), amountToSpend);

        uint256[] memory amounts = sparkRouter.swapExactTokensForTokens(
            amountToSpend,
            0,
            path,
            address(this),
            block.timestamp + 300
        );

        ethPosition += amounts[1];

        emit PositionOpened(amounts[1], amountToSpend);
    }

    function sellETH() internal {
        if (ethPosition == 0) return;

        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(usdt);

        weth.approve(address(sparkRouter), ethPosition);

        uint256[] memory amounts = sparkRouter.swapExactTokensForTokens(
            ethPosition,
            0,
            path,
            address(this),
            block.timestamp + 300
        );

        emit PositionClosed(ethPosition, amounts[1]);

        ethPosition = 0;
        hasPosition = false;
    }

    /// @notice Returns the most recent price from the prices array
    function getCurrentPrice(Price[] calldata prices) internal pure returns (uint256) {
        require(prices.length > 0, "No prices available");
        return prices[prices.length - 1].price;
    }
}
