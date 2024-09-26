// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "forge-std/Script.sol";
import "../src/BodManager.sol";
import "../src/Bod.sol";
import "../src/CDPContract.sol";
import "../src/BitDSMAVS.sol";

contract DeployScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        // Deploy the BodManager contract
        BodManager bodManager = new BodManager();
        address deployer = vm.addr(vm.envUint("PRIVATE_KEY"));
        bodManager.initialize(deployer);

        console.log("BodManager deployed at:", address(bodManager));

        // Deploy the Bod contract
        Bod bod = new Bod();
        bod.initialize(deployer, address(bodManager), "btc_address_placeholder");

        console.log("Bod deployed at:", address(bod));

        // After deploying Bod and before locking Bitcoin
        console.log("Creating Bod for deployer...");
        bodManager.createBod("bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh");

        console.log("Locking Bitcoin in Bod...");
        uint256 bitcoinAmount = 2; // 2 BTC in satoshis
        bytes32 dummyTxHash = bytes32(uint256(1)); // Dummy transaction hash
        bodManager.lockBitcoin(dummyTxHash, bitcoinAmount);
        //get lockedBitcoin
        uint256 lockedBitcoin = bod.getLockedBitcoin();
        console.log("Locked Bitcoin amount:", lockedBitcoin);

        console.log("Bitcoin locked in Bod");

        // Deploy the CDP contract
        CDPContract cdp = new CDPContract(address(bod));

        console.log("CDP deployed at:", address(cdp));

        // Mint some stablecoin
        uint256 mintAmount = 1; // Example amount to mint
        cdp.mintStablecoin(mintAmount);

        // Log the balance of the deployer
        uint256 stablecoinBalance = cdp.balanceOf(deployer);
        console.log("Stablecoin balance of deployer:", stablecoinBalance);

        // EigenLayer Holesky addresses
        address HOLESKY_DELEGATION_MANAGER_ADDRESS = 0xA44151489861Fe9e3055d95adC98FbD462B948e7;
        address HOLESKY_STAKE_REGISTRY_ADDRESS = 0x41F6a9eCC12c3Df46608270aAf6C458525269507;
        address HOLESKY_AVS_DIRECTORY_ADDRESS = 0x055733000064333CaDDbC92763c58BF0192fFeBf;

        // Assuming the contract interfaces are IAVSDirectory, IRegistryCoordinator, and IStakeRegistry
        IAVSDirectory avsDirectory = IAVSDirectory(HOLESKY_AVS_DIRECTORY_ADDRESS);
        IRegistryCoordinator registryCoordinator = IRegistryCoordinator(HOLESKY_STAKE_REGISTRY_ADDRESS);
        IStakeRegistry stakeRegistry = IStakeRegistry(HOLESKY_DELEGATION_MANAGER_ADDRESS);

        // Use the contract instances directly
        // someFunction(
        //     avsDirectory,
        //     registryCoordinator,
        //     stakeRegistry
        // );

        // Deploy BitDSMAVS
        BitDSMAVS avs = new BitDSMAVS(
            avsDirectory,
            registryCoordinator,
            stakeRegistry,
            address(bodManager),
            address(cdp)
        );

        console.log("BitDSMAVS deployed at:", address(avs));

        vm.stopBroadcast();
    }
}
