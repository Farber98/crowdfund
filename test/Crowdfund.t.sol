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
    address payable funder2 = payable(address(0x2));
    address payable funder3 = payable(address(0x3));
    address payable tokenDeployer = payable(address(0x4));
    uint256 goal = 31 * 10**18;
    uint32 duration = 60 seconds;
    string name = "Token";
    string symbol = "TOK";

    function setUp() public {
        vm.startPrank(tokenDeployer);
        token = new ERC20Maker(name, symbol);
        token.transfer(funder2, 50 * 10**token.decimals());
        token.transfer(funder3, 50 * 10**token.decimals());
        vm.stopPrank();

        vm.startPrank(creator);
        crowdfund = new Crowdfund(address(token));
        vm.stopPrank();
    }

    function testSetup() public {
        assertEq(token.balanceOf(funder2), 50 * 10**token.decimals());
        assertEq(token.balanceOf(funder3), 50 * 10**token.decimals());
    }

    function testStartOk() public {
        vm.startPrank(creator);
        assertEq(crowdfund.count(), 0);
        crowdfund.start(goal, duration);
        vm.stopPrank();

        assertEq(crowdfund.count(), 1);
        assertEq(crowdfund.getCampaignCreator(0), creator);
        assertEq(crowdfund.getCampaignGoal(0), goal);
        assertEq(crowdfund.getCampaignPledge(0), 0);
        assertEq(crowdfund.getCampaignDuration(0), duration);
        assertEq(crowdfund.getCampaignStartAt(0), uint32(block.timestamp));
        assertEq(crowdfund.getCampaignClaimed(0), false);
    }

    function testPledgeNotStarted() public {
        vm.startPrank(funder2);
        vm.expectRevert("Not started.");
        crowdfund.pledge(0, 30 * 10**18);
        vm.stopPrank();
    }

    function testPledgeAlreadyEnded() public {
        testStartOk();
        vm.warp(block.timestamp + duration + 1);
        vm.startPrank(funder2);
        vm.expectRevert("Already ended.");
        crowdfund.pledge(0, 30 * 10**18);
        vm.stopPrank();
    }

    function testPledgeOk() public {
        testStartOk();
        vm.startPrank(funder2);
        token.approve(address(crowdfund), 30 * 10**18);
        assertEq(token.balanceOf(funder2), 50 * 10**token.decimals());
        crowdfund.pledge(0, 30 * 10**18);
        assertEq(token.balanceOf(funder2), 20 * 10**token.decimals());
        assertEq(crowdfund.getCampaignPledge(0), 30 * 10**18);
        assertEq(crowdfund.getCampaignAddressPledge(0, funder2), 30 * 10**18);
        vm.stopPrank();
    }

    function testUnpledgeNotStarted() public {
        vm.startPrank(funder2);
        vm.expectRevert("Not started.");
        crowdfund.unpledge(0, 30 * 10**18);
        vm.stopPrank();
    }

    function testUnpledgeAlreadyEnded() public {
        testStartOk();
        vm.warp(block.timestamp + duration + 1);
        vm.startPrank(funder2);
        vm.expectRevert("Already ended.");
        crowdfund.unpledge(0, 30 * 10**18);
        vm.stopPrank();
    }

    function testUnpledgeNotEnough() public {
        testPledgeOk();
        vm.startPrank(funder2);
        vm.expectRevert("Not enough pledge.");
        crowdfund.unpledge(0, 40 * 10**18);
        vm.stopPrank();
    }

    function testUnpledgeOk() public {
        testPledgeOk();
        vm.startPrank(funder2);
        assertEq(token.balanceOf(funder2), 20 * 10**token.decimals());
        crowdfund.unpledge(0, 30 * 10**18);
        assertEq(token.balanceOf(funder2), 50 * 10**token.decimals());
        assertEq(crowdfund.getCampaignPledge(0), 0);
        assertEq(crowdfund.getCampaignAddressPledge(0, funder2), 0);
        vm.stopPrank();
    }

    function testClaimNotCreator() public {
        testStartOk();
        vm.expectRevert("Only creator.");
        crowdfund.claim(0);
    }

    function testClaimNotEnded() public {
        testStartOk();
        vm.startPrank(creator);
        vm.expectRevert("Not ended.");
        crowdfund.claim(0);
        vm.stopPrank();
    }

    function testClaimGoalNotReached() public {
        testPledgeOk();
        vm.warp(block.timestamp + duration + 1);
        vm.startPrank(creator);
        vm.expectRevert("Goal was not reached.");
        crowdfund.claim(0);
        vm.stopPrank();
    }

    function testClaimGoalReached() public {
        testPledgeOk();

        vm.startPrank(funder3);
        token.approve(address(crowdfund), 10 * 10**18);
        assertEq(token.balanceOf(funder3), 50 * 10**token.decimals());
        crowdfund.pledge(0, 10 * 10**18);
        assertEq(token.balanceOf(funder3), 40 * 10**token.decimals());
        assertEq(crowdfund.getCampaignPledge(0), 40 * 10**18);
        assertEq(crowdfund.getCampaignAddressPledge(0, funder3), 10 * 10**18);
        vm.stopPrank();

        vm.warp(block.timestamp + duration + 1);

        vm.startPrank(creator);
        assertEq(crowdfund.getCampaignClaimed(0), false);
        assertEq(
            token.balanceOf(address(crowdfund)),
            crowdfund.getCampaignPledge(0)
        );
        assertEq(token.balanceOf(creator), 0);
        crowdfund.claim(0);
        assertEq(token.balanceOf(address(crowdfund)), 0);
        assertEq(token.balanceOf(creator), crowdfund.getCampaignPledge(0));
        assertEq(crowdfund.getCampaignClaimed(0), true);
        vm.stopPrank();
    }

    function testClaimAlreadyClaimed() public {
        testClaimGoalReached();

        vm.startPrank(creator);
        vm.expectRevert("Already claimed.");
        crowdfund.claim(0);
        vm.stopPrank();
    }

    function testRefundNotEnded() public {
        vm.expectRevert("Not ended.");
        crowdfund.refund(0);
    }

    function testRefundNotEnoughPledge() public {
        testPledgeOk();
        vm.warp(block.timestamp + duration + 1);
        vm.expectRevert("Not enough pledge.");
        crowdfund.refund(0);
    }

    function testRefundOk() public {
        testPledgeOk();
        vm.startPrank(funder2);
        vm.warp(block.timestamp + duration + 1);
        assertEq(token.balanceOf(funder2), 20 * 10**token.decimals());
        crowdfund.refund(0);
        assertEq(token.balanceOf(funder2), 50 * 10**token.decimals());
        vm.stopPrank();
    }
}
