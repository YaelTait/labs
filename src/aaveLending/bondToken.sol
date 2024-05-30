//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/v0.8/interfaces/AggregatorV3Interface.sol";
import "./ISwapRouter.sol";
import "./math.sol";
import "./myToken.sol";
import "./aaveLibrary.sol";

interface IUniswapRouter is ISwapRouter {
    function refundETH() external payable;
}

contract BondToken is Ownable, Math {
    using SafeMath for uint256;
    using AaveLibrary for ILendingPool;
    using AaveLibrary for IWETHGateway;

    IERC20 public constant dai = IERC20(0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD);
    IERC20 public constant aDai = IERC20(0xdCf0aF9e59C002FA3AA091a46196b37530FD48a8);
    IERC20 public constant aWeth = IERC20(0x87b1f4cf9BD63f7BBD3eE1aD04E8F52540349347);
    IWETHGateway public constant wethGateway = IWETHGateway(0xA61ca04DF33B72b235a8A28CfB535bb7A5271B70);
    ILendingPool public constant aave = ILendingPool(0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe);
    uint256 public totalBorrowed;
    uint256 public totalReserve;
    uint256 public totalDeposit;
    uint256 public maxLTV = 4; // 1 = 20%
    uint256 public ethTreasury;
    uint256 public totalCollateral;
    uint256 public baseRate = 20000000000000000;
    uint256 public fixedAnnuBorrowRate = 300000000000000000;
    MyERC20 public bondToken;
    AggregatorV3Interface internal constant priceFeed =
        AggregatorV3Interface(0x9326BFA02ADD2366b30bacB125260Af641031331);
    IUniswapRouter public constant uniswapRouter = IUniswapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IERC20 private constant weth = IERC20(0xd0A1E359811322d97991E03f863a0C30C2cF029C);

    mapping(address => uint256) private usersCollateral;
    mapping(address => uint256) private usersBorrowed;

    constructor() Ownable(msg.sender) {
        bondToken = new MyERC20();
    }

    function bondAsset(uint256 _amount) external {
        dai.transferFrom(msg.sender, address(this), _amount);
        totalDeposit += _amount;
        AaveLibrary.sendDaiToAave(_amount);
        uint256 bondsToMint = wdiv(_amount, getExchangeRate());
        bondToken.mint(msg.sender, bondsToMint);
    }

    function unbondAsset(uint256 _amount) external {
        require(_amount <= bondToken.balanceOf(msg.sender), "Not enough bonds!");
        uint256 daiToReceive = wmul(_amount, getExchangeRate());
        totalDeposit -= daiToReceive;
        bondToken.burn(msg.sender, _amount);
        AaveLibrary.withdrawDaiFromAave(daiToReceive);
    }

    function addCollateral() external payable {
        require(msg.value != 0, "Cant send 0 ethers");
        usersCollateral[msg.sender] += msg.value;
        totalCollateral += msg.value;
        AaveLibrary.sendWethToAave(msg.value);
    }

    function removeCollateral(uint256 _amount) external {
        uint256 wethPrice = uint256(_getLatestPrice());
        uint256 collateral = usersCollateral[msg.sender];
        require(collateral > 0, "Dont have any collateral");
        uint256 borrowed = usersBorrowed[msg.sender];
        uint256 amountLeft = wmul(collateral, wethPrice).sub(borrowed);
        uint256 amountToRemove = wmul(_amount, wethPrice);
        require(amountToRemove < amountLeft, "Not enough collateral to remove");
        usersCollateral[msg.sender] -= _amount;
        totalCollateral -= _amount;
        AaveLibrary.withdrawWethFromAave(_amount);
        payable(address(this)).transfer(_amount);
    }

    function borrow(uint256 _amount) external {
        require(_amount <= _borrowLimit(), "No collateral enough");
        usersBorrowed[msg.sender] += _amount;
        totalBorrowed += _amount;
        AaveLibrary.withdrawDaiFromAave(_amount);
    }

    function repay(uint256 _amount) external {
        require(usersBorrowed[msg.sender] > 0, "Doesnt have a debt to pay");
        dai.transferFrom(msg.sender, address(this), _amount);
        (uint256 fee, uint256 paid) = calculateBorrowFee(_amount);
        usersBorrowed[msg.sender] -= paid;
        totalBorrowed -= paid;
        totalReserve += fee;
        AaveLibrary.sendDaiToAave(_amount);
    }

    function calculateBorrowFee(uint256 _amount) public view returns (uint256, uint256) {
        uint256 borrowRate = _borrowRate();
        uint256 fee = wdiv(_amount, borrowRate);
        uint256 paid = _amount.sub(fee);
        return (fee, paid);
    }

    function liquidation(address _user) external onlyOwner {
        uint256 wethPrice = uint256(_getLatestPrice());
        uint256 collateral = usersCollateral[_user];
        uint256 borrowed = usersBorrowed[_user];
        uint256 collateralToUsd = wmul(wethPrice, collateral);
        if (borrowed > percentage(collateralToUsd, maxLTV)) {
            AaveLibrary.withdrawWethFromAave(collateral);
            uint256 amountDai = _convertEthToDai(collateral);
            totalReserve += amountDai;
            usersBorrowed[_user] = 0;
            usersCollateral[_user] = 0;
            totalCollateral -= collateral;
        }
    }

    function getExchangeRate() public view returns (uint256) {
        if (bondToken.totalSupply() == 0) {
            return 1000000000000000000;
        }
        uint256 cash = getCash();
        uint256 num = cash.add(totalBorrowed).add(totalReserve);
        return wdiv(num, bondToken.totalSupply());
    }

    function getCash() public view returns (uint256) {
        return totalDeposit.sub(totalBorrowed);
    }

    function harvestRewards() external onlyOwner {
        uint256 aWethBalance = aWeth.balanceOf(address(this));
        if (aWethBalance > totalCollateral) {
            uint256 rewards = aWethBalance.sub(totalCollateral);
            AaveLibrary.withdrawWethFromAave(rewards);
            ethTreasury += rewards;
        }
    }

    function convertTreasuryToReserve() external onlyOwner {
        uint256 amountDai = _convertEthToDai(ethTreasury);
        ethTreasury = 0;
        totalReserve += amountDai;
    }

    function _borrowLimit() public view returns (uint256) {
        uint256 amountLocked = usersCollateral[msg.sender];
        require(amountLocked > 0, "No collateral found");
        uint256 amountBorrowed = usersBorrowed[msg.sender];
        uint256 wethPrice = uint256(_getLatestPrice());
        uint256 amountLeft = wmul(amountLocked, wethPrice).sub(amountBorrowed);
        return percentage(amountLeft, maxLTV);
    }

    function getCollateral() external view returns (uint256) {
        return usersCollateral[msg.sender];
    }

    function getBorrowed() external view returns (uint256) {
        return usersBorrowed[msg.sender];
    }

    function balance() public view returns (uint256) {
        return aDai.balanceOf(address(this));
    }

    function _getLatestPrice() public view returns (int256) {
        (, int256 price,,,) = priceFeed.latestRoundData();
        return price * 10 ** 10;
    }

    function _utilizationRatio() public view returns (uint256) { // The ratio of Borrowed to deposits
        return wdiv(totalBorrowed, totalDeposit);
    }

    function _interestMultiplier() public view returns (uint256) {
        uint256 uRatio = _utilizationRatio();   //The ratio of borrows to deposits
        uint256 num = fixedAnnuBorrowRate.sub(baseRate);
        return wdiv(num, uRatio);
    }

    function _borrowRate() public view returns (uint256) {
        uint256 uRatio = _utilizationRatio(); //The ratio of borrows to deposits
        uint256 interestMul = _interestMultiplier();
        uint256 product = wmul(uRatio, interestMul);
        return product.add(baseRate);
    }

    function _depositRate() public view returns (uint256) {
        uint256 uRatio = _utilizationRatio();
        uint256 bRate = _borrowRate();
        return wmul(uRatio, bRate);
    }

    function _convertEthToDai(uint256 _amount) internal returns (uint256) {
        require(_amount > 0, "Must pass non 0 amount");

        uint256 deadline = block.timestamp + 15; // using 'now' for convenience
        address tokenIn = address(weth);
        address tokenOut = address(dai);
        uint24 fee = 3000;
        address recipient = address(this);
        uint256 amountIn = _amount;
        uint256 amountOutMinimum = 1;
        uint160 sqrtPriceLimitX96 = 0;

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams(
            tokenIn, tokenOut, fee, recipient, deadline, amountIn, amountOutMinimum, sqrtPriceLimitX96
        );

        uint256 amountOut = uniswapRouter.exactInputSingle{value: _amount}(params);
        uniswapRouter.refundETH();
        return amountOut;
    }

    receive() external payable {}

    fallback() external payable {}
}