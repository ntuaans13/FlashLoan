// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {FlashLoanBot} from "../src/FlashLoan.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "forge-std/console.sol";

contract FlashLoanTest is Test {
    FlashLoanBot bot;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    uint256 constant AMOUNT_TO_BORROW = 1000000 * 1e6;

    function setUp() public {
        vm.createSelectFork("https://eth-mainnet.g.alchemy.com/v2/B2LCj03vGryZS23EuCr6D");
        bot = new FlashLoanBot();
        assertGt(address(bot.POOL()).code.length, 0);
    }

    function testExecuteFlashLoan() public {
        uint256 fee = 10000 * 1e6;
        deal(USDC, address(bot), fee);
        
        uint256 balanceBefore = IERC20(USDC).balanceOf(address(bot));
        
        bot.requestFlashLoan(USDC, AMOUNT_TO_BORROW);
        
        uint256 balanceAfter = IERC20(USDC).balanceOf(address(bot));
    }

}