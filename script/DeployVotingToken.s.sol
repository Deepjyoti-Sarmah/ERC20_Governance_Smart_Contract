// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {console} from "forge-std/console.sol";
import {VotingToken} from "../src/VotingToken.sol";

contract DeployVotingToken {
    VotingToken public votingToken;

    function run() public {
        votingToken = new VotingToken();
        console.log("VotingToken deployed to:", address(votingToken));
    }
}

// VotingToken deployed to: 0xC7f2Cf4845C6db0e1a1e91ED41Bcd0FcC1b0E141
