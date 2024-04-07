// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@hack/like/IERC20.sol";
contract DepositAndReward {
    IERC20 public immutable erc20;
    address public owner;
    uint private  REWARD_AMOUNT = 1000000
    // * 10**18; // 1 million reward tokens
    uint private constant SEVEN_DAYS_IN_SECONDS = 7 * 24 * 60 * 60;
    uint private constant TOTAL_DEPOSITS = 0;
    // User address => deposit information =>date=>amount
    mapping(address => mapping(uint => uint)) public deposits;
    // User address => timestamp of last deposit
    //mapping(address => uint) public lastDepositTime;
    constructor(address token) {
        owner = msg.sender;
        erc20 = IERC20(token);
        // Transfer reward tokens to this contract
        erc20.transferFrom(msg.sender, address(this), REWARD_AMOUNT);
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "not authorized");
        _;
    }
    function deposit(uint _amount) external {
        require(_amount > 0, "amount = 0");
        erc20.transferFrom(msg.sender, address(this), _amount);
        deposits[msg.sender][block.timestamp] = _amount;
        TOTAL_DEPOSITS+=_amount;
    }
function calc_rewards(uint _amount) private {
        reward=_amount/TOTAL_DEPOSITS *REWARD_AMOUNT/10;
    }
    function withdrawWithReward(uint _amount) external {
    require(_amount > 0, "amount = 0");
    uint BalnceWithReward = getBalnceWithReward(msg.sender);
    require(BalnceWithReward >= _amount, "insufficient available amount for withdrawal with rewards");
    uint reward=calc_rewards(_amount);
    erc20.transfer(address(this),msg.sender, _amount+reward);
    TOTAL_DEPOSITS-=_amount;
    REWARD_AMOUNT -=reward;
   for (uint i = 0; i < deposits[_account].length && _amount>0; i++) {
    tempAmount=deposits[_account][i];
    if(tempAmount<amount){
    amount-=tempAmount;
    deposits[_account][i]=0;
    //delete the element by loop!
    }
    else{
         deposits[_account][i]-=tempAmount;
         amount=0;
    }    
    }
}
        function withdrawWithoutReward(uint _amount) external {
        }
    function getBalnceWithReward(address _account) public view returns (uint) {
        uint sum;
        uint latestDate = block.timestamp - SEVEN_DAYS_IN_SECONDS;
        // Iterate over deposits for the given account
        for (uint i = 0; i < deposits[_account].length; i++) {
            // Check if the deposit date is at least 7 days ago
            if (i < latestDate) {
                sum += deposits[_account][i];
            } else {
                // If the date is less than seven days ago, exit the loop
                break;
            }
        }
        return sum;
    }
    }
    function getTotalBalance(address _account) public view returns (uint) {
    uint totalBalance;
    // Iterate over all timestamps in the deposits mapping for the specified account
    // and sum up all the deposit amounts
    for (uint i = 0; i < deposits[_account].length; i++) {
        totalBalance += deposits[_account][i];
    }
    return totalBalance;
}
}