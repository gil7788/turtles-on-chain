// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "contracts/trading.sol";

contract SparkDEXTraderTest is Test {
    trading trader;
    address mockRouter = address(0x123);
    address owner;

    function setUp() public {
        owner = address(this);
        trader = new SparkDEXTrader(mockRouter);
    }

    function testDeployment() public {
        assertEq(trader.getFLRBalance(), 0);
    }

    function testFundContract() public {
        trader.fundContract{value: 1 ether}();
        assertEq(trader.getFLRBalance(), 1 ether);
    }

    function testWithdrawFLR() public {
        trader.fundContract{value: 1 ether}();
        uint balanceBefore = address(this).balance;

        trader.withdrawFLR(0.5 ether);

        assertEq(address(this).balance, balanceBefore + 0.5 ether);
        assertEq(trader.getFLRBalance(), 0.5 ether);
    }

    function testOnlyOwner() public {
        vm.prank(address(0x456));
        vm.expectRevert("Not owner");
        trader.withdrawFLR(1 ether);
    }

    receive() external payable {}
}