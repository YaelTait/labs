// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12 <0.9.0;

import "@hack/gabaim/gabaim.sol";
import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

contract GabaimTest is Test {
    Gabaim public gabaim;

    function setUp() public {
        gabaim = new Gabaim();
    }

    // Test deposit function
    function testDeposit() public {
        // Arrange
        uint256 initialBalance = address(gabaim).balance;
        uint256 depositAmount = 100 wei;

        // Act
        payable(address(gabaim)).transfer(depositAmount);

        // Assert
        assertEq(address(gabaim).balance, initialBalance + depositAmount, "Contract balance should increase by deposit amount");
    }

    // Test withdraw function
    function testWithdraw() public {
        // Arrange
        uint256 withdrawAmount = 50;
        address pullerAddress = vm.addr(123);   
        payable(address(gabaim)).transfer(10000);
        uint256 initialBalance = address(gabaim).balance;
        gabaim.setAuthorizedWithdrawer(pullerAddress, 1);

        // Act
        vm.startPrank(pullerAddress); // send from random address
        gabaim.withdraw(withdrawAmount);
        vm.stopPrank();

        // Assert
        uint256 finalBalance = address(gabaim).balance; // the balance in the final (after transfer)
        assertEq(finalBalance, initialBalance - withdrawAmount);
    }

    // Test unauthorized withdraw function
    function testUnauthorizedWithdraw() public {
        // Arrange
        address unauthorizedUser = vm.addr(1234); // Replace with an unauthorized address
        uint256 withdrawalAmount = 50 wei;

        // Act & Assert
        vm.prank(unauthorizedUser); // Set the msg.sender to the unauthorized address
        vm.expectRevert("You are not allowed to withdraw");
        gabaim.withdraw(withdrawalAmount);
        vm.stopPrank(); // Stop the prank after the test
    }

    // Test withdraw less than 0
    function testWithdrawLessThanZero() public {
        // Arrange
        uint256 withdrawAmount = 0;
        address pullerAddress = vm.addr(123);   
        payable(address(gabaim)).transfer(10000);
        uint256 initialBalance = address(gabaim).balance;
        gabaim.setAuthorizedWithdrawer(pullerAddress, 1);

        // Act & Assert
        vm.prank(pullerAddress); // Set the msg.sender to the unauthorized address
        vm.expectRevert("Withdrawal amount must be greater than 0");
        gabaim.withdraw(withdrawAmount);
        vm.stopPrank(); // Stop the prank after the test
    }

    // Test insufficient balance withdraw function
    function testInsufficientBalanceWithdraw() public {
        // Arrange
        uint256 withdrawalAmount = address(gabaim).balance + 1 wei; // Set withdrawal amount to exceed contract balance

        // Act & Assert
        vm.expectRevert("Insufficient contract balance");
        gabaim.withdraw(withdrawalAmount);
    }

    // Test set authorized withdrawer function
    function testSetAuthorizedWithdrawer() public {
        // Arrange
        address withdrawer = address(0x123);
        
        // Act
        gabaim.setAuthorizedWithdrawer(withdrawer, 1);
        
        // Assert
        assertEq(gabaim.getAuthorizedWithdrawer(1), withdrawer, "Authorized withdrawer 1 should be set");
    }
}
