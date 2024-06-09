pragma solidity ^0.8.0;

import "src/nft/myToken.sol";
import "src/nft/nftAuction.sol";
import "foundry-huff/HuffDeployer.sol";
import "forge-std/Test.sol";
import "forge-std/console.sol";

contract NFTAuctionTest is Test {
    NFTAuction public nft;
    MyERC721 public erc721;
    uint256 public endingBid = 123;
    uint256 public startingPrice = 100;
    uint256 public tokenId = 1;
    address public owner = address(123);

    function setUp() public {
        // Deploy NFT and ERC721 contracts for testing
        vm.startPrank(owner);
        nft = new NFTAuction();
        string memory name = "yael";
        string memory symbole = "rachel";
        erc721 = new MyERC721(name, symbole);
        erc721.mint(owner, tokenId);
        erc721.approve(address(nft), tokenId);
    }

    // Test function to check the start of the auction
    function testStartAuction() public {
        nft.start(address(erc721), endingBid, startingPrice, tokenId);
        // Assert the state after calling start
        assertEq(nft.endingBid(), endingBid);
        assertEq(nft.startingPrice(), startingPrice);
        assertEq(nft.tokenId(), tokenId);
        assertEq(nft.started(), true);
        assertEq(erc721.ownerOf(tokenId), address(nft));
    }

    // Test function to add a Bid to the auction
    function testAddBid() public {
        address addr = vm.addr(12345);
        vm.startPrank(addr);
        vm.deal(address(addr), 5000);
        uint256 bidAmount = 150; // Higher than the starting price
        nft.addBid{value: bidAmount}();
        // Assert the state after adding a Bid
        (address maxStackAddress, uint256 maxStackAmount) = nft.getMaxStack();
        assertEq(maxStackAddress, address(addr), "Unexpected maxStackAddress");
        assertEq(maxStackAmount, bidAmount, "Unexpected maxStackAmount");
    }

    // Test function to cancel a Bid from the auction
    function testCancelBid() public {
        address addr = vm.addr(12345);
        vm.startPrank(addr);
        vm.deal(address(addr), 5000);
        uint256 bidAmount = 150; // Higher than the starting price
        nft.addBid{value: bidAmount}();
        nft.cancelBid();
        // Assert the state after canceling the Bid
        assert(!nft.getIsExist());
    }

    // Test function to end the auction
    function testEndAuction() public {
        nft.start(address(erc721), endingBid, startingPrice, tokenId);
        address addr = vm.addr(12345);
        vm.startPrank(addr);
        vm.deal(address(addr), 5000);
        uint256 bidAmount = 150; // Higher than the starting price
        nft.addBid{value: bidAmount}();
        vm.warp(124); // Fast forward time to simulate end of auction
        vm.stopPrank();
        vm.startPrank(owner);
        nft.end();
        // Assert the state after ending the auction
        assertEq(nft.started(), false, "Auction is still active after ending");
        assertEq(erc721.ownerOf(tokenId), address(addr), "Unexpected token owner after ending auction");
        assertEq(address(owner).balance, 150, "Incorrect balance after ending auction");
    }
}
