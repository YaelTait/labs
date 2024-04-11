// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/console.sol";
import "@hack/staking/MyToken.sol";
contract Reward_4_7{
    address public owner;
    uint public REWARD_AMOUNT ; // 1 million reward tokens
    uint public TOTAL_DEPOSITS = 0;
    uint WAD = 10000000000;
    uint BPS=10000;
    uint PERCENT;
    MyToken myToken;
    // Struct to hold deposit information
    struct Deposit {
        uint timestamp;
        uint amount;
    }
    // Mapping from user address to array of deposits
    mapping(address => Deposit[]) private userDeposits;
    constructor(uint reward,uint percent,address token)  {
        REWARD_AMOUNT=reward;
        PERCENT=percent;
        owner = msg.sender;
        myToken= MyToken(token);
        myToken.mint( REWARD_AMOUNT);
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }
    function deposit(uint _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        console.log("address 1" , (msg.sender));
        myToken.transferFrom(msg.sender, address(myToken), _amount);
        userDeposits[msg.sender].push(Deposit(block.timestamp, _amount));
    console.log("sssssssss",msg.sender);
        TOTAL_DEPOSITS += _amount;
    }
    function calcRewards(uint _amount) public view returns (uint) {
        console.log(msg.sender,"calc");
      if (TOTAL_DEPOSITS == 0) return 0;
     
      return  REWARD_AMOUNT*WAD*(PERCENT/100)*(_amount/TOTAL_DEPOSITS)/WAD;
    }
    function withdraw(uint _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        uint balanceWithReward = getBalanceWithReward(msg.sender);
        require(
            balanceWithReward >= _amount,
            "Insufficient available amount for withdrawal with rewards"
        );
        uint reward = calcRewards(_amount);
        myToken.transfer(msg.sender, _amount + reward);
        REWARD_AMOUNT -= reward;
        TOTAL_DEPOSITS -= _amount;
        uint remainingAmount = _amount;
        uint countZero = 0;
        for (
            uint i = 0;
            i < userDeposits[msg.sender].length && remainingAmount > 0;
            i++
        ) {
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
            userDeposits[msg.sender][j - countZero] = userDeposits[msg.sender][
                j
            ];
        }
        for (uint j = 0; j < countZero; j++) {
            userDeposits[msg.sender].pop();
        }
    }
    function getBalanceWithReward(address _account) public view returns (uint) {
        uint sum = 0;
      console.log("hrrrrrrrrru", _account);
        //console.log(7 days);
        uint latestDate = block.timestamp - 7 days;
        for (uint i = 0; i < userDeposits[_account].length; i++) {
            console.log("@@@",userDeposits[_account][i].amount);

            if (userDeposits[_account][i].timestamp< latestDate) {
                sum += userDeposits[_account][i].amount;
            }
        }
        return sum;
    }
}
