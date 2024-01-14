// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract VotingSystem {
    address public owner;
    
    // constants used for `voterState` in `s_voters` mapping
    uint8 private constant DISALLOWED = 0;
    uint8 private constant ALLOWED = 1;
    uint8 private constant VOTED = 2;

    struct Candidate {
        string name;
        uint256 voteCount;
    }

    mapping(address voter => uint8 voterState) public s_voters;
    Candidate[] public s_candidates;

    event VoterRegistered(address indexed voter);
    event CandidateAdded(string indexed name);
    event VoteCasted(address indexed voter, uint256 indexed candidateIndex);

    constructor(Candidate[] memory _candidateNames) {
        s_candidates = _candidateNames;
        owner = msg.sender;
    }

    function registerToVote() external {
        if(s_voters[msg.sender] == 1)
            revert("Already registered");
        if (s_voters[msg.sender] == 2)
            revert("Already voted");
        
        s_voters[msg.sender] = 1;
        emit VoterRegistered(msg.sender);
    }

    function addCandidate(string memory _name) external {
        if (msg.sender != owner)
            revert("Only owner can add candidates");
        s_candidates.push(Candidate(_name, 0));
        emit CandidateAdded(_name);
    }

    function vote(string memory _name) external {
        if(s_voters[msg.sender] == 0)
            revert("Not registered yet");
        if (s_voters[msg.sender] == 2)
            revert("Already voted");
        
        s_voters[msg.sender] = 2;
        for (uint256 i = 0; i < s_candidates.length; i++) {
            if (keccak256(abi.encodePacked(s_candidates[i].name)) == keccak256(abi.encodePacked(_name))) {
                s_candidates[i].voteCount++;
                emit VoteCasted(msg.sender, i);
                return;
            }
        }
        revert("Candidate not found");
    }

    // getters
    function getElectionResults() external view returns (Candidate[] memory) {
        return s_candidates;
    }

    function getVotesFor(string memory _name) external view returns (uint256) {
        for (uint256 i = 0; i < s_candidates.length; i++) {
            if (keccak256(abi.encodePacked(s_candidates[i].name)) == keccak256(abi.encodePacked(_name))) {
                return s_candidates[i].voteCount;
            }
        }
        revert("Candidate not found");
    }
}
