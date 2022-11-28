// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/ERC20Maker.sol";

contract ERC20MakerTest is Test {
    ERC20Maker token;

    address owner = address(0x1);
    string name = "Token";
    string symbol = "TOK";

    function setUp() public {
        vm.startPrank(owner);
        token = new ERC20Maker(name, symbol);
        vm.stopPrank();
    }

    function testNameOk() public {
        assertEq(token.name(), name);
    }

    function testSymbolOk() public {
        assertEq(token.symbol(), symbol);
    }

    function testDecimalsAre18() public {
        assertEq(token.decimals(), 18);
    }

    function testTotalSupplyIs100() public {
        assertEq(token.totalSupply(), 100 * 10**token.decimals());
    }

    function testTotalSupplyInOwnerAccount() public {
        assertEq(token.balanceOf(owner), token.totalSupply());
    }
}
