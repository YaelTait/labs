// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "src/staking/staking.sol";
import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@hack/staking/MyToken.sol";

// /root/labs/src/staking/staking.sol
contract TestReward is Test {
    Reward_4_7 reward;
    MyToken myToken;

    function setUp() public {
        myToken = new MyToken();
        reward = new Reward_4_7(1000000, 2, address(myToken));
    }

    function testDepositReward(uint256 depositAmount) public {
        vm.assume(depositAmount > 0 && depositAmount <= 1000 ether); // Deposit amount should be positive and less than or equal to 1000 ether

        uint256 initialBalance = reward.REWARD_AMOUNT() + reward.TOTAL_DEPOSITS();
        myToken.approve(address(reward), depositAmount);
        myToken.mint(depositAmount);

        reward.deposit(depositAmount);
        uint256 newBalance = reward.REWARD_AMOUNT() + reward.TOTAL_DEPOSITS();
        assertEq(newBalance - initialBalance, depositAmount, "Deposit should increase balance by 100 tokens");
    }

    function testwithdrawStakingFuzz(uint256 withdrawAmount) public {
        vm.assume(withdrawAmount > 0 && withdrawAmount < 1000);
        console.log("reward", address(reward));
        console.log("TestReward", address(this));
        console.log("myToken", address(reward));
        myToken.mint(withdrawAmount);
        myToken.approve(address(reward), withdrawAmount);
        vm.warp(1641070800);
        reward.deposit(withdrawAmount);
        vm.warp(1641070800 + 8 days);
        reward.withdraw(withdrawAmount);
        assertGt(address(this).balance, withdrawAmount);
    }
}
