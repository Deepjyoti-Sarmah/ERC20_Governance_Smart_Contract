// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {console} from "forge-std/console.sol";
import {TimeLock} from "../src/TimeLock.sol";

contract DeployTimeLock {
    TimeLock public timelock;

    function run() public {
        uint256 minDelay = 3600; // 1 hour delay
        address[] memory proposers = new address[](0); // No proposers initially
        address[] memory executors = new address[](0); // No executors initially
        timelock = new TimeLock(minDelay, proposers, executors);
        console.log("TimeLock deployed to:", address(timelock));
    }
}


// TimeLock deployed to: 0xC7f2Cf4845C6db0e1a1e91ED41Bcd0FcC1b0E141