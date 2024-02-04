// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {console} from "forge-std/console.sol";
import {VotingToken} from "../src/VotingToken.sol";

contract DeployVotingToken {
    VotingToken public votingToken;

    function setup() public {
        votingToken = new VotingToken();
        console.log("VotingToken deployed to:", address(votingToken));
    }
}
