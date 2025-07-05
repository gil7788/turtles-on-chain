interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}

interface IFlareContractRegistry {
    function getContractAddressByName(string calldata _name) external view returns (address);
}

interface IFtsoRegistry {
    function getCurrentPriceWithDecimals(string calldata _symbol) external view returns (uint256, uint256, uint256);
}

// Simple mock DEX for testing (since real DEX might not exist on Coston2)
contract SimpleMockDEX {
    mapping(address => mapping(address => uint256)) public exchangeRates;

    event Swap(address indexed from, address indexed to, uint256 amountIn, uint256 amountOut);

    constructor() {
        // Set mock exchange rate: 1 ETH = 2500 USDT (with 18 decimals for ETH, 6 for USDT)
        // This means 1 USDT = 0.0004 ETH
        // Rate stored as: how much ETH you get per USDT (scaled by 1e18)
        // 0.0004 * 1e18 = 400000000000000 (0.0004 ETH per USDT)
    }

    function setExchangeRate(address tokenIn, address tokenOut, uint256 rate) external {
        exchangeRates[tokenIn][tokenOut] = rate;
    }

    function swap(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address to
    ) external returns (uint256 amountOut) {
        require(exchangeRates[tokenIn][tokenOut] > 0, "Exchange rate not set");

        // Calculate output amount
        amountOut = (amountIn * exchangeRates[tokenIn][tokenOut]) / 1e18;
        require(amountOut > 0, "Invalid swap amount");

        // Transfer tokens
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenOut).transfer(to, amountOut);

        emit Swap(tokenIn, tokenOut, amountIn, amountOut);
    }

    function getAmountOut(address tokenIn, address tokenOut, uint256 amountIn)
        external view returns (uint256) {
        if (exchangeRates[tokenIn][tokenOut] == 0) return 0;
        return (amountIn * exchangeRates[tokenIn][tokenOut]) / 1e18;
    }
}

// Simple ERC20 token for testing
contract TestToken {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 public totalSupply;
    string public name;
    string public symbol;
    uint8 public decimals;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");

        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        allowance[from][msg.sender] -= amount;

        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }
}

// Main swap contract
contract SimpleSwapper {
    IFlareContractRegistry public immutable flareRegistry;
    IFtsoRegistry public ftsoRegistry;

    IERC20 public immutable usdt;
    IERC20 public immutable weth;
    SimpleMockDEX public immutable dex;

    uint256 public lastSwapPrice;
    uint256 public lastSwapAmount;
    uint256 public totalSwaps;

    event SwapExecuted(uint256 usdtIn, uint256 ethOut, uint256 ethPrice);
    event ContractFunded(address token, uint256 amount);

    constructor(address _usdt, address _weth, address _dex) {
        flareRegistry = IFlareContractRegistry(0xaD67FE66660Fb8dFE9d6b1b4240d8650e30F6019);
        usdt = IERC20(_usdt);
        weth = IERC20(_weth);
        dex = SimpleMockDEX(_dex);

        // Initialize FTSO registry
        address ftsoRegistryAddr = flareRegistry.getContractAddressByName("FtsoRegistry");
        require(ftsoRegistryAddr != address(0), "FTSO Registry not found");
        ftsoRegistry = IFtsoRegistry(ftsoRegistryAddr);
    }

    function main() external {
        // Get current ETH price from oracle
        (uint256 ethPrice, uint256 timestamp, uint256 decimals) =
            ftsoRegistry.getCurrentPriceWithDecimals("testETH");

        // Get USDT balance of this contract
        uint256 usdtBalance = usdt.balanceOf(address(this));
        require(usdtBalance > 0, "No USDT to swap");

        // Approve DEX to spend USDT
        usdt.approve(address(dex), usdtBalance);

        // Execute swap: USDT -> WETH
        uint256 ethReceived = dex.swap(
            address(usdt),
            address(weth),
            usdtBalance,
            address(this)
        );

        // Update state
        lastSwapPrice = ethPrice;
        lastSwapAmount = ethReceived;
        totalSwaps++;

        emit SwapExecuted(usdtBalance, ethReceived, ethPrice / (10**decimals));
    }

    // View functions
    function getBalances() external view returns (uint256 usdtBal, uint256 wethBal) {
        return (usdt.balanceOf(address(this)), weth.balanceOf(address(this)));
    }

    function getCurrentETHPrice() external view returns (uint256 price, uint256 decimals) {
        (uint256 p, , uint256 d) = ftsoRegistry.getCurrentPriceWithDecimals("testETH");
        return (p, d);
    }

    function getSwapQuote(uint256 usdtAmount) external view returns (uint256 ethAmount) {
        return dex.getAmountOut(address(usdt), address(weth), usdtAmount);
    }

    function getLastSwap() external view returns (uint256 price, uint256 amount, uint256 count) {
        return (lastSwapPrice, lastSwapAmount, totalSwaps);
    }

    // Fund the contract (for testing)
    function fundWithUSDT(uint256 amount) external {
        usdt.transferFrom(msg.sender, address(this), amount);
        emit ContractFunded(address(usdt), amount);
    }
}