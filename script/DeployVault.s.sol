// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {console} from "forge-std/console.sol";
import {Vault} from "../src/Vault.sol";

contract DeployVault {
    Vault public vault;

    function setup() public {
        vault = new Vault();
        console.log("Vault deployed to:", address(vault));
    }
}
