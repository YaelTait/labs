// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Reward_4_7 is ERC20 {
    address public owner;
    uint private REWARD_AMOUNT = 1000000; // 1 million reward tokens
    //uint private constant SEVEN_DAYS_IN_SECONDS = 7 days;
    uint private TOTAL_DEPOSITS = 0;
    uint WAD =10000000000;
    // Struct to hold deposit information
    struct Deposit {
        uint timestamp;
        uint amount;
    }
    
    // Mapping from user address to array of deposits
    mapping(address => Deposit[]) private userDeposits;

    constructor() ERC20("Reward_4_7", "RWD_4_7") {
        owner = msg.sender;
        _mint(msg.sender, REWARD_AMOUNT);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    function deposit(uint _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        transferFrom(msg.sender, address(this), _amount);
        
        userDeposits[msg.sender].push(Deposit(block.timestamp, _amount));
        TOTAL_DEPOSITS += _amount;
    }

function calcRewards(uint _amount) public view returns (uint) {
    if (TOTAL_DEPOSITS == 0) return 0;

    uint rewardPool = (REWARD_AMOUNT * 2*WAD) / 100; // 2% of the reward pool
    uint reward = (_amount * rewardPool) / TOTAL_DEPOSITS;
    return reward;
}

    function withdrawWithReward(uint _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        uint balanceWithReward = getBalanceWithReward(msg.sender);
        require(balanceWithReward >= _amount, "Insufficient available amount for withdrawal with rewards");
        
        uint reward = calcRewards(_amount);
        transferFrom(address(this), msg.sender, _amount + reward);
        REWARD_AMOUNT -= reward;
        TOTAL_DEPOSITS -= _amount;
        
        uint remainingAmount = _amount;
        uint countZero = 0;
        for (uint i = 0; i < userDeposits[msg.sender].length && remainingAmount > 0; i++) {
            if (userDeposits[msg.sender][i].amount <= remainingAmount) {
                remainingAmount -= userDeposits[msg.sender][i].amount;
                userDeposits[msg.sender][i].amount = 0;
                countZero++;
            } else {
                userDeposits[msg.sender][i].amount -= remainingAmount;
                break;
            }
        }
        
        for (uint j = countZero; j < userDeposits[msg.sender].length - 1; j++) {
            userDeposits[msg.sender][j - countZero] = userDeposits[msg.sender][j];
        }
        for (uint j = 0; j < countZero; j++) {
            userDeposits[msg.sender].pop();
        }
    }

    function getBalanceWithReward(address _account) public view returns (uint) {
        uint sum;
        uint latestDate = block.timestamp - 7 days;
        
        for (uint i = 0; i < userDeposits[_account].length; i++) {
            if (userDeposits[_account][i].timestamp < latestDate) {
                sum += userDeposits[_account][i].amount;
            }
        }
        return sum;
    }

    function getTotalBalance(address _account) public view returns (uint) {
        uint totalBalance;
        
        for (uint i = 0; i < userDeposits[_account].length; i++) {
            totalBalance += userDeposits[_account][i].amount;
        }
        return totalBalance;
    }
}
