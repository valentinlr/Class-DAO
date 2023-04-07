// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract GovernanceLogic is Governor, GovernorCountingSimple, GovernorVotes, GovernorVotesQuorumFraction, AccessControl {
    bytes32 public constant PROPOSER_ROLE = keccak256("PROPOSER_ROLE");
    uint256 private constant _VOTING_DURATION = 3 days;
    IERC721 public token;

    constructor(IERC721 _token, address[] memory proposers)
        Governor("GovernanceLogic")
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4)
    {
        token = token_;

        struct Proposal {
        uint256 proposalId;
        string description;
        uint256 voteEnd;
    }

        mapping(uint256 => Proposal) public proposals;


        // Grant the PROPOSER_ROLE to the specified proposers
        for (uint256 i = 0; i < proposers.length; i++) {
            _setupRole(PROPOSER_ROLE, proposers[i]);
        }

        // Grant the DEFAULT_ADMIN_ROLE to the deployer
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function votingDelay() public pure override returns (uint256) {
        return 0; // No delay
    }

    function votingPeriod() public pure override returns (uint256) {
        return _VOTING_DURATION;
    }

    // The following functions are overrides required by Solidity.

    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function getVotes(address account, uint256) public view override returns (uint256) {
        // One vote per ERC721 token held by the account
        return token.balanceOf(account);
    }

    function getProposalStatus(uint256 proposalId) public view returns (string memory) {
        Proposal memory proposal = proposals(proposalId);

        if (proposal.voteCount >= quorum(proposalId)) {
            return "Passed";
        } else if (block.timestamp > proposal.voteEnd) {
            return "Failed";
        } else {
            return "In Progress";
        }
    }
}

