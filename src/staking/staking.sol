// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/console.sol";
import "@hack/staking/MyToken.sol";

contract Reward_4_7 {
    address public owner;
    uint256 public REWARD_AMOUNT; // 1 million reward tokens
    uint256 public TOTAL_DEPOSITS = 0;
    uint256 WAD = 10000000000;
    uint256 BPS = 10000;
    uint256 PERCENT;
    MyToken myToken;
    // Struct to hold deposit information

    struct Deposit {
        uint256 timestamp;
        uint256 amount;
    }
    // Mapping from user address to array of deposits

    mapping(address => Deposit[]) private userDeposits;

    constructor(uint256 reward, uint256 percent, address token) {
        REWARD_AMOUNT = reward;
        PERCENT = percent;
        owner = msg.sender;
        myToken = MyToken(token);
        myToken.mint(REWARD_AMOUNT);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    function deposit(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        console.log("address 1", (msg.sender));
        myToken.transferFrom(msg.sender, address(myToken), _amount);
        userDeposits[msg.sender].push(Deposit(block.timestamp, _amount));
        console.log("sssssssss", msg.sender);
        TOTAL_DEPOSITS += _amount;
    }

    function calcRewards(uint256 _amount) public view returns (uint256) {
        console.log(msg.sender, "calc");
        if (TOTAL_DEPOSITS == 0) return 0;

        return REWARD_AMOUNT * WAD * (PERCENT / 100) * (_amount / TOTAL_DEPOSITS) / WAD;
    }

    function withdraw(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        uint256 balanceWithReward = getBalanceWithReward(msg.sender);
        require(balanceWithReward >= _amount, "Insufficient available amount for withdrawal with rewards");
        uint256 reward = calcRewards(_amount);
        myToken.transfer(msg.sender, _amount + reward);
        REWARD_AMOUNT -= reward;
        TOTAL_DEPOSITS -= _amount;
        uint256 remainingAmount = _amount;
        uint256 countZero = 0;
        for (uint256 i = 0; i < userDeposits[msg.sender].length && remainingAmount > 0; i++) {
            if (userDeposits[msg.sender][i].amount <= remainingAmount) {
                remainingAmount -= userDeposits[msg.sender][i].amount;
                userDeposits[msg.sender][i].amount = 0;
                countZero++;
            } else {
                userDeposits[msg.sender][i].amount -= remainingAmount;
                break;
            }
        }
        for (uint256 j = countZero; j < userDeposits[msg.sender].length - 1; j++) {
            userDeposits[msg.sender][j - countZero] = userDeposits[msg.sender][j];
        }
        for (uint256 j = 0; j < countZero; j++) {
            userDeposits[msg.sender].pop();
        }
    }

    function getBalanceWithReward(address _account) public view returns (uint256) {
        uint256 sum = 0;
        console.log("hrrrrrrrrru", _account);
        //console.log(7 days);
        uint256 latestDate = block.timestamp - 7 days;
        for (uint256 i = 0; i < userDeposits[_account].length; i++) {
            console.log("@@@", userDeposits[_account][i].amount);

            if (userDeposits[_account][i].timestamp < latestDate) {
                sum += userDeposits[_account][i].amount;
            }
        }
        return sum;
    }
}
