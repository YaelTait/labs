pragma solidity >=0.6.12 <0.9.0;
import "@hack/gabaim.sol";
import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";



contract GabaimTest is Test {
    Gabaim public gabaim;

    function setUp() public {
        gabaim = new Gabaim();
    }


 
 function testDeposit() public {
        // Arrange
        uint256 initialBalance = address(gabaim).balance;
        uint256 depositAmount = 100 wei;
        
        // Act
        payable(address(gabaim)).transfer(depositAmount);
        
        // Assert
        assertEq(address(gabaim).balance, initialBalance + depositAmount, "Contract balance should increase by deposit amount");
    }
    

    function testWithdraw() public {
        // Arrange
        uint256 initialBalance = address(gabaim).balance;
        uint256 withdrawalAmount = 50 wei;
        payable(address(gabaim)).transfer(withdrawalAmount);
        
        // Act
        gabaim.withdraw(withdrawalAmount);
        
        // Assert
        assertEq(address(gabaim).balance, initialBalance, "Contract balance should decrease by withdrawal amount");
    }
    

    function testInsufficientBalanceWithdraw() public {
    // Arrange
    uint256 withdrawalAmount = address(gabaim).balance + 1 wei; // Set withdrawal amount to exceed contract balance

    // Act & Assert
    vm.expectRevert("Insufficient contract balance");
    gabaim.withdraw(withdrawalAmount);
}

    

    function testSetAuthorizedWithdrawer() public {
        // Arrange
        address withdrawer = address(0x123);
        
        // Act
        gabaim.setAuthorizedWithdrawer1(withdrawer);
        
        // Assert
        assertEq(gabaim.getAuthorizedWithdrawer1(), withdrawer, "Authorized withdrawer 1 should be set");
    }
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

}
