// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WalletDistributor {
    event Deposit(address indexed sender, uint256 amount);
    event Withdrawal(address indexed recipient, uint256 amount);

    address private owner;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function distribute(address[] memory recipients, uint256 amount) public payable {
        require(msg.sender == owner, "Only the owner can distribute funds");
        require(recipients.length > 0, "Please specify recipients");
        uint256 amountPerRecipient = amount / recipients.length;
        require(amountPerRecipient > 0, "The amount per recipient is too low");

        for (uint256 i = 0; i < recipients.length; i++) {
            payable(address(recipients[i])).transfer(amountPerRecipient);
        }
    }
}
