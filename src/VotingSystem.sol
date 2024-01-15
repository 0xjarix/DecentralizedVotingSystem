// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

contract VotingSystem {
    // Errors
    error VotingSystem__AlreadyRegistered();
    error VotingSystem__AlreadyVoted();
    error VotingSystem__OnlyOwnerCanAddCandidates();
    error VotingSystem__NotRegisteredYet();
    error VotingSystem__CandidateNotFound();
    error VotingSystem__VotingNotFinished();
    error VotingSystem__VotingFinished();

    // State Variables
    // owner of the contract
    address public immutable i_owner;
    // start time of the voting
    uint40 public immutable i_startTime;
    // DURATION of the voting
    uint40 public constant DURATION = 1 weeks;

    // constants used for `voterState` in `s_voters` mapping
    uint8 private constant DISALLOWED = 0;
    uint8 private constant ALLOWED = 1;
    uint8 private constant VOTED = 2;
    
    // total number of votes
    uint256 private s_totalVotes;

    // struct for candidate
    struct Candidate {
        string name;
        uint256 voteCount;
    }

    // mapping for voters
    mapping(address voter => uint8 voterState) public s_voters;
    Candidate[] public s_candidates;

    // events
    event VoterRegistered(address indexed voter);
    event CandidateAdded(string indexed name);
    event VoteCasted(address indexed voter, uint256 indexed candidateIndex);
    event WinnerAnnounced(string indexed name);

    constructor() {
        i_startTime = uint40(block.timestamp);
        i_owner = msg.sender;
    }

    function registerToVote() external {
        if (block.timestamp > i_startTime + DURATION)
            revert VotingSystem__VotingFinished();
        if(s_voters[msg.sender] == 1)
            revert VotingSystem__AlreadyRegistered();
        if (s_voters[msg.sender] == 2)
            revert VotingSystem__AlreadyVoted();
        
        s_voters[msg.sender] = 1;
        emit VoterRegistered(msg.sender);
    }

    // only owner can add candidates
    function addCandidate(string memory _name) external {
        if (block.timestamp > i_startTime + DURATION)
            revert VotingSystem__VotingFinished();
        if (msg.sender != i_owner)
            revert VotingSystem__OnlyOwnerCanAddCandidates();
        s_candidates.push(Candidate(_name, 0));
        emit CandidateAdded(_name);
    }

    // vote for a candidate
    function vote(string memory _name) external {
        if (block.timestamp > i_startTime + DURATION)
            revert VotingSystem__VotingFinished();
        if(s_voters[msg.sender] == 0)
            revert VotingSystem__NotRegisteredYet();
        if (s_voters[msg.sender] == 2)
            revert VotingSystem__AlreadyVoted();
        
        s_voters[msg.sender] = 2;
        for (uint256 i = 0; i < s_candidates.length; i++) {
            if (keccak256(abi.encodePacked(s_candidates[i].name)) == keccak256(abi.encodePacked(_name))) {
                unchecked {
                    s_candidates[i].voteCount++;
                    s_totalVotes++;
                    }
                emit VoteCasted(msg.sender, i);
                return;
            }
            unchecked {i++;}
        }
        revert VotingSystem__CandidateNotFound();
    }

    // announce winner after voting is finished
    function announceWinner() external returns (string memory) {
        if (block.timestamp < i_startTime + DURATION)
            revert VotingSystem__VotingNotFinished();
        uint256 maxVotes;
        uint256 maxVotesIndex;
        for (uint256 i = 0; i < s_candidates.length;) {
            if (s_candidates[i].voteCount > maxVotes) {
                maxVotes = s_candidates[i].voteCount;
                maxVotesIndex = i;
            }   
            unchecked {i++;}
        }
        emit WinnerAnnounced(s_candidates[maxVotesIndex].name);
        return s_candidates[maxVotesIndex].name;
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
        revert VotingSystem__CandidateNotFound();
    }

    function getVoterState(address _voter) external view returns (uint8) {
        return s_voters[_voter];
    }

    function getTotalVotes() external view returns (uint256) {
        return s_totalVotes;
    }   
}