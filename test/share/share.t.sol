// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "@hack/share/share.sol"; // Import the WalletDistributor contract

contract ShareTest is Test {
    WalletDistributor public walletDistributor;

    function setUp() public {
        // Deploy WalletDistributor contract
        walletDistributor = new WalletDistributor();
    }

    function testShare() public {
        // Transfer funds to the wallet distributor
        payable(address(walletDistributor)).transfer(10000);

        // Define recipients
        address[] memory recipients = new address[](3);
        recipients[0] = 0x074AC318E0f004146dbf4D3CA59d00b96a100100;
        recipients[1] = 0x1Eb3c3595F52788CBF3F2138652cC36fCb2EB673;
        recipients[2] = 0x5C3B01156A4029D1050Cd35bBB00CE3007B077eB;

        // Record initial balances of recipients
        uint256[] memory before = new uint256[](3);
        before[0] = address(recipients[0]).balance;
        before[1] = address(recipients[1]).balance;
        before[2] = address(recipients[2]).balance;

        uint256 amount = 90;

        // Distribute funds to recipients
        walletDistributor.distribute(recipients, amount);

        // Assert balances after distribution
        for (uint256 i = 0; i < recipients.length; i++) {
            uint256 amountPerRecipient = amount / recipients.length;
            assertEq(
                before[i] + amountPerRecipient, address(recipients[i]).balance, "Incorrect balance after distribution"
            );
        }
    }
}
