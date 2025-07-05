interface IFlareContractRegistry {
    function getContractAddressByName(string calldata _name) external view returns (address);
}

interface IFtsoRegistry {
    function getCurrentPriceWithDecimals(string calldata _symbol) external view returns (uint256, uint256, uint256);
}

contract FlareETHFeed {
    IFlareContractRegistry public immutable flareRegistry;
    IFtsoRegistry public ftsoRegistry;
    uint256 public interval;

    struct Price {
        uint256 price;
        uint256 timestamp;
        uint256 decimals;
    }

    Price[] public prices;
    uint256 public lastUpdate;

    event PriceUpdated(uint256 price, uint256 timestamp, uint256 decimals);

    constructor(uint256 _interval) {
        flareRegistry = IFlareContractRegistry(0xaD67FE66660Fb8dFE9d6b1b4240d8650e30F6019);
        interval = _interval;

        address ftsoRegistryAddr = flareRegistry.getContractAddressByName("FtsoRegistry");
        require(ftsoRegistryAddr != address(0), "FTSO Registry not found");
        ftsoRegistry = IFtsoRegistry(ftsoRegistryAddr);
    }

    function updatePrice() external {
        // if (block.timestamp < lastUpdate + interval) return;

        // Use "testETH" instead of "ETH" for Coston2
        (uint256 price, uint256 timestamp, uint256 decimals) =
            ftsoRegistry.getCurrentPriceWithDecimals("testETH");

        prices.push(Price(price, timestamp, decimals));
        lastUpdate = block.timestamp;

        emit PriceUpdated(price, timestamp, decimals);

        if (prices.length > 14) {
            for (uint i = 0; i < prices.length - 1; i++) {
                prices[i] = prices[i + 1];
            }
            prices.pop();
        }
    }

    function getLatestPrice() external view returns (uint256 price, uint256 timestamp, uint256 decimals) {
        if (prices.length == 0) return (0, 0, 0);
        Price memory latest = prices[prices.length - 1];
        return (latest.price, latest.timestamp, latest.decimals);
    }

    function getPriceCount() external view returns (uint256) {
        return prices.length;
    }

    function getCurrentPrice() external view returns (uint256, uint256, uint256) {
        return ftsoRegistry.getCurrentPriceWithDecimals("testETH");
    }
}