// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {MyGovernor} from "../src/MyGovernor.sol";
import {Vault} from "../src/Vault.sol";
import {VotingToken} from "../src/VotingToken.sol";
import {TimeLock} from "../src/TimeLock.sol";

contract MyGovernorTest is Test {
    MyGovernor governor;
    Vault vault;
    TimeLock timelock;
    VotingToken votingToken;

    address public USER = makeAddr("user");
    uint256 public constant INITIAL_SUPPLY = 100 ether;

    address[] proposers;
    address[] executors;

    uint256[] values;
    bytes[] calldatas;
    address[] targets;

    uint256 public constant MINT_DELAY = 3600; //1 hour - after a vote passes
    uint256 public constant VOTING_DELAY = 1; // how many blocks till a vote is active
    uint256 public constant VOTING_PERIOD = 50400;

    function setUp() public {
        votingToken = new VotingToken();
        votingToken.mint(USER, INITIAL_SUPPLY);

        vm.startPrank(USER);
        votingToken.delegate(USER);
        timelock = new TimeLock(MINT_DELAY, proposers, executors);
        governor = new MyGovernor(votingToken, timelock);

        bytes32 proposerRole = timelock.PROPOSER_ROLE();
        bytes32 executorRole = timelock.EXECUTOR_ROLE();
        bytes32 adminRole = timelock.TIMELOCK_ADMIN_ROLE();

        timelock.grantRole(proposerRole, address(governor));
        timelock.grantRole(executorRole, address(0));
        timelock.revokeRole(adminRole, USER);
        vm.stopPrank();

        vault = new Vault();
        vault.transferOwnership(address(timelock));
    }

    function testCantUpdateBoxWithoutGovernance() public {
        vm.expectRevert();
        vault.store(1);
    }

    function testGovernanceUpdatesBox() public {
        uint256 valueToStore = 888;
        string memory description = "store 1 in Box";
        bytes memory encodedFunctionCalls = abi.encodeWithSignature("store(uint256)", valueToStore);

        values.push(0);
        calldatas.push(encodedFunctionCalls);
        targets.push(address(vault));

        //1. propose to the DAO
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        //view the state
        console.log("Proposal State:", uint256(governor.state(proposalId)));

        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);

        console.log("Proposal State:", uint256(governor.state(proposalId)));

        //2. Vote
        string memory reason = "cuz blue frog is cool";

        uint8 voteWay = 1; //voting yes
        vm.prank(USER);
        governor.castVoteWithReason(proposalId, voteWay, reason);

        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.number + VOTING_PERIOD + 1);

        //3. Queue the TX
        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.queue(targets, values, calldatas, descriptionHash);

        vm.warp(block.timestamp + MINT_DELAY + 1);
        vm.roll(block.number + MINT_DELAY + 1);

        //4. Execuute
        governor.execute(targets, values, calldatas, descriptionHash);

        assert(vault.getNumber() == valueToStore);
        console.log("Box Value:", vault.getNumber());
    }

    function testNonOwnerCannotTransferOwnership() public {
        address nonOwner = makeAddr("nonOwner");
        vm.startPrank(nonOwner);
        vm.expectRevert();
        vault.transferOwnership(nonOwner);
        vm.stopPrank();
    }

    function testNonProposerCannotPropose() public {
        address nonProposer = makeAddr("nonProposer");
        vm.startPrank(nonProposer);
        vm.expectRevert();
        governor.propose(targets, values, calldatas, "test proposal");
        vm.stopPrank();
    }

    function testProposalState() public {
        uint256 valueToStore = 999;
        string memory description = "store 999 in Box";
        bytes memory encodedFunctionCalls = abi.encodeWithSignature("store(uint256)", valueToStore);

        values.push(0);
        calldatas.push(encodedFunctionCalls);
        targets.push(address(vault));

        // Propose to the DAO
        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        // Check the initial state
        assertEq(uint256(governor.state(proposalId)), 0, "Initial state is not Pending");

        // Fast forward time to surpass the voting delay
        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);

        // Check the state after the voting delay
        assertEq(uint256(governor.state(proposalId)), 1, "State after voting delay is not Active");
    }

    function testOnlyProposerCanPropose() public {
        address nonProposer = makeAddr("nonProposer");
        vm.startPrank(nonProposer);
        vm.expectRevert();
        governor.propose(targets, values, calldatas, "test proposal");
        vm.stopPrank();
    }

    function testOnlyExecutorCanExecute() public {
        address nonExecutor = makeAddr("nonExecutor");
        vm.startPrank(nonExecutor);
        vm.expectRevert();
        governor.execute(targets, values, calldatas, "test proposal");
        vm.stopPrank();
    }

    function testUserCannotVoteTwiceOnSameProposal() public {
        uint256 valueToStore = 888;
        string memory description = "store 1 in Box";
        bytes memory encodedFunctionCalls = abi.encodeWithSignature("store(uint256)", valueToStore);

        values.push(0);
        calldatas.push(encodedFunctionCalls);
        targets.push(address(vault));

        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        vm.warp(block.timestamp + VOTING_DELAY + 1);
        vm.roll(block.number + VOTING_DELAY + 1);

        string memory reason = "cuz blue frog is cool";
        uint8 voteWay = 1; //voting yes

        vm.prank(USER);
        governor.castVoteWithReason(proposalId, voteWay, reason);

        vm.expectRevert();
        governor.castVoteWithReason(proposalId, voteWay, reason);
        vm.stopPrank();
    }

    // function testProposalCanBeCancelled() public {
    //     uint256 valueToStore = 888;
    //     string memory description = "store 1 in Box";
    //     bytes memory encodedFunctionCalls = abi.encodeWithSignature("store(uint256)", valueToStore);

    //     values.push(0);
    //     calldatas.push(encodedFunctionCalls);
    //     targets.push(address(vault));

    //     uint256 proposalId = governor.propose(targets, values, calldatas, description);

    //     vm.warp(block.timestamp + VOTING_DELAY + 1);
    //     vm.roll(block.number + VOTING_DELAY + 1);

    //     string memory reason = "cuz blue frog is cool";
    //     uint8 voteWay = 1; //voting yes

    //     vm.prank(USER);
    //     governor.castVoteWithReason(proposalId, voteWay, reason);

    //     vm.expectRevert();
    //     governor.cancel(proposalId);
    //     vm.stopPrank();
    // }

    function testProposalCanBeExecuted() public {
        uint256 valueToStore = 888;
        string memory description = "store 1 in Box";
        bytes memory encodedFunctionCalls = abi.encodeWithSignature("store(uint256)", valueToStore);

        values.push(0);
        calldatas.push(encodedFunctionCalls);
        targets.push(address(vault));

        uint256 proposalId = governor.propose(targets, values, calldatas, description);

        // Increase the voting delay and period
        uint256 increasedDelay = VOTING_DELAY * 2;
        uint256 increasedPeriod = VOTING_PERIOD * 2;

        vm.warp(block.timestamp + increasedDelay + 1);
        vm.roll(block.number + increasedDelay + 1);

        string memory reason = "cuz blue frog is cool";
        uint8 voteWay = 1; //voting yes

        vm.prank(USER);
        governor.castVoteWithReason(proposalId, voteWay, reason);

        vm.warp(block.timestamp + increasedPeriod + 1);
        vm.roll(block.number + increasedPeriod + 1);

        bytes32 descriptionHash = keccak256(abi.encodePacked(description));
        governor.execute(targets, values, calldatas, descriptionHash);

        assert(vault.getNumber() == valueToStore);
    }
}
