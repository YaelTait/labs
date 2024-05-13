// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "forge-std/console.sol";
import "@hack/amm/MyToken.sol";
contract ConstantSumAMM {
    address public owner;
    uint public balanceA;
    uint public balanceB;
    uint public total;
    uint public wad=10**18;
    MyToken tokenA;
    MyToken tokenB;
    constructor(MyToken _tokenA, MyToken _tokenB) {
        owner = msg.sender;
        tokenA=_tokenA;
        tokenB=_tokenB;
    }
    function initialize(uint initialA, uint initialB) public {
        require(msg.sender == owner, "Only the owner can initialize");
        require(initialA > 0 && initialB > 0, "Initial amounts must be greater than zero");
        require(balanceA == 0 && balanceB == 0, "Already initialized");
        balanceA = initialA;
        balanceB = initialB;
        total=balanceA*balanceB;
    }
    function price(uint256 denominator) public view returns (uint) {
        require(balanceA > 0, "Balance of Token A must be greater than zero");
        return total*wad/denominator;
    }
    function getPayB2BuyA(uint desireA) public view returns(uint)   {
       return balanceB- total/balanceA-desireA; //add wad
    }
     function getPayA2BuyB(uint desireB) public view returns(uint){
       return balanceA -total/balanceB-desireB ;//add wad
    }
    function tradeAToB(uint amountA,uint amountB) public payable {
        require(amountA > 0, "Amount of Token A must be greater than zero");
        //require(lastBalanceB >= amountA, "Insufficient balance of Token A");
        require(amountA==getPayA2BuyB(amountB));
        tokenA.transferFrom(msg.sender, address(this), amountA);
         tokenB.transferFrom(address(this),msg.sender, amountB);
        balanceA+=amountA;
        balanceB-=amountB;
    }
    function tradeBToA(uint amountB, uint amountA) public payable{
       require(amountB > 0, "Amount of Token A must be greater than zero");
        //require(lastBalanceB >= amountA, "Insufficient balance of Token A");
        require(amountB==getPayB2BuyA(amountA));
         tokenB.transferFrom(msg.sender, address(this), amountB);
         tokenA.transferFrom(address(this),msg.sender, amountA);
        balanceB+=amountB;
        balanceA-=amountA;
    }
    function addLiquidity(uint amountA, uint amountB) payable public {
        require(amountA > 0 && amountB > 0, "Both amounts must be greater than zero");
        require(amountB==getPayB2BuyA(amountA),"the amount  of and b is not match");
        require(tokenA.balanceOf(msg.sender)+tokenB.balanceOf(msg.sender)>amountA+amountB,"Insufficient balance");
         tokenA.transferFrom(msg.sender, address(this), amountA);
         tokenB.transferFrom(msg.sender, address(this), amountB);
        balanceA += amountA;
        balanceB += amountB;
    }
    function removeLiquidity(uint amountA, uint amountB) payable public {
        require(amountA > 0 && amountB > 0, "Both amounts must be greater than zero");
        require(amountB==getPayB2BuyA(amountA),"the amount  of and b is not match");
        require(tokenA.balanceOf(msg.sender)+tokenB.balanceOf(msg.sender)>amountA+amountB,"Insufficient balance");
         tokenA.transfer(msg.sender,amountA);
         tokenA.transfer(msg.sender,amountB);
        balanceA -= amountA;
        balanceB -= amountB;
    }
}