// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Test.sol"; // Assuming you're using Foundry/Hardhat for testing
import "@hack/AMM/MyToken.sol"; // Importing your token contract
import "src/AMM/cp.sol";
import "foundry-huff/HuffDeployer.sol";
import "forge-std/console.sol";
contract AmmTest is Test {
    CP public amm; // Your AMM contract
    MyToken public token0;
    MyToken public token1;
    function setUp() public {
        // Deploy tokens
        token0 = new MyToken(); // Token with initial supply of 10,000
        token1 = new MyToken();
        // Deploy AMM contract
        amm = new CP(address(token0), address(token1));
    }
    function testValidSwap() public {
        uint swapAmount = 100;
        // Mint tokens for user1
       address user1 = address(0x123); // Set up user1 address
        // Approve the contract to spend the required tokens
        vm.startPrank(user1);
        token0.approve(address(amm), 20000); // Ensure approval to the correct contract
        token0.mint(2000);
        // Get initial reserves
        uint reserve0Before = amm.reserve0();
        uint reserve1Before = amm.reserve1();
        uint amountOut = amm.swap(address(token0), swapAmount);
        // Calculate expected output after the swap
        uint expectedOut = (reserve1Before * ((swapAmount * 997) / 1000)) /
            (reserve0Before + ((swapAmount * 997) / 1000));
        // Ensure the returned amountOut matches the expected value
        assertEq(
            amountOut,
            expectedOut,
            "Returned amountOut doesn't match expected value"
        );
        // Verify the reserves have updated correctly after the swap
        assertEq(
            amm.reserve0(),
            reserve0Before + swapAmount,
            "Reserve0 not updated correctly"
        );
        assertEq(
            amm.reserve1(),
            reserve1Before - amountOut,
            "Reserve1 not updated correctly"
        );
    }
    function testInvalidToken() public {
        // Trying to swap a token that's not in the pool should fail
        MyToken invalidToken = new MyToken();
        vm.expectRevert("AMM3-invalid-token");
        amm.swap(address(invalidToken), 100);
    }
    function testZeroAmount() public {
        token0.mint(2000);
        // Trying to swap zero amount should fail
        vm.expectRevert("AMM3-zero-amount");
        amm.swap(address(token0), 0);
    }
    function testAddInitialLiquidity() public {
        address user1 = address(0x123); // Set up user1 address
        vm.startPrank(user1);
        token0.approve(address(amm), 20000); // Ensure approval to the correct contract
        token1.approve(address(amm), 20000); // Ensure approval to the correct contract
        token0.mint(2000);
        token1.mint(2000);
        uint shares = amm.addLiquidity(5, 10);
        // Validate that shares were minted based on the sqrt formula
        uint temp = 5 * 10;
        uint expectedShares = sqrt(temp);
        assertEq(shares, expectedShares, "Shares minted do not match expected");
        // Check if reserves are updated correctly
        assertEq(amm.reserve0(), 5, "Reserve0 not updated correctly");
        assertEq(amm.reserve1(), 10, "Reserve1 not updated correctly");
        // Check total supply and user's shares
        assertEq(amm.totalSupply(), expectedShares, "Total supply incorrect");
        assertEq(
            amm.balances(user1),
            expectedShares,
            "User's shares incorrect"
        );
    }
    function testAddProportionalLiquidity() public {
        uint INITIAL_AMOUNT0 = 5;
        uint INITIAL_AMOUNT1 = 10;
        address user1 = address(0x123); // Set up user1 address
        vm.startPrank(user1);
        token0.approve(address(amm), 20000); // Ensure approval to the correct contract
        token1.approve(address(amm), 20000); // Ensure approval to the correct contract
        token0.mint(2000);
        token1.mint(2000);
        uint shares = amm.addLiquidity(INITIAL_AMOUNT0, INITIAL_AMOUNT1);
        // Validate that shares were minted based on the sqrt formula
        uint temp = 5 * 10;
        uint expectedShares = sqrt(temp);
        assertEq(shares, expectedShares, "Shares minted do not match expected");
        // Adding proportional liquidity
        uint additionalAmount0 = 20; // Adding more liquidity
        uint additionalAmount1 = 40; // Proportional to existing liquidity
        uint additionalShares = amm.addLiquidity(
            additionalAmount0,
            additionalAmount1
        );
        // Validate shares minted for proportional liquidity
        uint expectedAdditionalShares = min(
            (additionalAmount0 * amm.totalSupply()) / amm.reserve0(),
            (additionalAmount1 * amm.totalSupply()) / amm.reserve1()
        );
        assertEq(
            additionalShares,
            expectedAdditionalShares,
            "Additional shares do not match expected"
        );
        // Check if reserves are updated correctly
        assertEq(
            amm.reserve0(),
            INITIAL_AMOUNT0 + additionalAmount0,
            "Reserve0 incorrect"
        );
        assertEq(
            amm.reserve1(),
            INITIAL_AMOUNT1 + additionalAmount1,
            "Reserve1 incorrect"
        );
        // Validate total supply and user's updated shares
        assertEq(
            amm.totalSupply(),
            expectedAdditionalShares + expectedShares,
            "Total supply incorrect"
        );
        assertEq(
            amm.balances(user1),
            expectedAdditionalShares + expectedShares,
            "User's shares incorrect"
        );
    }
    function testAddLiquidityIncorrectRatio() public {
        // Try adding liquidity with incorrect ratios
        address user1 = address(0x123); // Set up user1 address
        vm.startPrank(user1);
        token0.approve(address(amm), 20000); // Ensure approval to the correct contract
        token1.approve(address(amm), 20000); // Ensure approval to the correct contract
        token0.mint(2000);
        token1.mint(2000);
        amm.addLiquidity(5, 10);
        vm.expectRevert("x/y != dx/dy"); // Expect revert on invalid ratio
        amm.addLiquidity(1, 3); // Incorrect ratio
    }
    function testRemoveLiquidity() public {
        address user1 = address(0x123); // Set up user1 address
        vm.startPrank(user1);
        token0.approve(address(amm), 20000); // Ensure approval to the correct contract
        token1.approve(address(amm), 20000); // Ensure approval to the correct contract
        token0.mint(2000);
        token1.mint(2000);
        uint INITIAL_AMOUNT0 = 20;
        uint INITIAL_AMOUNT1 = 40;
        amm.addLiquidity(INITIAL_AMOUNT0, INITIAL_AMOUNT1);
        uint sharesToRemove = 10; // Number of shares to remove
        // Remove liquidity
        (uint amount0, uint amount1) = amm.removeLiquidity(sharesToRemove);
        // Calculate expected amounts returned based on share-to-reserve ratio
        uint totalSupply = amm.totalSupply();
        uint expectedAmount0 = (sharesToRemove * amm.reserve0()) / totalSupply;
        uint expectedAmount1 = (sharesToRemove * amm.reserve1()) / totalSupply;
        // Check that the correct amounts were returned
        assertEq(
            amount0,
            expectedAmount0,
            "Returned amount0 does not match expected"
        );
        assertEq(
            amount1,
            expectedAmount1,
            "Returned amount1 does not match expected"
        );
        // Validate reserve updates after liquidity removal
        assertEq(
            amm.reserve0(),
            INITIAL_AMOUNT0 - expectedAmount0,
            "Reserve0 not updated correctly"
        );
        assertEq(
            amm.reserve1(),
            INITIAL_AMOUNT1 - expectedAmount1,
            "Reserve1 not updated correctly"
        );
    }
    // Helper functions
    function sqrt(uint y) private pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
    function min(uint x, uint y) private pure returns (uint) {
        return x < y ? x : y;
    }
}