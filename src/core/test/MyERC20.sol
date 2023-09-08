// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.19;



//import "../../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../../../solmate/tokens/ERC20.sol";

contract MyERC20 is ERC20 {
    constructor(string memory name_, string memory symbol_)
        ERC20(name_, symbol_,20){}
    

    function mint(uint256 amount, address to) public {
        _mint(to, amount);
    }
}

