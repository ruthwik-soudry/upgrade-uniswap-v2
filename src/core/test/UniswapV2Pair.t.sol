pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../UniswapV2Pair.sol";

import "../UniswapV2Factory.sol";
import '../libraries/UQ112x112.sol';

import "./MyERC20.sol";

contract UniswapV2PairTest is Test {
    MyERC20 tokenA;
    MyERC20 tokenB;
    UniswapV2Pair pair;
    TestingContract testingContract;

    function setUp() public {
        testingContract = new TestingContract();

        tokenA = new MyERC20("Token A", "TA");
        tokenB = new MyERC20("Token B", "TB");

        UniswapV2Factory uniswapV2Factory  = new UniswapV2Factory();
        address pairAddress = uniswapV2Factory.createPair(
            address(tokenA),
            address(tokenB)
        );
        pair = UniswapV2Pair(pairAddress);

        tokenA.mint(10 ether, address(this));
        tokenB.mint(10 ether, address(this));

        tokenA.mint(10 ether, address(testingContract));
        tokenB.mint(10 ether, address(testingContract));
    }

    

    function assertReserves(uint112 expectedReserve0, uint112 expectedReserve1) internal
    {
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        assertEq(reserve0, expectedReserve0, "unexpected reserve0");
        assertEq(reserve1, expectedReserve1, "unexpected reserve1");
    }

    function assertCumulativePrices(uint256 expectedPrice0,uint256 expectedPrice1) internal {
        assertEq(
            pair.price0CumulativeLast(),
            expectedPrice0,
            "The cumulative price0 is unexpected!"
        );
        assertEq(
            pair.price1CumulativeLast(),
            expectedPrice1,
            "The cumulative price1 is unexpected!"
        );
    }
    function ErrorInEncode(string memory error) internal pure returns (bytes memory encoded)
    {
        encoded = abi.encodeWithSignature(error);
    }

    function ErrorInEncode(string memory error, uint256 a) internal pure returns (bytes memory encoded)
    {
        encoded = abi.encodeWithSignature(error, a);
    }

    function calculateCurrentPrice() internal view  returns (uint256 price0, uint256 price1)
    {
        (uint112 reserve0, uint112 reserve1, ) = pair.getReserves();
        price0 = reserve0 > 0
            ? (reserve1 * uint256(UQ112x112.Q112)) / reserve0
            : 0;
        price1 = reserve1 > 0
            ? (reserve0 * uint256(UQ112x112.Q112)) / reserve1
            : 0;
    }

    function assertBlockTimestampLast(uint32 expected) internal {
        (, , uint32 blockTimestampLast) = pair.getReserves();

        assertEq(blockTimestampLast, expected, "BlockTimestampLast is not what is expected here");
    }


    function testMint() public {
        tokenA.transfer(address(pair), 1 ether);
        tokenB.transfer(address(pair), 1 ether);

        pair.mint(address(this));

        assertEq(pair.balanceOf(address(this)), 1 ether - 1000);
        assertReserves(1 ether, 1 ether);
        assertEq(pair.totalSupply(), 1 ether);
    }

    function testMintWithLiquidityExists() public {
        tokenA.transfer(address(pair), 1 ether);
        tokenB.transfer(address(pair), 1 ether);

        pair.mint(address(this)); 

        vm.warp(37);

        tokenA.transfer(address(pair), 2 ether);
        tokenB.transfer(address(pair), 2 ether);

        pair.mint(address(this)); 

        assertEq(pair.balanceOf(address(this)), 3 ether - 1000);
        assertEq(pair.totalSupply(), 3 ether);
        assertReserves(3 ether, 3 ether);
    }

    function testMintWithUnbalanced() public {
        tokenA.transfer(address(pair), 1 ether);
        tokenB.transfer(address(pair), 1 ether);

        pair.mint(address(this)); 
        assertEq(pair.balanceOf(address(this)), 1 ether - 1000);
        assertReserves(1 ether, 1 ether);

        tokenA.transfer(address(pair), 2 ether);
        tokenB.transfer(address(pair), 1 ether);

        pair.mint(address(this)); 
        assertEq(pair.balanceOf(address(this)), 2 ether - 1000);
        assertReserves(3 ether, 2 ether);
    }

    function testMintWithUnderflowLiquidity() public {
      
        vm.expectRevert(ErrorInEncode("Panic(uint256)", 0x11));
        pair.mint(address(this));
    }

    function testMintWithLiquidityZero() public {
        tokenA.transfer(address(pair), 1000);
        tokenB.transfer(address(pair), 1000);

        vm.expectRevert(abi.encodePacked("UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED"));
        pair.mint(address(this));
    }

    function testBurn() public {
        tokenA.transfer(address(pair), 1 ether);
        tokenB.transfer(address(pair), 1 ether);

        pair.mint(address(this));

        uint256 liquidity = pair.balanceOf(address(this));
        pair.transfer(address(pair), liquidity);
        pair.burn(address(this));

        assertEq(pair.balanceOf(address(this)), 0);
        assertReserves(1000, 1000);
        assertEq(pair.totalSupply(), 1000);
        assertEq(tokenA.balanceOf(address(this)), 10 ether - 1000);
        assertEq(tokenB.balanceOf(address(this)), 10 ether - 1000);
    }

    function testBurnWithUnbalanced() public {
        tokenA.transfer(address(pair), 1 ether);
        tokenB.transfer(address(pair), 1 ether);

        pair.mint(address(this));

        tokenA.transfer(address(pair), 2 ether);
        tokenB.transfer(address(pair), 1 ether);

        pair.mint(address(this)); 
        uint256 liquidity = pair.balanceOf(address(this));
        pair.transfer(address(pair), liquidity);
        pair.burn(address(this));

        assertEq(pair.balanceOf(address(this)), 0);
        assertReserves(1500, 1000);
        assertEq(pair.totalSupply(), 1000);
        assertEq(tokenA.balanceOf(address(this)), 10 ether - 1500);
        assertEq(tokenB.balanceOf(address(this)), 10 ether - 1000);
    }

    function testBurnWithDifferentUsersUnbalanced() public {
        testingContract.provideLiquidity(
            address(pair),
            address(tokenA),
            address(tokenB),
            1 ether,
            1 ether
        );

        assertEq(pair.balanceOf(address(this)), 0);
        assertEq(pair.balanceOf(address(testingContract)), 1 ether - 1000);
        assertEq(pair.totalSupply(), 1 ether);

        tokenA.transfer(address(pair), 2 ether);
        tokenB.transfer(address(pair), 1 ether);

        pair.mint(address(this)); 

        uint256 liquidity = pair.balanceOf(address(this));
        pair.transfer(address(pair), liquidity);
        pair.burn(address(this));

        
        assertEq(pair.balanceOf(address(this)), 0);
        assertReserves(1.5 ether, 1 ether);
        assertEq(pair.totalSupply(), 1 ether);
        assertEq(tokenA.balanceOf(address(this)), 10 ether - 0.5 ether);
        assertEq(tokenB.balanceOf(address(this)), 10 ether);

        testingContract.removeLiquidity(address(pair));

      
        assertEq(pair.balanceOf(address(testingContract)), 0);
        assertReserves(1500, 1000);
        assertEq(pair.totalSupply(), 1000);
        assertEq(
            tokenA.balanceOf(address(testingContract)),
            10 ether + 0.5 ether - 1500
        );
        assertEq(tokenB.balanceOf(address(testingContract)), 10 ether - 1000);
    }

    function testBurnWithTotalSupplyZero() public {
      
        vm.expectRevert(ErrorInEncode("Panic(uint256)", 0x12));
        pair.burn(address(this));
    }

    function testBurnWithLiquidityZero() public {
    
        tokenA.transfer(address(pair), 1 ether);
        tokenB.transfer(address(pair), 1 ether);
        pair.mint(address(this));

        vm.prank(address(0xdeadbeef));
        vm.expectRevert(abi.encodePacked('UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED'));
        
        pair.burn(address(this));
    }



    function testSwap() public {
        tokenA.transfer(address(pair), 1 ether);
        tokenB.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        uint256 amountOut = 0.181322178776029826 ether;
        tokenA.transfer(address(pair), 0.1 ether);
        pair.swap(0, amountOut, address(this), "");

        assertEq(
            tokenA.balanceOf(address(this)),
            10 ether - 1 ether - 0.1 ether,
            "tokenA balance is not correct"
        );
        assertEq(
            tokenB.balanceOf(address(this)),
            10 ether - 2 ether + amountOut,
            "tokenB balance is not correct"
        );
        assertReserves(1 ether + 0.1 ether, uint112(2 ether - amountOut));
    }

    function testSwapReverseDirection() public {
        tokenA.transfer(address(pair), 1 ether);
        tokenB.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        tokenB.transfer(address(pair), 0.2 ether);
        pair.swap(0.09 ether, 0, address(this), "");

        assertEq(
            tokenA.balanceOf(address(this)),
            10 ether - 1 ether + 0.09 ether,
            "tokenA balance is not correct"
        );
        assertEq(
            tokenB.balanceOf(address(this)),
            10 ether - 2 ether - 0.2 ether,
            "tokenA balance is not correct"
        );
        assertReserves(1 ether - 0.09 ether, 2 ether + 0.2 ether);
    }

    function testSwapInBothDirections() public {
        tokenA.transfer(address(pair), 1 ether);
        tokenB.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        tokenA.transfer(address(pair), 0.1 ether);
        tokenB.transfer(address(pair), 0.2 ether);
        pair.swap(0.09 ether, 0.18 ether, address(this), "");

        assertEq(
            tokenA.balanceOf(address(this)),
            10 ether - 1 ether - 0.01 ether,
            "tokenA balance is not correct"
        );
        assertEq(
            tokenB.balanceOf(address(this)),
            10 ether - 2 ether - 0.02 ether,
            "tokenB balance is not correct"
        );
        assertReserves(1 ether + 0.01 ether, 2 ether + 0.02 ether);
    }

    function testSwapZeroOut() public {
        tokenA.transfer(address(pair), 1 ether);
        tokenB.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        vm.expectRevert(abi.encodePacked('UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT'));
        pair.swap(0, 0, address(this), "");
    }

    function testSwapWithInsufficientLiquidity() public {
        tokenA.transfer(address(pair), 1 ether);
        tokenB.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        vm.expectRevert(abi.encodePacked('UniswapV2: INSUFFICIENT_LIQUIDITY' ));
        pair.swap(0, 2.1 ether, address(this), "");

        vm.expectRevert(abi.encodePacked('UniswapV2: INSUFFICIENT_LIQUIDITY' ));
        pair.swap(1.1 ether, 0, address(this), "");
    }

    function testSwapWithUnderpriced() public {
        tokenA.transfer(address(pair), 1 ether);
        tokenB.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        tokenA.transfer(address(pair), 0.1 ether);
        pair.swap(0, 0.09 ether, address(this), "");

        assertEq(
            tokenA.balanceOf(address(this)),
            10 ether - 1 ether - 0.1 ether,
            "tokenA balance is not correct"
        );
        assertEq(
            tokenB.balanceOf(address(this)),
            10 ether - 2 ether + 0.09 ether,
            "tokenB balance is not correct"
        );
        assertReserves(1 ether + 0.1 ether, 2 ether - 0.09 ether);
    }

    function testSwapWithOverpriced() public {
        tokenA.transfer(address(pair), 1 ether);
        tokenB.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        tokenA.transfer(address(pair), 0.1 ether);

        vm.expectRevert(abi.encodePacked("UniswapV2: K"));
        pair.swap(0, 0.36 ether, address(this), "");

        assertEq(
            tokenA.balanceOf(address(this)),
            10 ether - 1 ether - 0.1 ether,
            "tokenA balance is not correct"
        );
        assertEq(
            tokenB.balanceOf(address(this)),
            10 ether - 2 ether,
            "tokenB balance is not correct"
        );
        assertReserves(1 ether, 2 ether);
    }

    function testSwapWithUnpaidFee() public {
        tokenA.transfer(address(pair), 1 ether);
        tokenB.transfer(address(pair), 2 ether);
        pair.mint(address(this));

        tokenA.transfer(address(pair), 0.1 ether);

        vm.expectRevert(abi.encodePacked("UniswapV2: K"));
        pair.swap(0, 0.181322178776029827 ether, address(this), "");
    }

    function testCalculateCumulativePrices() public {
        vm.warp(0);
        tokenA.transfer(address(pair), 1 ether);
        tokenB.transfer(address(pair), 1 ether);
        pair.mint(address(this));

        (
            uint256 initialPrice0,
            uint256 initialPrice1
        ) = calculateCurrentPrice();

        
        pair.sync();
        assertCumulativePrices(0, 0);

        
        vm.warp(1);
        pair.sync();
        assertBlockTimestampLast(1);
        assertCumulativePrices(initialPrice0, initialPrice1);

        
        vm.warp(2);
        pair.sync();
        assertBlockTimestampLast(2);
        assertCumulativePrices(initialPrice0 * 2, initialPrice1 * 2);

       
        vm.warp(3);
        pair.sync();
        assertBlockTimestampLast(3);
        assertCumulativePrices(initialPrice0 * 3, initialPrice1 * 3);

     
        tokenA.transfer(address(pair), 2 ether);
        tokenB.transfer(address(pair), 1 ether);
        pair.mint(address(this));

        (uint256 newPrice0, uint256 newPrice1) = calculateCurrentPrice();

    
        assertCumulativePrices(initialPrice0 * 3, initialPrice1 * 3);

        
        vm.warp(4);
        pair.sync();
        assertBlockTimestampLast(4);
        assertCumulativePrices(
            initialPrice0 * 3 + newPrice0,
            initialPrice1 * 3 + newPrice1
        );

        
        vm.warp(5);
        pair.sync();
        assertBlockTimestampLast(5);
        assertCumulativePrices(
            initialPrice0 * 3 + newPrice0 * 2,
            initialPrice1 * 3 + newPrice1 * 2
        );

      
        vm.warp(6);
        pair.sync();
        assertBlockTimestampLast(6);
        assertCumulativePrices(
            initialPrice0 * 3 + newPrice0 * 3,
            initialPrice1 * 3 + newPrice1 * 3
        );
    }

    
}

contract TestingContract {
    function provideLiquidity(
        address pairAddress_,
        address tokenAAddress_,
        address tokenBAddress_,
        uint256 amount0_,
        uint256 amount1_
    ) public {
        ERC20(tokenAAddress_).transfer(pairAddress_, amount0_);
        ERC20(tokenBAddress_).transfer(pairAddress_, amount1_);

        UniswapV2Pair(pairAddress_).mint(address(this));
    }

    function removeLiquidity(address pairAddress_) public {
        uint256 liquidity = ERC20(pairAddress_).balanceOf(address(this));
        ERC20(pairAddress_).transfer(pairAddress_, liquidity);
        UniswapV2Pair(pairAddress_).burn(address(this));


    }

    function removeLiquidityFromPair(address _pairAddress) public {
    uint256 _liquidityAmount = ERC20(_pairAddress).balanceOf(address(this));
   
    ERC20(_pairAddress).transfer(_pairAddress, _liquidityAmount);
    UniswapV2Pair(_pairAddress).burn(address(this));
}
}
