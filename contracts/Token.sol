//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import "../node_modules/hardhat/console.sol";

import "../node_modules/hardhat/console.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {

    constructor() ERC20("MockToken", "MOK") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

}