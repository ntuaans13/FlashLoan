// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/console.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// Interface của Aave Pool (Để gọi hàm vay)
interface IPool {
    function flashLoanSimple(
        address receiverAddress,
        address asset,
        uint256 amount,
        bytes calldata params,
        uint16 referralCode
    ) external;
}

contract FlashLoanBot {
    address payable public owner;
    IPool public POOL;

    // Địa chỉ Aave V3 Pool trên Ethereum Mainnet (Dùng cái này nếu fork mainnet)
    // Nếu dùng testnet Sepolia thì thay địa chỉ khác
    address constant AAVE_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2; 

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

        // logic kiem tien

        uint256 amountOwed = amount + premium;
        IERC20(asset).approve(address(POOL), amountOwed);

        return true;
    }
}