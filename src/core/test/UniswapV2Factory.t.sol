pragma solidity ^0.8.19;
import "ds-test/test.sol";
import "forge-std/Test.sol";
import "../../../lib/forge-std/lib/ds-test/src/test.sol";
import "../UniswapV2Factory.sol";
import "./MyERC20.sol";



contract UniswapV2FactoryTest is Test {
    UniswapV2Factory  uniswapV2Factory;
    
    
    UniswapV2Pair pair;

    


        function setUp() public {
       
        uniswapV2Factory = new UniswapV2Factory();
        
    }
    function encodeError(string memory error) internal pure returns (bytes memory encoded)
    {
        encoded = abi.encodeWithSignature(error);
    }

    function test_createPair() public {
        // Create two ERC20 tokens to use as input for the pair
        MyERC20 tokenA = new MyERC20("token31","T31");
        MyERC20 tokenB = new MyERC20("token41","T41");

       address pairAddress = uniswapV2Factory.createPair(
            address(tokenB),
            address(tokenA)
        );

        UniswapV2Pair pair = UniswapV2Pair(pairAddress);

        assertEq(pair.token0(), address(tokenA));
        assertEq(pair.token1(), address(tokenB));
    }
   function test_identicalPair() public {
    // Create two ERC20 tokens to use as input for the pair
    MyERC20 tokenC = new MyERC20("token31","T31");

    // Try to create a pair with identical addresses
    vm.expectRevert(abi.encodePacked("UniswapV2: IDENTICAL_ADDRESSES"));
    uniswapV2Factory.createPair(address(tokenC), address(tokenC));
}
 function test_zeroaddress() public {
    // Create an ERC20 token to use as input for the pair
    MyERC20 tokenC = new MyERC20("token31","T31");

    // Expect a revert error when creating a pair with a zero address
    vm.expectRevert(abi.encodePacked("UniswapV2: ZERO_ADDRESS"));
    uniswapV2Factory.createPair(address(0), address(tokenC));
}



}