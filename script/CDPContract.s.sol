// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {CDPContract} from "../src/CDPContract.sol";
import {Bod} from "../src/Bod.sol";

contract DeployCDPContract is Script {
    CDPContract public cdpContract;
    Bod public bod;
    address public bodOwner;

    function setUp() public {
        bodOwner = msg.sender;
    }

    function run() public {
        vm.startBroadcast();

        // Deploy the Bod contract
        bod = new Bod();
        bod.initialize(msg.sender, address(this), "defaultBitcoinAddress");

        // Set the bodOwner in Bod contract
        bod.setBodOwner(bodOwner);

        // Deploy the CDPContract
        cdpContract = new CDPContract(address(bod));

        console.log("CDPContract deployed at:", address(cdpContract));

        vm.stopBroadcast();
    }
}