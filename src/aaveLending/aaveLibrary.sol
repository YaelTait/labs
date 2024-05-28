// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface ILendingPool {
    function deposit(
        address asset,//l;l;
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

interface IWETHGateway {
    function depositETH(
        address lendingPool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    function withdrawETH(
        address lendingPool,
        uint256 amount,
        address onBehalfOf
    ) external;
}

library AaveLibrary {
    function depositToAave(
        ILendingPool aave,
        address asset,
        uint256 amount,
        address onBehalfOf
    ) internal {
        IERC20(asset).approve(address(aave), amount);
        aave.deposit(asset, amount, onBehalfOf, 0);
    }

    function withdrawFromAave(
        ILendingPool aave,
        address asset,
        uint256 amount,
        address to
    ) internal returns (uint256) {
        return aave.withdraw(asset, amount, to);
    }

    function depositWethToAave(
        IWETHGateway wethGateway,
        address aave,
        uint256 amount,
        address onBehalfOf
    ) internal {
        wethGateway.depositETH{value: amount}(aave, onBehalfOf, 0);
    }

    function withdrawWethFromAave(
        IWETHGateway wethGateway,
        address aave,
        uint256 amount,
        address to
    ) internal {
        wethGateway.withdrawETH(aave, amount, to);
    }
}