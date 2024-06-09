// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "src/staking/staking2.sol";
import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";
import "@hack/staking/MyToken.sol";

contract TestStakingRewards is Test {
    StakingRewards rewardsContract;
    MyToken stakingToken;
    MyToken rewardsToken;

    function setUp() public {
        stakingToken = new MyToken();
        rewardsToken = new MyToken();
        rewardsContract = new StakingRewards(address(stakingToken), address(rewardsToken));
    }

    function testStake() public {
        stakingToken.mint(1000);
        stakingToken.approve(address(rewardsContract), 1000);
        rewardsContract.stake(500);
        assertEq(rewardsContract.balances(address(this)), 500, "Staking should increase user balance");
        assertEq(rewardsContract.staked(), 500, "Total staked amount should increase");
    }

    function testWithdraw() public {
        stakingToken.mint(1000);
        stakingToken.approve(address(rewardsContract), 1000);
        rewardsContract.stake(500);
        rewardsContract.withdraw(200);
        assertEq(rewardsContract.balances(address(this)), 300, "Withdrawal should decrease user balance");
        assertEq(rewardsContract.staked(), 300, "Total staked amount should decrease");
    }

    // function testGetReward() public {
    //     rewardsToken.mint(1000);
    //     rewardsToken.transfer(address(rewardsContract), 1000);
    //     rewardsContract.getReward();
    //     assertEq(
    //         rewardsToken.balanceOf(address(this)),
    //         1000,
    //         "User should receive rewards"
    //     );
    // }

    function testSetRewardsDuration() public {
        rewardsContract.setRewardsDuration(14 days);
        assertEq(rewardsContract.duration(), 14 days, "Rewards duration should be updated");
    }

    function testUpdateRate() public {
        rewardsContract.setRewardsDuration(7 days);

        rewardsContract.updateRate(7 days + 100);
        assertEq(rewardsContract.rate(), (7 days) / rewardsContract.duration(), "Reward rate should be updated");
    }

    function testLastTime() public {
        uint256 currentTime = block.timestamp;
        rewardsContract.setRewardsDuration(7 days);
        rewardsContract.updateRate(100); // Just to make sure lastTime() considers the finish time

        uint256 finishTime = currentTime + 7 days;
        vm.warp(finishTime + 1); // Move time past finish time
        assertEq(rewardsContract.lastTime(), finishTime, "Last time should be finish time");
    }

    function testAccumulated() public {
        stakingToken.mint(1000);
        stakingToken.approve(address(rewardsContract), 1000);
        rewardsContract.stake(500);
        rewardsContract.setRewardsDuration(7 days);
        rewardsContract.updateRate(100);

        uint256 initialAccumulated = rewardsContract.accumulated();
        console.log("before", initialAccumulated);

        vm.warp(block.timestamp + 1 days);
        uint256 afterOneDay = rewardsContract.accumulated();

        console.log("afterOneDay", afterOneDay);

        assertEq(afterOneDay, initialAccumulated + 100 * 1 days, "Accumulated should increase based on rate and time");
    }

    function testEarned() public {
        stakingToken.mint(1000);
        stakingToken.approve(address(rewardsContract), 1000);
        rewardsContract.stake(500);
        rewardsContract.updateRate(100);
        rewardsContract.setRewardsDuration(7 days);
        vm.warp(block.timestamp + 1 days);
        uint256 earnedAfterOneDay = rewardsContract.earned(address(this));
        assertEq(
            earnedAfterOneDay, 100 * 1 days, "Earned should be accurate based on staked amount and accumulated rewards"
        );
    }
}
