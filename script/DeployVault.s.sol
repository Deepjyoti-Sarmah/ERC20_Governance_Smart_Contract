// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {console} from "forge-std/console.sol";
import {Vault} from "../src/Vault.sol";

contract DeployVault {
    Vault public vault;

    function run() public {
        vault = new Vault();
        console.log("Vault deployed to:", address(vault));
    }
}

// Vault deployed to: 0xC7f2Cf4845C6db0e1a1e91ED41Bcd0FcC1b0E141
