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
        reward = new Reward_4_7(1000000,2,address(myToken));
    }
   
    function testInitialBalance() public {
        console.log(reward.REWARD_AMOUNT());
        assertEq(
            reward.REWARD_AMOUNT(),
            1000000,
            "Initial balance should be 1 million tokens"
        );
    }
    function testDeposit1() public {
        uint initialBalance = reward.REWARD_AMOUNT()+reward.TOTAL_DEPOSITS();
        myToken.mint(200);
        myToken.approve(address(reward), 100);
        reward.deposit(100);
        uint newBalance = reward.REWARD_AMOUNT()+reward.TOTAL_DEPOSITS();
        assertEq(
            newBalance - initialBalance,
            100,
            "Deposit should increase balance by 100 tokens"
        );
    }
  
    function testwithdraw() public {
        myToken.mint(100);
        myToken.approve(address(reward), 100);
        vm.warp(1641070800);
        reward.deposit(100);
        vm.warp(1641070800+8 days);
        reward.withdraw(1);
        assertGt(address(this).balance,100);
    }
        
    //test before 7 days passed
        function testGetBalanceWithReward1() public {
            myToken.mint(200);
            myToken.approve(address(reward), 100);
            vm.warp(1641070800);
            reward.deposit(100);
            uint balanceWithReward = reward.getBalanceWithReward(address(this));
            assertEq(balanceWithReward, 0, "Balance with reward should be accurate");
        }
    // test after 7 days passed
        function testGetBalanceWithReward() public {

            myToken.mint(200);
            myToken.approve(address(reward), 100);
            vm.warp(1641070800);
            reward.deposit(100);
             vm.warp(1641070800+8 days);
            uint balanceWithReward = reward.getBalanceWithReward(address(this));
            assertEq(balanceWithReward, 100, "Balance with reward should be accurate");
       }
}