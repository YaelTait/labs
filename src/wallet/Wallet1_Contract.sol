pragma solidity >=0.6.12 <0.9.0;

contract ReceiveEther {
    // Event to log the deposit to blockchain
    event Deposit(address indexed sender, uint256 amount);
    // Event to log the withdrawal from the contract
    event Withdrawal(address indexed recipient, uint256 amount);

    address owner;

    constructor() {
        owner = msg.sender;
    }
    // Function to receive Ether happen when u get eth  in the deploy
    // external - u can access it from everywhere
    // payable - it get eth

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    // Function to check the contract's balance
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Function to withdraw Ether from the contract
    function withdraw(uint256 amount) public {
        require(amount > 0, "Withdrawal amount must be greater than 0");
        require(amount <= address(this).balance, "Insufficient contract balance");
        require(msg.sender == owner, "You are not allowed to withdraw");
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }
}
