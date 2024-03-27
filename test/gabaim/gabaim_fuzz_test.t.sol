// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.9.0;

import "@hack/gabaim/gabaim.sol";
import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

contract GabaimTest is Test {
    Gabaim public gabaim;

    // Set up the test environment
    function setUp() public {
        gabaim = new Gabaim();
    }

    // Test deposit function
    function testFuzz_Deposit(uint256 depositAmount) public {
        // Record the balance before deposit
        uint256 preBalance = address(gabaim).balance;

        // Assumptions
        vm.assume(depositAmount > 0 && depositAmount <= 1000 ether); // Deposit amount should be positive and less than or equal to 1000 ether

        // Act
        payable(address(gabaim)).transfer(depositAmount);

        // Assert
        assertGt(address(gabaim).balance, preBalance, "Contract balance should increase by deposit amount");
    }

    // Test withdraw function
    function testFuzz_Withdraw(uint256 withdrawAmount) public {
        // Assumptions & Arrange
        address pullerAddress = vm.addr(123); // Assuming vm.addr() is a valid way to obtain an address
        // Transfer some funds to the contract
        payable(address(gabaim)).transfer(10000);
        uint256 preBalance = address(gabaim).balance;
        // Check if withdrawal amount is valid
        vm.assume(withdrawAmount <= preBalance && withdrawAmount > 0);
        // Authorize the withdrawal for the specified address
        gabaim.setAuthorizedWithdrawer(pullerAddress, 1);

        // Act
        // Simulate a transaction from a random address
        vm.startPrank(pullerAddress);
        gabaim.withdraw(withdrawAmount);
        vm.stopPrank();

        // Assert
        uint256 finalBalance = address(gabaim).balance; // Final balance after transfer
        assertEq(finalBalance, preBalance - withdrawAmount); // Ensure the withdrawal amount has been deducted
    }

    // Test insufficient balance withdrawal
    function testFuzz_InsufficientBalanceWithdraw(uint256 withdrawalAmount) public {
        // Assumptions
        vm.assume(withdrawalAmount > address(gabaim).balance); // Withdrawal amount should exceed contract balance

        // Act & Assert
        vm.expectRevert("Insufficient contract balance");
        gabaim.withdraw(withdrawalAmount);
    }

    // Test setting authorized withdrawer
    function testFuzz_SetAuthorizedWithdrawer(address withdrawer) public {
        // Assumptions
        vm.assume(withdrawer != address(0)); // Withdrawer address should not be zero address

        // Act
        gabaim.setAuthorizedWithdrawer(withdrawer, 1);

        // Assert
        assertEq(gabaim.getAuthorizedWithdrawer(1), withdrawer, "Authorized withdrawer should be set");
    }
}
