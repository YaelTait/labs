// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILendingPool {
    function deposit(
        address asset, //token
        uint256 amount, // amount
        address onBehalfOf, //msg.sender
        uint16 referralCode //?
    ) external;

    function withdraw(
        address asset, //token
        uint256 amount, //amount
        address to // msg.sender
    ) external returns (uint256);
}

interface IWETHGateway { //wrap eth
    function depositETH(
        address lendingPool,
        address onBehalfOf,
        uint16 referralCode //?
    ) external payable;

    function withdrawETH(address lendingPool, uint256 amount, address onBehalfOf) external;
}

library AaveLibrary {
    ILendingPool public constant aave = ILendingPool(0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe);
    IWETHGateway public constant wethGateway = IWETHGateway(0xA61ca04DF33B72b235a8A28CfB535bb7A5271B70);
    IERC20 public constant dai = IERC20(0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD);
    IERC20 public constant aDai = IERC20(0xdCf0aF9e59C002FA3AA091a46196b37530FD48a8);
    IERC20 public constant aWeth = IERC20(0x87b1f4cf9BD63f7BBD3eE1aD04E8F52540349347);

    function sendDaiToAave(uint256 _amount) internal {
        dai.approve(address(aave), _amount);
        aave.deposit(address(dai), _amount, address(this), 0);
    }

    function withdrawDaiFromAave(uint256 _amount) internal {
        aave.withdraw(address(dai), _amount, msg.sender);
    }

    function sendWethToAave(uint256 _amount) internal {
        wethGateway.depositETH{value: _amount}(address(aave), address(this), 0);
    }

    function withdrawWethFromAave(uint256 _amount) internal {
        aWeth.approve(address(wethGateway), _amount);
        wethGateway.withdrawETH(address(aave), _amount, address(this));
    }
}
