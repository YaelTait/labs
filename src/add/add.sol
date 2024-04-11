// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "forge-std/console.sol";

contract Add {
    constructor() {}

    function addTwo(uint256 x, uint256 y) public  returns (uint256) {
        console.log("add",msg.sender);
        return x + y;
    }
}
//0x1e476fcb0d4bb8d3256c63984dab88f6ec475b31cd
//https://rpc.ankr.com/polygon_mumbai	
////https://rpc.ankr.com/polygon_mumbai	