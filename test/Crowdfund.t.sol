// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/ERC20Maker.sol";
import "../src/Crowdfund.sol";

contract CrowdfundTest is Test {
    ERC20Maker token;
    Crowdfund crowdfund;

    address creator = address(0x1);
    address payable founder2 = payable(address(0x2));
    address payable founder3 = payable(address(0x3));
    address payable tokenDeployer = payable(address(0x4));
    uint256 goal = 90 * 10**18;
    uint32 duration = 60 seconds;
    string name = "Token";
    string symbol = "TOK";

    function setUp() public {
        vm.startPrank(tokenDeployer);
        token = new ERC20Maker(name, symbol);
        token.transfer(founder2, 50 * 10**token.decimals());
        token.transfer(founder3, 50 * 10**token.decimals());
        vm.stopPrank();

        vm.startPrank(creator);
        crowdfund = new Crowdfund(address(token));
        vm.stopPrank();
    }

    function testSetup() public {
        assertEq(token.balanceOf(founder2), 50 * 10**token.decimals());
        assertEq(token.balanceOf(founder3), 50 * 10**token.decimals());
    }

    function testStartOk() public {
        vm.startPrank(creator);
        crowdfund.start(goal, duration);
        vm.stopPrank();
    }

    function testPledgeNotStarted() public {}

    function testPledgeAlreadyEnded() public {}

    function testPledgeOk() public {}

    function testUnpledgeNotStarted() public {}

    function testUnpledgeAlreadyEnded() public {}

    function testUnpledgeNotEnough() public {}

    function testUnpledgeOk() public {}

    function testClaimNotCreator() public {}

    function testClaimNotEnded() public {}

    function testClaimAlreadyClaimed() public {}

    function testClaimGoalNotReached() public {}

    function testRefundNotEnded() public {}

    function testRefundNotEnoughPledge() public {}

    function testRefundOk() public {}
}
