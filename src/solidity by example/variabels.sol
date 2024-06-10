pragma solidity ^0.8.20;
 contract Variabels{

//state: save in blockchin
string public text="hello!";
function doSomthing()public{
    //local
    uint i=456;
    //global:
    uint256 timestamp=block.timestamp;
    address sender=msg.sender;
}
 }