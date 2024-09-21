// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {CDPContract} from "../src/CDPContract.sol";

contract DeployCDPContract is Script {
    CDPContract public cdpContract;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Deploy the CDPContract
        cdpContract = new CDPContract();

        console.log("CDPContract deployed at:", address(cdpContract));

        vm.stopBroadcast();
    }
}
