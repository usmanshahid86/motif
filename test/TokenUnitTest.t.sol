// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "../src/governance/Token.sol";
import "../src/governance/TokenStorage.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "../src/governance/TokenTimelock.sol";

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

    function testInitialSupply() public view {
        assertEq(token.totalSupply(), token.INITIAL_SUPPLY());
    }

    function testEmitNewTokens() public {
        // advance time by 1 day
        vm.warp(block.timestamp + 1 days);
        vm.prank(owner);

        uint256 expectedAmount = token.getNextEmissionAmount();
        token.emitNewTokens(owner);

        // Should be INITIAL_SUPPLY + first day emission (500K tokens)
        assertEq(token.totalSupply(), token.INITIAL_SUPPLY() + expectedAmount);
    }

    function testFuzz_EmitNewTokens(uint256 timeJump) public {
        timeJump = bound(timeJump, 1 days, 365 days);
        vm.warp(block.timestamp + timeJump);
        vm.prank(owner);
        token.emitNewTokens(owner);
        assertGt(token.totalSupply(), token.INITIAL_SUPPLY());
        assertLe(token.totalSupply(), token.TARGET_TOTAL_SUPPLY());
    }

    function testDailyMintLimit() public {
    // Take a snapshot of the initial state
    uint256 snapshot = vm.snapshot();

    // Log initial timestamp
    console.log("Initial timestamp:", block.timestamp);
    
    // Reset the blockchain state and warp to a reasonable starting time
    vm.warp(1 days);
    console.log("After first warp:", block.timestamp);
    
    // Deploy contracts again to reset the lastEmissionTime
    setUp();
    
    // Log contract state
    console.log("Contract startTime:", token.startTime());
    console.log("Contract lastEmissionTime:", token.lastEmissionTime());
    
    // Warp forward one more day before first emission
    vm.warp(block.timestamp + 1 days);
    console.log("After second warp:", block.timestamp);
    
    // Test initial mint
    vm.prank(owner);
    token.emitNewTokens(owner);
    
    // Try after 23 hours (should fail)
    vm.warp(block.timestamp  + 23 hours);
    console.log("23 hours later:", block.timestamp);
    vm.prank(owner);
    vm.expectRevert("Wait 24 hours between emissions");
    token.emitNewTokens(owner);
    
    // Try after 24 hours + 1 second (should succeed)
    vm.warp(block.timestamp  + 24 hours + 1);
    console.log("24 hours + 1 second later:", block.timestamp);
    vm.prank(owner);
    token.emitNewTokens(owner);
    
    // Restore the initial state
        vm.revertTo(snapshot);
    }
    /*//////////////////////////////////////////////////////////////
                        EMISSION TESTS
    //////////////////////////////////////////////////////////////*/
    function testEmissionDecline() public {
        uint256 startTime = block.timestamp;

        // Test emissions at different points in time
        uint256[] memory testDays = new uint256[](4);
        testDays[0] = 1; // Day 1
        testDays[1] = 90; // Quarter way
        testDays[2] = 180; // Half way
        testDays[3] = 364; // Near end

        uint256 lastEmission;

        for (uint256 i = 0; i < testDays.length; i++) {
            vm.warp(startTime + (testDays[i] * 1 days));
            vm.prank(owner);

            uint256 beforeMint = token.totalSupply();
            token.emitNewTokens(owner);
            uint256 emissionAmount = token.totalSupply() - beforeMint;

            if (i > 0) {
                assertLt(
                    emissionAmount,
                    lastEmission,
                    "Emission should decrease over time"
                );
            }

            lastEmission = emissionAmount;
        }
    }
    function testEmissionPeriodEnd() public {
        // Warp to just before emission period ends
        vm.warp(block.timestamp + 365 days - 1 hours);
        vm.prank(owner);
        token.emitNewTokens(owner);

        // Warp past emission period
        vm.warp(block.timestamp + 2 days);
        vm.prank(owner);
        vm.expectRevert("Emission period ended");
        token.emitNewTokens(owner);
    }

    function testMaxSupplyCap() public {
        // Calculate total days needed to reach max supply
        uint256 startTime = block.timestamp;
        uint256 totalSupply = token.INITIAL_SUPPLY();

        for (uint256 i = 1; i <= 365; i++) {
            vm.warp(startTime + (i * 1 days));
            vm.prank(owner);
            token.emitNewTokens(owner);
        }

        assertLe(
            token.totalSupply(),
            token.TARGET_TOTAL_SUPPLY(),
            "Total supply should not exceed target"
        );
    }

    function testCalculateGrowthForDays() public {
        uint256 oneDay = token.calculateGrowthForDays(1);
        uint256 thirtyDays = token.calculateGrowthForDays(30);
        uint256 fullPeriod = token.calculateGrowthForDays(365);

        assertGt(
            oneDay,
            token.INITIAL_SUPPLY(),
            "One day growth should increase supply"
        );
        assertGt(thirtyDays, oneDay, "30 days should be more than 1 day");
        assertLe(
            fullPeriod,
            token.TARGET_TOTAL_SUPPLY(),
            "Full period should not exceed target"
        );

        vm.expectRevert("Cannot calculate beyond emission period");
        token.calculateGrowthForDays(366);
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
            abi.encodePacked(
                "ADD_GUARDIAN",
                newGuardian,
                block.timestamp - token.GUARDIAN_TIMELOCK_DELAY()
            )
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
        abi.encodePacked(
            "ADD_GUARDIAN",
            guardian,
            block.timestamp - token.GUARDIAN_TIMELOCK_DELAY()
        )
    );
    token.executeAddGuardian(operationId, guardian);
    vm.stopPrank();
}

