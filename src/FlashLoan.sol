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
        console.log("So du sau khi vay:", myBalance/1e6, "USDC");

        // logic kiem tien
        address[] memory path = new address[](2); // USDC -> WETH
        path[0] = asset;
        path[1] = WETH;
        IERC20(asset).approve(UNISWAP_ROUTER, amount);
        IUniswapV2Router(UNISWAP_ROUTER).swapExactTokensForTokens(
            amount,
            0,
            path,
            address(this),
            block.timestamp
        );
        myBalance = IERC20(asset).balanceOf(address(this));
        console.log("So du sau khi trade:", myBalance/1e6, "USDC");

        uint wethBalance = IERC20(WETH).balanceOf(address(this));
        console.log("Luong WETH trade duoc", wethBalance/1e18, "WETH");

        address[] memory pathBack = new address[](2); // WETH -> USDC
        pathBack[0] = WETH;
        pathBack[1] = asset;
        IERC20(WETH).approve(UNISWAP_ROUTER, wethBalance);
        IUniswapV2Router(UNISWAP_ROUTER).swapExactTokensForTokens(
            wethBalance,
            0,
            pathBack,
            address(this),
            block.timestamp
        );

        myBalance = IERC20(asset).balanceOf(address(this));
        console.log("So du sau khi trade back:", myBalance/1e6, "USDC");

        wethBalance = IERC20(WETH).balanceOf(address(this));
        console.log("Luong WETH trade back", wethBalance/1e18, "WETH");

        uint256 amountOwed = amount + premium;
        IERC20(asset).approve(address(POOL), amountOwed);

        return true;
    }
}