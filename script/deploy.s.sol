// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/Bod.sol";
import "../src/BodManager.sol";
import "../src/CDPContract.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Deploy the Bod contract
        Bod bod = new Bod();
        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));
        bod.initialize(deployer, deployer);

        // Deploy the BodManager contract
        BodManager bodManager = new BodManager();
        bodManager.initialize(deployer);

        // Deploy the CDPContract
        CDPContract cdpContract = new CDPContract(address(bod));

        console.log("Bod deployed at:", address(bod));
        console.log("BodManager deployed at:", address(bodManager));
        console.log("CDPContract deployed at:", address(cdpContract));

        vm.stopBroadcast();
    }
}
