// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IPool {
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;
}

interface IUniswapV2Router {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadlin
    ) external returns (uint[] memory amounts);
}

contract FlashLoanBot {
    address payable public owner;
    IPool public POOL;

    // Dia chi Aave V3 Pool tren Ethereum Mainnet
    address constant AAVE_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address constant UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant WBTC = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    constructor() {
        owner = payable(msg.sender);
        POOL = IPool(AAVE_POOL);
    }

    receive() external payable {}

    function withdrawToken(address _token) external {
        require(msg.sender == owner, "Only owner");
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(owner, balance);
    }

    function withdrawETH() external {
        require(msg.sender == owner, "Only owner");
        (bool success, ) = owner.call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    function requestFlashLoan(address _token, uint256 _amount) external {
        POOL.flashLoanSimple(address(this), _token, _amount, "", 0);
    }

    function executeOperation(
        address asset,
        uint256 amount,
        uint256 premium,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        uint256 myBalance = IERC20(asset).balanceOf(address(this));
        require(myBalance >= amount, "Tien chua ve!");
        // console.log("So du sau khi vay:", myBalance/1e6, "USDC");

        // logic kiem tien
        address[] memory path = new address[](4);
        path[0] = USDC; 
        path[1] = WBTC;
        path[2] = WETH;
        path[3] = USDC;
        IERC20(asset).approve(UNISWAP_ROUTER, amount);
        IUniswapV2Router(UNISWAP_ROUTER).swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountOwed = amount + premium;
        uint256 finalBalance = IERC20(asset).balanceOf(address(this));
        
        console.log("--- KET QUA ARBITRAGE ---");
        console.log("Vay:", amount);
        console.log("Tra:", amountOwed);
        console.log("Thu ve:", finalBalance);

        // tra no
        IERC20(asset).approve(address(POOL), amountOwed);

        return true;
    }
}