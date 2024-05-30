//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "./SafeMath.sol";

contract Math {
    using SafeMath for uint256;

    uint256 private constant WAD = 1e18;
    uint256 private constant HALF_WAD = WAD / 2;

    function wdiv(uint256 num, uint256 denom) internal pure returns (uint256) {
        (bool successMul, uint256 scaledNumber) = num.tryMul(WAD);
        if (!successMul) return 0;
        (bool successDiv, uint256 rational) = scaledNumber.tryDiv(denom);
        if (!successDiv) return 0;
        return rational;
    }

    function wmul(uint256 a, uint256 b) internal pure returns (uint256) {
        (bool successMul, uint256 doubleScaledProduct) = a.tryMul(b);
        if (!successMul) return 0;
        (bool successAdd, uint256 doubleScaledProductWithHalfScale) = HALF_WAD.tryAdd(doubleScaledProduct);
        if (!successAdd) return 0;
        (bool successDiv, uint256 product) = doubleScaledProductWithHalfScale.tryDiv(WAD);
        assert(successDiv == true);
        return product;
    }

    function percentage(uint256 _num, uint256 _percentage) internal pure returns (uint256) {
        uint256 rational = wdiv(_num, 5);
        return wmul(rational, _percentage);
    }
}