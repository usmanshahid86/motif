// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "../src/governance/Token.sol";
import "../src/governance/TokenStorage.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract TokenUnitTest is Test {
    BitDSMToken public token;
    TransparentUpgradeableProxy public proxy;
    ProxyAdmin public proxyAdmin;
    address owner = address(1);

    function setUp() public {
        // Deploy implementation
        BitDSMToken implementation = new BitDSMToken();

        // Deploy ProxyAdmin
        proxyAdmin = new ProxyAdmin();

        // Prepare initialization data
        bytes memory initData = abi.encodeWithSelector(
            BitDSMToken.initialize.selector,
            owner
        );

        // Deploy proxy
        proxy = new TransparentUpgradeableProxy(
            address(implementation),
            address(proxyAdmin),
            initData
        );

        token = BitDSMToken(address(proxy));
    }

    function testInitialSupply() public {
        assertEq(token.totalSupply(), token.INITIAL_SUPPLY());
    }

    function testEmitNewTokens() public {
        vm.prank(owner);
        token.emitNewTokens(owner);
        // Add assertions to check the new supply
        assertEq(token.totalSupply(), token.INITIAL_SUPPLY() + 1000000 * 10**18);
    }

    

    /*//////////////////////////////////////////////////////////////
                        EMISSION TESTS
    //////////////////////////////////////////////////////////////*/
    
    function testEmissionCalculation() public {
        // Test basic emission calculation
        vm.warp(block.timestamp + 1 days);
        uint256 expectedAmount = token.getNextEmissionAmount();
        vm.prank(owner);
        token.emitNewTokens(owner);
        assertEq(token.totalSupply(), token.INITIAL_SUPPLY() + expectedAmount);
    }

    function testEmissionRateLimits() public {
        // Test daily emission limits
        vm.warp(block.timestamp + 1 days);
        vm.prank(owner);
        token.emitNewTokens(owner);
        vm.expectRevert("Wait 24 hours between emissions");
        vm.prank(owner);
        token.emitNewTokens(owner);
    }

    function testSupplyCapEnforcement() public {
        // Test supply cap
        uint256 newCap = token.INITIAL_SUPPLY();
        vm.prank(owner);
        token.setMaxSupplyCap(newCap);
        vm.warp(block.timestamp + 1 days);
        vm.expectRevert(abi.encodeWithSelector(ITokenInterface.SupplyCapExceeded.selector, 0, 0));
        vm.prank(owner);
        token.emitNewTokens(owner);
    }

    /*//////////////////////////////////////////////////////////////
                        GUARDIAN SYSTEM TESTS
    //////////////////////////////////////////////////////////////*/

    function testGuardianAddition() public {
        address newGuardian = address(2);
        
        // Schedule guardian addition
        vm.prank(owner);
        token.scheduleAddGuardian(newGuardian);
        
        // Wait for timelock
        vm.warp(block.timestamp + token.GUARDIAN_TIMELOCK_DELAY());
        
        // Execute addition
        bytes32 operationId = keccak256(
            abi.encodePacked("ADD_GUARDIAN", newGuardian, block.timestamp - token.GUARDIAN_TIMELOCK_DELAY())
        );
        vm.prank(owner);
        token.executeAddGuardian(operationId, newGuardian);
        
        assertTrue(token.guardians(newGuardian));
    }

    // Helper function to add a guardian
    function _addGuardian(address guardian) internal {
        vm.startPrank(owner);
        token.scheduleAddGuardian(guardian);
        vm.warp(block.timestamp + token.GUARDIAN_TIMELOCK_DELAY());
        bytes32 operationId = keccak256(
            abi.encodePacked("ADD_GUARDIAN", guardian, block.timestamp - token.GUARDIAN_TIMELOCK_DELAY())
        );
        token.executeAddGuardian(operationId, guardian);
        vm.stopPrank();
    }

    function testGuardianRemoval() public {
        address guardian = address(2);
        _addGuardian(guardian);

        // Test removal
        vm.prank(owner);
        token.scheduleRemoveGuardian(guardian);
        vm.warp(block.timestamp + token.GUARDIAN_TIMELOCK_DELAY());
        bytes32 removeOperationId = keccak256(
            abi.encodePacked("REMOVE_GUARDIAN", guardian, block.timestamp - token.GUARDIAN_TIMELOCK_DELAY())
        );
        vm.prank(owner);
        token.executeRemoveGuardian(removeOperationId, guardian);
        
        assertFalse(token.guardians(guardian));
    }

    /*//////////////////////////////////////////////////////////////
                        EMERGENCY SYSTEM TESTS
    //////////////////////////////////////////////////////////////*/

    function testEmergencyPause() public {
        address guardian = address(2);
        _addGuardian(guardian);

        // Test emergency pause
        vm.prank(guardian);
        token.proposeEmergencyPause();
        bytes32 actionId = keccak256(abi.encodePacked("PAUSE", block.timestamp));
        vm.prank(guardian);
        token.executeEmergencyPause(actionId);
        
        assertTrue(token.paused());
    }

    /*//////////////////////////////////////////////////////////////
                        TIMELOCK OPERATION TESTS
    //////////////////////////////////////////////////////////////*/

    function testTimelockOperations() public {
        // Test scheduling and executing timelock operations
        uint256 newCap = token.INITIAL_SUPPLY() * 2;
        vm.prank(owner);
        token.scheduleSetMaxSupplyCap(newCap);
        
        vm.warp(block.timestamp + token.TIMELOCK_MIN_DELAY());
        
        vm.prank(owner);
        token.executeTimelockOperation(
            address(token),
            0,
            abi.encodeWithSelector(token.setMaxSupplyCap.selector, newCap),
            bytes32(0),
            bytes32(0)
        );
        
        assertEq(token.maxSupplyCap(), newCap);
    }

    /*//////////////////////////////////////////////////////////////
                        BLACKLIST TESTS
    //////////////////////////////////////////////////////////////*/

    function testBlacklistFunctionality() public {
        address user = address(2);
        vm.deal(user, 1 ether);
        
        // Transfer some tokens to user
        vm.prank(owner);
        token.transfer(user, 1000);
        
        // Blacklist user
        vm.prank(owner);
        token.setBlacklisted(user, true);
        
        // Test transfer restrictions
        vm.expectRevert("Blacklisted");
        vm.prank(user);
        token.transfer(address(3), 100);
    }

    /*//////////////////////////////////////////////////////////////
                        DAILY MINT LIMIT TESTS
    //////////////////////////////////////////////////////////////*/

    function testDailyMintLimit() public {
        uint256 maxDaily = token.MAX_DAILY_MINT();
        
        // Mint up to the daily limit
        vm.prank(owner);
        token.emitNewTokens(owner);
        
        // Attempt to mint more than the daily limit and expect a revert
        vm.expectRevert("Daily mint limit");
        vm.prank(owner);
        token.emitNewTokens(owner);
    }
}