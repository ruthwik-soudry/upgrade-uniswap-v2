// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "../../core/UniswapV2Pair.sol";
import "../UniswapV2Router02.sol";
import "../../core/UniswapV2Factory.sol";


import "../../core/test/MyERC20.sol";

contract UniswapV2RouterTest is Test {
    UniswapV2Factory factory;
    UniswapV2Router02 router;

    MyERC20 tokenA;
    MyERC20 tokenB;
    MyERC20 tokenC;

    function setUp() public {
        factory = new UniswapV2Factory();
        router = new UniswapV2Router02(address(factory));

        tokenA = new MyERC20("Token A", "TKNA");
        tokenB = new MyERC20("Token B", "TKNB");
        tokenC = new MyERC20("Token C", "TKNC");

        tokenA.mint(20 ether, address(this));
        tokenB.mint(20 ether, address(this));
        tokenC.mint(20 ether, address(this));
    }

    function ErrorInEncode(string memory error) internal pure returns (bytes memory encoded)
    {
        encoded = abi.encodeWithSignature(error);
    }


    function testForAddingLiquidityNoPair() public {
        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 1 ether);

        (uint256 amountA, uint256 amountB, uint256 liquidity) = router
            .addLiquidity(
                address(tokenA),
                address(tokenB),
                1 ether,
                1 ether,
                1 ether,
                1 ether,
                address(this)
            );

        assertEq(amountA, 1 ether);
        assertEq(amountB, 1 ether);
        assertEq(liquidity, 1 ether - 1000);

        address pairAddress = factory.getPair(address(tokenA), address(tokenB));

        assertEq(tokenA.balanceOf(pairAddress), 1 ether);
        assertEq(tokenB.balanceOf(pairAddress), 1 ether);

        UniswapV2Pair pair = UniswapV2Pair(pairAddress);

        assertEq(pair.token0(), address(tokenB));
        assertEq(pair.token1(), address(tokenA));
        assertEq(pair.totalSupply(), 1 ether);
        assertEq(pair.balanceOf(address(this)), 1 ether - 1000);

        assertEq(tokenA.balanceOf(address(this)), 19 ether);
        assertEq(tokenB.balanceOf(address(this)), 19 ether);
    }

    function testForAddingLiquidityAmountBOptimalIsOk() public {
        address pairAddress = factory.createPair(
            address(tokenA),
            address(tokenB)
        );

        UniswapV2Pair pair = UniswapV2Pair(pairAddress);

        assertEq(pair.token0(), address(tokenB));
        assertEq(pair.token1(), address(tokenA));

        tokenA.transfer(pairAddress, 1 ether);
        tokenB.transfer(pairAddress, 2 ether);
        pair.mint(address(this));

        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 2 ether);

        (uint256 amountA, uint256 amountB, uint256 liquidity) = router
            .addLiquidity(
                address(tokenA),
                address(tokenB),
                1 ether,
                2 ether,
                1 ether,
                1.9 ether,
                address(this)
            );

        assertEq(amountA, 1 ether);
        assertEq(amountB, 2 ether);
        assertEq(liquidity, 1414213562373095048);
    }

    function testForAddingLiquidityAmountBOptimalIsTooLow() public {
        address pairAddress = factory.createPair(
            address(tokenA),
            address(tokenB)
        );

        UniswapV2Pair pair = UniswapV2Pair(pairAddress);
        assertEq(pair.token0(), address(tokenB));
        assertEq(pair.token1(), address(tokenA));

        tokenA.transfer(pairAddress, 5 ether);
        tokenB.transfer(pairAddress, 10 ether);
        pair.mint(address(this));

        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 2 ether);

         vm.expectRevert(abi.encodePacked("InsufficientBAmount"));
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1 ether,
            2 ether,
            1 ether,
            2 ether,
            address(this)
        );
    }

    function testForAddingLiquidityAmountBOptimalTooHighAmountATooLow() public {
        address pairAddress = factory.createPair(
            address(tokenA),
            address(tokenB)
        );
        UniswapV2Pair pair = UniswapV2Pair(pairAddress);

        assertEq(pair.token0(), address(tokenB));
        assertEq(pair.token1(), address(tokenA));

        tokenA.transfer(pairAddress, 10 ether);
        tokenB.transfer(pairAddress, 5 ether);
        pair.mint(address(this));

        tokenA.approve(address(router), 2 ether);
        tokenB.approve(address(router), 1 ether);

       vm.expectRevert(abi.encodePacked("InsufficientAAmount"));
        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            2 ether,
            0.9 ether,
            2 ether,
            1 ether,
            address(this)
        );
    }

    function testForAddingLiquidityAmountBOptimalIsTooHighAmountAOk() public {
        address pairAddress = factory.createPair(
            address(tokenA),
            address(tokenB)
        );
        UniswapV2Pair pair = UniswapV2Pair(pairAddress);

        assertEq(pair.token0(), address(tokenB));
        assertEq(pair.token1(), address(tokenA));

        tokenA.transfer(pairAddress, 10 ether);
        tokenB.transfer(pairAddress, 5 ether);
        pair.mint(address(this));

        tokenA.approve(address(router), 2 ether);
        tokenB.approve(address(router), 1 ether);

        (uint256 amountA, uint256 amountB, uint256 liquidity) = router
            .addLiquidity(
                address(tokenA),
                address(tokenB),
                2 ether,
                0.9 ether,
                1.7 ether,
                1 ether,
                address(this)
            );
        assertEq(amountA, 1.8 ether);
        assertEq(amountB, 0.9 ether);
        assertEq(liquidity, 1272792206135785543);
    }

    function testWithRemoveLiquidity() public {
        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 1 ether);

        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1 ether,
            1 ether,
            1 ether,
            1 ether,
            address(this)
        );

        address pairAddress = factory.getPair(address(tokenA), address(tokenB));
        UniswapV2Pair pair = UniswapV2Pair(pairAddress);
        uint256 liquidity = pair.balanceOf(address(this));

        pair.approve(address(router), liquidity);

        router.removeLiquidity(
            address(tokenA),
            address(tokenB),
            liquidity,
            1 ether - 1000,
            1 ether - 1000,
            address(this)
        );

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        assertEq(reserve0, 1000);
        assertEq(reserve1, 1000);
        assertEq(pair.balanceOf(address(this)), 0);
        assertEq(pair.totalSupply(), 1000);
        assertEq(tokenA.balanceOf(address(this)), 20 ether - 1000);
        assertEq(tokenB.balanceOf(address(this)), 20 ether - 1000);
    }

    function testWithRemoveLiquidityPartially() public {
        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 1 ether);

        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1 ether,
            1 ether,
            1 ether,
            1 ether,
            address(this)
        );

        address pairAddress = factory.getPair(address(tokenA), address(tokenB));
        UniswapV2Pair pair = UniswapV2Pair(pairAddress);
        uint256 liquidity = pair.balanceOf(address(this));

        liquidity = (liquidity * 3) / 10;
        pair.approve(address(router), liquidity);

        router.removeLiquidity(
            address(tokenA),
            address(tokenB),
            liquidity,
            0.3 ether - 300,
            0.3 ether - 300,
            address(this)
        );

        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        assertEq(reserve0, 0.7 ether + 300);
        assertEq(reserve1, 0.7 ether + 300);
        assertEq(pair.balanceOf(address(this)), 0.7 ether - 700);
        assertEq(pair.totalSupply(), 0.7 ether + 300);
        assertEq(tokenA.balanceOf(address(this)), 20 ether - 0.7 ether - 300);
        assertEq(tokenB.balanceOf(address(this)), 20 ether - 0.7 ether - 300);
    }

    function testWithRemoveLiquidityInsufficientAAmount() public {
        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 1 ether);

        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1 ether,
            1 ether,
            1 ether,
            1 ether,
            address(this)
        );

        address pairAddress = factory.getPair(address(tokenA), address(tokenB));
        UniswapV2Pair pair = UniswapV2Pair(pairAddress);
        uint256 liquidity = pair.balanceOf(address(this));

        pair.approve(address(router), liquidity);

        vm.expectRevert(abi.encodePacked("InsufficientAAmount"));
        router.removeLiquidity(
            address(tokenA),
            address(tokenB),
            liquidity,
            1 ether,
            1 ether - 1000,
            address(this)
        );
    }

    function testWithRemoveLiquidityInsufficientBAmount() public {
        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 1 ether);

        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1 ether,
            1 ether,
            1 ether,
            1 ether,
            address(this)
        );

        address pairAddress = factory.getPair(address(tokenA), address(tokenB));
        UniswapV2Pair pair = UniswapV2Pair(pairAddress);
        uint256 liquidity = pair.balanceOf(address(this));

        pair.approve(address(router), liquidity);

        vm.expectRevert(abi.encodePacked("InsufficientBAmount"));
        router.removeLiquidity(
            address(tokenA),
            address(tokenB),
            liquidity,
            1 ether - 1000,
            1 ether,
            address(this)
        );
    }

    function testWithSwapExactTokensForTokens() public {
        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 2 ether);
        tokenC.approve(address(router), 1 ether);

        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1 ether,
            1 ether,
            1 ether,
            1 ether,
            address(this)
        );

        router.addLiquidity(
            address(tokenB),
            address(tokenC),
            1 ether,
            1 ether,
            1 ether,
            1 ether,
            address(this)
        );

        address[] memory path = new address[](3);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        path[2] = address(tokenC);

        tokenA.approve(address(router), 0.3 ether);
        router.swapExactTokensForTokens(
            0.3 ether,
            0.1 ether,
            path,
            address(this)
        );

       
        assertEq(
            tokenA.balanceOf(address(this)),
            20 ether - 1 ether - 0.3 ether
        );
        assertEq(tokenB.balanceOf(address(this)), 20 ether - 2 ether);
        assertEq(
            tokenC.balanceOf(address(this)),
            20 ether - 1 ether + 0.186691414219734305 ether
        );
    }

    function testWithSwapTokensForExactTokens() public {
        tokenA.approve(address(router), 1 ether);
        tokenB.approve(address(router), 2 ether);
        tokenC.approve(address(router), 1 ether);

        router.addLiquidity(
            address(tokenA),
            address(tokenB),
            1 ether,
            1 ether,
            1 ether,
            1 ether,
            address(this)
        );

        router.addLiquidity(
            address(tokenB),
            address(tokenC),
            1 ether,
            1 ether,
            1 ether,
            1 ether,
            address(this)
        );

        address[] memory path = new address[](3);
        path[0] = address(tokenA);
        path[1] = address(tokenB);
        path[2] = address(tokenC);

        tokenA.approve(address(router), 0.3 ether);
        router.swapTokensForExactTokens(
            0.186691414219734305 ether,
            0.3 ether,
            path,
            address(this)
        );

       
        assertEq(
            tokenA.balanceOf(address(this)),
            20 ether - 1 ether - 0.3 ether
        );
        assertEq(tokenB.balanceOf(address(this)), 20 ether - 2 ether);
        assertEq(
            tokenC.balanceOf(address(this)),
            20 ether - 1 ether + 0.186691414219734305 ether
        );
    }
}
