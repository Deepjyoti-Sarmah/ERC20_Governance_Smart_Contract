// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {console} from "forge-std/console.sol";
import {MyGovernor} from "../src/MyGovernor.sol";
import {VotingToken} from "../src/VotingToken.sol";
import {TimeLock} from "../src/TimeLock.sol";

contract DeployMyGovernor {
    MyGovernor public myGovernor;
    VotingToken public votingToken;
    TimeLock public timeLock;

    function run() public {
        votingToken = new VotingToken();
        timeLock = new TimeLock(3600, new address[](0), new address[](0));
        myGovernor = new MyGovernor(votingToken, timeLock);
        console.log("MyGovernor deployed to:", address(myGovernor));
    }
}

//  MyGovernor deployed to: 0x238213078DbD09f2D15F4c14c02300FA1b2A81BB