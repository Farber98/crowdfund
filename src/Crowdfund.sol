// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract Crowdfund {
    struct Campaign {
        address public immutable payable creator;
        uint256 public immutable goal;
        uint256 public pledged;
        uint32 public immutable duration;
        uint32 public startAt;
        bool public claimed;
    }

    IERC20 public immutable token;
    uint public count;
    mapping(uint => Campaign) public campaigns;
    mapping(uint => mapping(address => uint)) public campaignAddressPledge;

    event Start(uint256 campaingId, address indexed creator, uint256 goal, uint32 startAt, uint32, endAt);
    event Pledge(uint256 campaingId, address indexed pledger, uint256 amount);
    event Unpledge(uint256 campaingId, address indexed unpledger, uint256 amount);
    event Claim(uint256 campaingId);
    event Refund(uint256 campaingId, address indexed refunder, uint256 balance);

    constructor(address _token) {
        token = IERC20(_token);
    }

    function start(uint _goal, uint32 _duration) external {
        Campaign cmp = new Campaign(
            creator: msg.sender,
            goal: _goal,
            pledged: 0,
            duration: _duration,
            startAt: block.timestamp,
            claimed: false,
        );

        campaigns[count] = cmp;
        count++;
        emit Start(count,msg.sender,_goal, block.timestamp, block.timestamp + _duration);

    }

    function pledge(uint256 _id, uint256 _amount) external payable {
        Campaign storage campaign = campaigns[_id];
        
        require(campaign.startAt != uint32(0), "Not started.");
        require(campaign.startAt + campaign.duration > block.timestamp, "Already ended.");

        campaign.pledge += _amount;
        campaignAddressPledge[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);
        
        emit Pledge(_id, msg.sender, msg.value);
    }

    function unpledge(uint256 _id, uint256 _amount) external {
        Campaign storage campaign = campaigns[_id];
        
        require(campaign.startAt + campaign.duration > block.timestamp, "Already ended.");
        require(campaignAddressPledge[_id][msg.sender] >= _amount, "Not enough pledge.");

        campaign.pledge -= _amount;
        campaignAddressPledge[_id][msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);
        emit Unpledge(_id, msg.sender, _amount);
    }

    function claim(uint256 _id) external {
        Campaign storage campaign = campaigns[_id];

        require(campaign.creator == msg.sender, "Only creator.");
        require(campaign.startAt + campaign.duration < block.timestamp, "Not ended.");
        require(!campaign.claimed, "Already claimed.");
        require(campaign.pledged >= campaign.goal, "Goal was not reached.");

        campaign.claimed = true;

        token.transfer(campaign.creator, campaign.pledged);

        emit Claim(_id);

    }

    function refund(uint256 _id) external {
        Campaign memory campaign = campaigns[_id];
        require(campaign.startAt + campaign.duration < block.timestamp, "Not ended.");
        require(campaignAddressPledge[_id][msg.sender] > 0, "Not enough pledge.");
        
        bal = campaignAddressPledge[_id][msg.sender];
        campaignAddressPledge[_id][msg.sender] = 0;
        token.transfer(msg.sender,bal);
        
        emit Refund(_id, msg.sender, bal);
    }
}