// function testGuardianRemoval() public {
//     // Add minimum required guardians first
//     address[] memory guardians = new address[](3); // MIN_GUARDIANS is 3
//     for(uint i = 0; i < guardians.length; i++) {
//         guardians[i] = address(uint160(i + 2));
//         _addGuardian(guardians[i]);
//     }

//     // Now test removal of one guardian
//     address guardianToRemove = guardians[0];
    
//     vm.prank(owner);
//     token.scheduleRemoveGuardian(guardianToRemove);
//     vm.warp(block.timestamp + token.GUARDIAN_TIMELOCK_DELAY());
//     bytes32 removeOperationId = keccak256(
//         abi.encodePacked(
//             "REMOVE_GUARDIAN",
//             guardianToRemove,
//             block.timestamp - token.GUARDIAN_TIMELOCK_DELAY()
//         )
//     );
//     vm.prank(owner);
//     token.executeRemoveGuardian(removeOperationId, guardianToRemove);

//     assertFalse(token.guardians(guardianToRemove));
// }
    function testGuardianSystem() public {
        // Test multiple guardians
        address[] memory guardians = new address[](3);
        for (uint i = 0; i < guardians.length; i++) {
            guardians[i] = address(uint160(i + 2));
            _addGuardian(guardians[i]);
        }

        // Test emergency actions with multiple approvals
        vm.prank(guardians[0]);
        token.proposeEmergencyPause();

        bytes32 actionId = keccak256(
            abi.encodePacked("PAUSE", block.timestamp)
        );

        for (uint i = 1; i < guardians.length; i++) {
            vm.prank(guardians[i]);
            token.approveEmergencyAction(actionId);
        }

        vm.prank(guardians[0]);
        token.executeEmergencyPause(actionId);

        assertTrue(token.paused());
    }

    /*//////////////////////////////////////////////////////////////
                        EMERGENCY SYSTEM TESTS
    //////////////////////////////////////////////////////////////*/

    function testEmergencyPause() public {
        // Add multiple guardians (assuming minimum required is 3)
        address[] memory guardians = new address[](3);
        for (uint i = 0; i < guardians.length; i++) {
            guardians[i] = address(uint160(i + 2));
            _addGuardian(guardians[i]);
        }

        // First guardian proposes the pause
        vm.prank(guardians[0]);
        token.proposeEmergencyPause();
        
        bytes32 actionId = keccak256(
            abi.encodePacked("PAUSE", block.timestamp)
        );

        // Other guardians approve
        for (uint i = 1; i < guardians.length; i++) {
            vm.prank(guardians[i]);
            token.approveEmergencyAction(actionId);
        }

        // First guardian executes the pause
        vm.prank(guardians[0]);
        token.executeEmergencyPause(actionId);

        assertTrue(token.paused());
    }
    // function testEmergencySystemUnderStress() public {
    //     // Add multiple guardians
    //     address[] memory guardians = new address[](5);
    //     for (uint i = 0; i < guardians.length; i++) {
    //         guardians[i] = address(uint160(i + 10));
    //         _addGuardian(guardians[i]);
    //     }

    //     // Test multiple concurrent emergency actions
    //     bytes32[] memory actionIds = new bytes32[](3);

    //     // Propose multiple actions
    //     vm.prank(guardians[0]);
    //     token.proposeEmergencyPause();
    //     actionIds[0] = keccak256(abi.encodePacked("PAUSE", block.timestamp));

    //     vm.warp(block.timestamp + 1);
    //     vm.prank(guardians[1]);
    //     token.proposeEmergencyBurn(address(1), 1000);
    //     actionIds[1] = keccak256(
    //         abi.encodePacked("BURN", address(1), "1000", block.timestamp)
    //     );

    //     // Test approval and execution order
    //     for (uint i = 2; i < guardians.length; i++) {
    //         vm.prank(guardians[i]);
    //         token.approveEmergencyAction(actionIds[0]);
    //         token.approveEmergencyAction(actionIds[1]);
    //     }
    // }

    /*//////////////////////////////////////////////////////////////
                        TIMELOCK OPERATION TESTS
    //////////////////////////////////////////////////////////////*/

    // function testTimelockOperations() public {
    //     // Test scheduling and executing timelock operations
    //     uint256 newCap = token.INITIAL_SUPPLY() * 2;
    //     bytes memory data = abi.encodeWithSelector(token.setMaxSupplyCap.selector, newCap);
        
    //     // Setup proposers and executors for TokenTimelock
    //     address[] memory proposers = new address[](1);
    //     proposers[0] = owner;
    //     address[] memory executors = new address[](1);
    //     executors[0] = owner;
        
    //     // Deploy TokenTimelock contract with proper initialization
    //     TokenTimelock timelock = new TokenTimelock(
    //         token.TIMELOCK_MIN_DELAY(),  // minDelay
    //         proposers,                    // proposers array
    //         executors,                    // executors array
    //         owner                         // admin
    //     );
        
    //     // Grant timelock the PROPOSER_ROLE and EXECUTOR_ROLE
    //     vm.startPrank(owner);
    //     bytes32 PROPOSER_ROLE = timelock.PROPOSER_ROLE();
    //     bytes32 EXECUTOR_ROLE = timelock.EXECUTOR_ROLE();
    //     timelock.grantRole(PROPOSER_ROLE, owner);
    //     timelock.grantRole(EXECUTOR_ROLE, owner);
        
    //     // Transfer token ownership to timelock
    //     token.transferOwnership(address(timelock));
    //     vm.stopPrank();
        
    //     // Schedule operation through timelock
    //     vm.startPrank(owner);
    //     timelock.schedule(
    //         address(token),
    //         0,
    //         data,
    //         bytes32(0),
    //         bytes32(0),
    //         token.TIMELOCK_MIN_DELAY()
    //     );
        
    //     // Wait for timelock
    //     vm.warp(block.timestamp + token.TIMELOCK_MIN_DELAY());
        
    //     // Execute operation through timelock
    //     timelock.execute(
    //         address(token),
    //         0,
    //         data,
    //         bytes32(0),
    //         bytes32(0)
    //     );
    //     vm.stopPrank();

    //     assertEq(token.maxSupplyCap(), newCap);
    // }

    // function testTimelockOperationCancellation() public {
    //     uint256 newCap = token.INITIAL_SUPPLY() * 2;

    //     // Schedule operation
    //     vm.prank(owner);
    //     token.scheduleSetMaxSupplyCap(newCap);

    //     // Try to execute before delay
    //     bytes memory data = abi.encodeWithSelector(
    //         token.setMaxSupplyCap.selector,
    //         newCap
    //     );
    //     bytes32 operationId = keccak256(
    //         abi.encodePacked(data, block.timestamp)
    //     );

    //     vm.prank(owner);
    //     token.cancelTimelockOperation(operationId, address(0), "SET_MAX_CAP");

    //     // Verify operation was cancelled
    //     vm.warp(block.timestamp + token.TIMELOCK_MIN_DELAY());
    //     vm.expectRevert();
    //     vm.prank(owner);
    //     token.executeTimelockOperation(
    //         address(token),
    //         0,
    //         data,
    //         bytes32(0),
    //         bytes32(0)
    //     );
    // }

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

    function testBlacklistEdgeCases() public {
        address user = address(2);
        address recipient = address(3);

        // Setup
        vm.prank(owner);
        token.transfer(user, 1000);

        // Test blacklist during transfer
        vm.prank(owner);
        token.setBlacklisted(user, true);

        vm.expectRevert("Blacklisted");
        vm.prank(user);
        token.approve(recipient, 500);

        // Test blacklist removal
        vm.prank(owner);
        token.setBlacklisted(user, false);

        vm.prank(user);
        assertTrue(token.transfer(recipient, 500));
    }
}
