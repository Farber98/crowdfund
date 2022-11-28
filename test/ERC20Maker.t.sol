// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ERC20Maker.sol";

contract ERC20MakerTest is Test {
    ERC20Maker token1;
    ERC20Maker token2;

    address owner1 = address(0x1);
    string name1 = "Token 1";
    string symbol1 = "TOK1";

    function setUp() public {
        vm.startPrank(owner1);
        token1 = new ERC20Maker(name1, symbol1);
        vm.stopPrank();
    }

    function testNameOk() public {
        assertEq(token1.name(), name1);
    }

    function testSymbolOk() public {
        assertEq(token1.symbol(), symbol1);
    }

    function testDecimalsAre18() public {
        assertEq(token1.decimals(), 18);
    }

    function testTotalSupplyIs100() public {
        assertEq(token1.totalSupply(), 100 * 10**token1.decimals());
    }

    function testTotalSupplyInOwnerAccount() public {
        assertEq(token1.balanceOf(owner1), token1.totalSupply());
    }
}
