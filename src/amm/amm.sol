// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/console.sol";
import "@hack/amm/MyToken.sol";

contract ConstantSumAMM {
    address public owner;
    uint256 public balanceA;
    uint256 public balanceB;
    uint256 public total;
    uint256 public wad = 10 ** 18;
    MyToken tokenA;
    MyToken tokenB;

    constructor(MyToken _tokenA, MyToken _tokenB) {
        owner = msg.sender;
        tokenA = _tokenA;
        tokenB = _tokenB;
    }

    function initialize(uint256 initialA, uint256 initialB) public {
        require(msg.sender == owner, "Only the owner can initialize");
        require(initialA > 0 && initialB > 0, "Initial amounts must be greater than zero");
        require(balanceA == 0 && balanceB == 0, "Already initialized");
        balanceA = initialA;
        balanceB = initialB;
        total = balanceA * balanceB;
    }

    function price(uint256 denominator) public view returns (uint256) {
        require(balanceA > 0, "Balance of Token A must be greater than zero");
        return total * wad / denominator;
    }

    function getPayB2BuyA(uint256 desireA) public view returns (uint256) {
        return balanceB - total / balanceA - desireA; //add wad
    }

    function getPayA2BuyB(uint256 desireB) public view returns (uint256) {
        return balanceA - total / balanceB - desireB; //add wad
    }

    function tradeAToB(uint256 amountA, uint256 amountB) public payable {
        require(amountA > 0, "Amount of Token A must be greater than zero");
        //require(lastBalanceB >= amountA, "Insufficient balance of Token A");
        require(amountA == getPayA2BuyB(amountB));
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(address(this), msg.sender, amountB);
        balanceA += amountA;
        balanceB -= amountB;
    }

    function tradeBToA(uint256 amountB, uint256 amountA) public payable {
        require(amountB > 0, "Amount of Token A must be greater than zero");
        //require(lastBalanceB >= amountA, "Insufficient balance of Token A");
        require(amountB == getPayB2BuyA(amountA));
        tokenB.transferFrom(msg.sender, address(this), amountB);
        tokenA.transferFrom(address(this), msg.sender, amountA);
        balanceB += amountB;
        balanceA -= amountA;
    }

    function addLiquidity(uint256 amountA, uint256 amountB) public payable {
        require(amountA > 0 && amountB > 0, "Both amounts must be greater than zero");
        require(amountB == getPayB2BuyA(amountA), "the amount  of and b is not match");
        require(tokenA.balanceOf(msg.sender) + tokenB.balanceOf(msg.sender) > amountA + amountB, "Insufficient balance");
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);
        balanceA += amountA;
        balanceB += amountB;
    }

    function removeLiquidity(uint256 amountA, uint256 amountB) public payable {
        require(amountA > 0 && amountB > 0, "Both amounts must be greater than zero");
        require(amountB == getPayB2BuyA(amountA), "the amount  of and b is not match");
        require(tokenA.balanceOf(msg.sender) + tokenB.balanceOf(msg.sender) > amountA + amountB, "Insufficient balance");
        tokenA.transfer(msg.sender, amountA);
        tokenA.transfer(msg.sender, amountB);
        balanceA -= amountA;
        balanceB -= amountB;
    }
}
