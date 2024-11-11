// test/AppRegistry.t.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "../src/core/AppRegistry.sol";

contract AppRegistryTest is Test {
    AppRegistry public appRegistry;
    address public owner;
    address public app;
    uint256 private signerPrivateKey;

    function setUp() public {
        signerPrivateKey = vm.envUint("PRIVATE_KEY");
        owner = address(this);
        app = vm.addr(signerPrivateKey);

        appRegistry = new AppRegistry();
        appRegistry.initialize(owner);
    }

    function testRegisterApp() public {
        bytes32 salt = keccak256("test_salt");
        uint256 expiry = block.timestamp + 1 hours;

        bytes32 digestHash = appRegistry.calculateAppRegistrationDigestHash(app, address(appRegistry), salt, expiry);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digestHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.prank(app);
        appRegistry.registerApp(app, signature, salt, expiry);

        assertTrue(appRegistry.isAppRegistered(app));
    }

    function testDeregisterApp() public {
        // First, register the app
        testRegisterApp();

        // Now deregister
        vm.prank(owner);
        appRegistry.deregisterApp(app);

        assertFalse(appRegistry.isAppRegistered(app));
    }

    function testCannotRegisterTwice() public {
        testRegisterApp();

        bytes32 salt = keccak256("new_salt");
        uint256 expiry = block.timestamp + 1 hours;

        bytes32 digestHash = appRegistry.calculateAppRegistrationDigestHash(app, address(appRegistry), salt, expiry);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digestHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("AppRegistry: app already registered");
        vm.prank(app);
        appRegistry.registerApp(app, signature, salt, expiry);
    }

    function testCannotUseExpiredSignature() public {
        bytes32 salt = keccak256("test_salt");
        uint256 expiry = block.timestamp - 1; // Expired

        bytes32 digestHash = appRegistry.calculateAppRegistrationDigestHash(app, address(appRegistry),salt, expiry);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPrivateKey, digestHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        vm.expectRevert("AppRegistry: signature expired");
        vm.prank(app);
        appRegistry.registerApp(app, signature, salt, expiry);
    }
}
