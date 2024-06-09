pragma solidity >=0.6.12 <0.9.0;

import "forge-std/console.sol";

/**
 * Getting authorized withdrawers in the constructor:**
 *
 * Pros:
 *
 * Immutability**: Once set in the constructor, the authorized withdrawers cannot be changed, ensuring that the contract's behavior is predictable and cannot be altered after deployment.
 * 3. **Gas efficiency**: Since the addresses are set during deployment, there's no need for additional transactions to set them later, which saves gas costs.
 *
 * Cons:
 * 1. **Less flexibility**: If there's a need to change the authorized withdrawers after deployment, it's not possible without deploying a new contract, which can be cumbersome and may require migration of funds and configurations.
 *
 * Getting authorized withdrawers in a function:**
 *
 * Pros:
 * 1. **Flexibility**: By allowing the authorized withdrawers to be set or updated through a function call
 * 2. **Dynamic configuration**: This approach allows for dynamic changes to the authorized withdrawers based on changing requirements or conditions.
 *
 *
 * Cons:
 * 1. **Additional complexity**: Implementing a function to set or update the authorized withdrawers adds complexity to the contract, requiring additional code and potentially introducing more points of failure.
 * 2. **Security risks**: If not implemented carefully, allowing dynamic changes to the authorized withdrawers can introduce security risks, such as the accidental removal of critical addresses or unauthorized modification by malicious actors.
 * conclusion-
 * The functionality of dynamism in permissions is important to me,
 * And worth the disadvantages of this method.
 * That's why I chose the function method.
 */
/*i chose to use three separate variables to store the authorized withdrawers
 beacuse it offers simplicity, readability, and efficiency.
  It  avoids unnecessary complexity, 
  and is more gas-efficient compared to using loops or data structures like mappings or hash 
*/
contract Gabaim {
    // Event to log the deposit to blockchain
    event Deposit(address indexed sender, uint256 amount);
    // Event to log the withdrawal from the contract
    event Withdrawal(address indexed recipient, uint256 amount);

    address private owner;
    address[3] private authorizedWithdrawers;

    constructor() {
        owner = msg.sender;
    }

    // Function to receive Ether
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
        require(msg.sender != address(0), "Cannot withdraw to zero address");
        require(isAuthorized(msg.sender), "You are not allowed to withdraw");
        require(amount <= address(this).balance, "Insufficient contract balance");
        payable(msg.sender).transfer(amount);
        emit Withdrawal(msg.sender, amount);
    }

    // Function to check if an address is authorized to withdraw
    function isAuthorized(address _address) private view returns (bool) {
        return (
            _address == owner || _address == authorizedWithdrawers[0] || _address == authorizedWithdrawers[1]
                || _address == authorizedWithdrawers[2]
        );
    }

    // Function to set or update the authorized withdrawer
    function setAuthorizedWithdrawer(address _authorizedWithdrawer, uint256 _index) public {
        require(msg.sender == owner, "Only the owner can set authorized withdrawer");
        require(_authorizedWithdrawer != address(0), "Authorized withdrawer cannot be zero address");
        require(_index >= 0 && _index < 3, "Invalid index");

        authorizedWithdrawers[_index] = _authorizedWithdrawer;
    }

    // Function to get authorized withdrawer address at a specific index
    function getAuthorizedWithdrawer(uint256 _index) public view returns (address) {
        require(_index >= 0 && _index < 3, "Index out of bounds");
        return authorizedWithdrawers[_index];
    }
}
