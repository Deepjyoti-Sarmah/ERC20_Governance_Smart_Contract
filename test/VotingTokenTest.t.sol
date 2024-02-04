// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {Test, console} from "forge-std/Test.sol";
import {VotingToken} from "../src/VotingToken.sol";

contract VotingTokenTest is Test {
    VotingToken votingToken;
    address public USER = makeAddr("user");
    uint256 public constant INITIAL_SUPPLY = 200 ether;

    function setUp() public {
        votingToken = new VotingToken();
        votingToken.mint(USER, INITIAL_SUPPLY);
    }

    function testInitialSupply() public {
        assertEq(votingToken.balanceOf(USER), INITIAL_SUPPLY);
    }

    function testMint() public {
        uint256 initialBalance = votingToken.balanceOf(USER);
        votingToken.mint(USER, 100 ether);
        assertEq(votingToken.balanceOf(USER), initialBalance + 100 ether);
    }

    function testTransfer() public {
        address recipient = makeAddr("recipient");
        uint256 transferAmount = 100 ether;
        uint256 initialBalance = votingToken.balanceOf(USER);

        // Check that the USER has enough balance to cover the transfer amount
        require(initialBalance >= transferAmount, "User does not have enough balance");

        votingToken.transfer(recipient, transferAmount);
        assertEq(votingToken.balanceOf(USER), initialBalance - transferAmount);
        assertEq(votingToken.balanceOf(recipient), transferAmount);
    }
}
