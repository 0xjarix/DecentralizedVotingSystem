// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {VotingSystem} from "../src/VotingSystem.sol";

contract VotingSystemTest is Test {
    VotingSystem votingSystem;
    struct Candidate {
        string name;
        uint256 voteCount;
    }

    Candidate[] public s_candidates;
    function setUp() public {
        votingSystem = new VotingSystem();
        votingSystem.addCandidate("Alice");
        votingSystem.addCandidate("Bob");
        votingSystem.addCandidate("Charlie");
        assert (votingSystem.i_startTime() == block.timestamp);
        assert (votingSystem.i_owner() == address(this));
    }

    function testRegisterToVote() public {
        vm.prank(address(0x1));
        votingSystem.registerToVote();
        assert (votingSystem.s_voters(address(0x1)) == 1);
        vm.prank(address(0x1));
        vm.expectRevert(VotingSystem.VotingSystem__AlreadyRegistered.selector);
        votingSystem.registerToVote();
    }

    function testAddCandidateByOwner() public {
        votingSystem.addCandidate("Szabo");
        assert (votingSystem.getVotesFor("Szabo") == 0);
        votingSystem.addCandidate("Finney");
        assert (votingSystem.getVotesFor("Finney") == 0);
    }

    function testAddCandidateByNonOwner() public {
        vm.prank(address(0x1));
        vm.expectRevert(VotingSystem.VotingSystem__OnlyOwnerCanAddCandidates.selector);
        votingSystem.addCandidate("Dennis");
    }

    function testVote() public {
        vm.startPrank(address(0x2));
        votingSystem.registerToVote();
        vm.expectRevert(VotingSystem.VotingSystem__CandidateNotFound.selector);
        votingSystem.vote("Vitalik");
        votingSystem.vote("Alice");
        assert (votingSystem.getVotesFor("Alice") == 1);
        vm.expectRevert(VotingSystem.VotingSystem__AlreadyVoted.selector);
        votingSystem.vote("Bob");
    }

    function testAnnounceWinner() public {
        vm.startPrank(address(0x5));
        votingSystem.registerToVote();
        votingSystem.vote("Alice");
        vm.startPrank(address(0x4));
        votingSystem.registerToVote();
        votingSystem.vote("Charlie");
        vm.startPrank(address(0x3));
        votingSystem.registerToVote();
        votingSystem.vote("Alice");
        vm.warp(votingSystem.i_startTime() + 1 weeks + 1);
        votingSystem.announceWinner();
        assert (votingSystem.getVotesFor("Alice") == 2);
        assert (votingSystem.getVotesFor("Charlie") == 1);
        assert (keccak256(abi.encodePacked(votingSystem.announceWinner())) == keccak256(abi.encodePacked("Alice"))); // If Alice had 1 vote she would have won with our code, because she was added first, our code is intended for large elections where candidates having the same amount of votes is nearly impossible
    }
}
