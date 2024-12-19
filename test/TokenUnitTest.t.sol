// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "../src/governance/Token.sol";
import "../src/governance/TokenStorage.sol";
import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import "../src/governance/TokenTimelock.sol";
import "./mocks/MockStaking.sol";
import "../src/interfaces/ITokenEventsAndErrors.sol";
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
            owner, 
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
        vm.warp(block.timestamp + 1 days);
        vm.prank(owner);

        uint256 expectedAmount = token.getNextEmissionAmount();
        assertEq(expectedAmount, 7_200 * 10 ** 18); // First period daily emission

        token.emitNewTokens(owner);
        assertEq(token.totalSupply(), token.INITIAL_SUPPLY() + expectedAmount);
    }
    /*//////////////////////////////////////////////////////////////
                        EMISSION TESTS
    //////////////////////////////////////////////////////////////*/
    function testEmissionHalving() public {
        uint256 startTime = block.timestamp;

        // Test first period (0-4 years)
        vm.warp(startTime + 1 days);
        vm.prank(owner);
        uint256 firstPeriodEmission = token.getNextEmissionAmount();
        assertEq(firstPeriodEmission, 7_200 * 10 ** 18);

        // Test second period (4-8 years)
        vm.warp(startTime + 4 * 365 days + 1 days);
        vm.prank(owner);
        uint256 secondPeriodEmission = token.getNextEmissionAmount();
        assertEq(secondPeriodEmission, 3_600 * 10 ** 18);

        // Test third period (8-12 years)
        vm.warp(startTime + 8 * 365 days + 1 days);
        vm.prank(owner);
        uint256 thirdPeriodEmission = token.getNextEmissionAmount();
        assertEq(thirdPeriodEmission, 1_800 * 10 ** 18);

        // Test fourth period (12-16 years)
        vm.warp(startTime + 12 * 365 days + 1 days);
        vm.prank(owner);
        uint256 fourthPeriodEmission = token.getNextEmissionAmount();
        assertEq(fourthPeriodEmission, 900 * 10 ** 18);

        // Test fifth period (16-20 years)
        vm.warp(startTime + 16 * 365 days + 1 days);
        vm.prank(owner);
        uint256 fifthPeriodEmission = token.getNextEmissionAmount();
        assertEq(fifthPeriodEmission, 450 * 10 ** 18);
    }
    
    /**
     * @dev Tests the 24 hour mint limit functionality of the token contract.
     * 
     * This function tests that the token contract enforces a 24 hour mint limit, 
     * preventing the owner from minting new tokens more frequently than once every 24 hours.
     */
    function test24HourMintLimit() public {
        // Take a snapshot of the initial state
        uint256 snapshot = vm.snapshot();

        // Reset the blockchain state and warp to a reasonable starting time
        vm.warp(1 days);

        // Deploy contracts again to reset the lastEmissionTime
        setUp();

        // Warp forward one more day before first emission
        vm.warp(block.timestamp + 1 days);

        // Test initial mint
        vm.prank(owner);
        token.emitNewTokens(owner);

        // Try after 23 hours (should fail)
        vm.warp(block.timestamp + 23 hours);
        vm.prank(owner);
        vm.expectRevert("Wait 24 hours between emissions");
        token.emitNewTokens(owner);

        // Try after 24 hours + 1 second (should succeed)
        vm.warp(block.timestamp + 24 hours + 1);
        vm.prank(owner);
        token.emitNewTokens(owner);

        // Restore the initial state
        vm.revertTo(snapshot);
    }

    function testDailyMintLimit() public {
        // assuming the Daily emission is set to 30 days accumulation 
        // i.,e the maximumamount of tokens in first period is 30 * 7200 * 10 ** 18
        // mint 1000 tokens every day for 10 days
       // Take a snapshot of the initial state
        uint256 snapshot = vm.snapshot();

        // Reset the blockchain state and warp to a reasonable starting time
        vm.warp(1 days);

        // Deploy contracts again to reset the lastEmissionTime
        setUp();

        // Warp forward one more day before first emission
        vm.warp(block.timestamp + 1 days);

        // Test initial mint
        vm.prank(owner);
        token.emitNewTokens(owner);

        // Try after 30 days 
        vm.warp(block.timestamp + 31 days); // (should fail)
        vm.prank(owner);
        vm.expectRevert("Daily mint limit");
        token.emitNewTokens(owner);

        // Restore the initial state
        vm.revertTo(snapshot);
    }
   
    /**
     * @dev Tests the Maximum Supply Cap Enforcement for the token contract.
     * 
     * This function tests that the token contract enforces a maximum supply cap, 
     * of 21,000,000,000 tokens over a 20 year period.
     */
    function testMaxSupplyCapEnforcement() public {
        uint256 startTime = block.timestamp;
        uint256 totalMinted = 0;
        emit log_named_uint("Total supply:", token.TOTAL_SUPPLY());
        emit log_named_uint("Initial lock:", token.totalSupply());
        // Try to mint beyond total supply
        for (uint256 i = 1; i < 7301; i++) {
            // 20 years in days
            vm.warp(startTime + (i * 1 days));
            vm.prank(owner);

            uint256 beforeMint = token.totalSupply();
            token.emitNewTokens(owner);
            uint256 minted = token.totalSupply() - beforeMint;
            totalMinted += minted;
            //emit log_named_uint("Daily emission", minted);
            assertLe(token.totalSupply(), token.TOTAL_SUPPLY());
        }
        emit log_named_uint("Total minted", totalMinted);
        // mint a day after 20 years . expect revert 
        vm.warp(startTime + (7300 * 1 days) + 1 days);
        vm.prank(owner);
        vm.expectRevert("Emission period ended");
        token.emitNewTokens(owner);
    }

    /*//////////////////////////////////////////////////////////////
                        ACCUMULATED EMISSION TESTS
    //////////////////////////////////////////////////////////////*/
    function testAccumulatedEmissions() public {
        // First, let's set up the initial state
        uint256 startTime = block.timestamp;

        // Warp to 5 days in the future
        vm.warp(startTime + 5 days);
        vm.prank(owner);

        // Get initial supply
        uint256 initialSupply = token.totalSupply();

        // Emit tokens
        token.emitNewTokens(owner);

        // Verify the results
        assertEq(
            token.totalSupply() - initialSupply,
            7_200 * 10 ** 18 * 5,
            "Should mint 5 days worth of tokens"
        );
    }

    function testAccumulatedEmissionsWithHalving() public {
        // Get initial timestamp
        uint256 startTime = block.timestamp;

        // Move to just before halving (4 years - 2 days), ensuring 30-day limit applies
        uint256 preHalvingTime = startTime + (4 * 365 days - 2 days);

        // Simulate regular emissions leading up to the halving point
        uint256 currentTime = startTime;
        uint256 interval = 30 days; // Emit every 30 days
        while (currentTime < preHalvingTime - interval) {
            currentTime += interval;
            vm.warp(currentTime);
            vm.prank(owner);
            token.emitNewTokens(owner);
        }

        vm.warp(preHalvingTime - 15 days); // Move to 15 days before the halving point
        vm.prank(owner);

        // First emission before halving
        token.emitNewTokens(owner); // Emits tokens for the last 15 days before halving

        // Get supply before second emission
        uint256 beforeSecondEmission = token.totalSupply();

        // Move to 30 days after halving
        uint256 postHalvingTime = block.timestamp + 30 days;
        vm.warp(postHalvingTime);
        vm.prank(owner);

        // Second emission after halving
        token.emitNewTokens(owner);

        // Verify results
        uint256 halvedDailyEmission = 3_600 * 10 ** 18; // Halved daily emission
        uint256 expectedEmission = halvedDailyEmission * 30; // 30 days of halved emission

        assertEq(
            token.totalSupply() - beforeSecondEmission,
            expectedEmission,
            "Should mint correct amount after halving"
        );
    }

    function testPendingEmissions() public {
        // Advance time by 3 days
        vm.warp(block.timestamp + 3 days);

        // Check pending emissions
        (
            uint256 pendingAmount,
            uint256 daysAccumulated,
            uint256 nextDailyEmission
        ) = token.getPendingEmissions();

        assertEq(daysAccumulated, 3, "Should show 3 days accumulated");
        assertEq(
            pendingAmount,
            7_200 * 10 ** 18 * 3,
            "Should have 3 days of emissions pending"
        );
        assertEq(
            nextDailyEmission,
            7_200 * 10 ** 18,
            "Should show correct daily emission"
        );
    }

    function testDetailedEmissionStats() public {
        vm.warp(block.timestamp + 5 days);

        (
            uint256 currentSupply,
            uint256 pendingEmissions,
            uint256 daysAccumulated,
            uint256 nextEmission,
            uint256 remainingTime
        ) = token.getDetailedEmissionStats();

        assertEq(
            currentSupply,
            token.INITIAL_SUPPLY(),
            "Initial supply should be locked supply"
        );
        assertEq(
            pendingEmissions,
            7_200 * 10 ** 18 * 5,
            "Should have 5 days of pending emissions"
        );
        assertEq(daysAccumulated, 5, "Should show 5 days accumulated");
        assertEq(
            nextEmission,
            7_200 * 10 ** 18,
            "Should show correct daily emission"
        );
        assertLt(
            remainingTime,
            token.EMISSION_PERIOD(),
            "Should show reduced remaining time"
        );
    }

   function testMaxSupplyWithAccumulation() public {
    // Get the initial supply and calculate the remaining supply
    uint256 startSupply = token.totalSupply();
   
    uint256 remainingSupply = token.TOTAL_SUPPLY() - startSupply;
   

    // Calculate the number of days required to reach the max supply
    uint256 dailyEmission = 7_200 * 10 ** 18; // Initial daily emission
    uint256 daysToMax = remainingSupply / dailyEmission;
   

    // Simulate emissions over the calculated number of days
    uint256 currentTime = block.timestamp;
    
    while (daysToMax > 0) {
        uint256 daysToEmit = daysToMax > 30 ? 30 : daysToMax;
        currentTime += daysToEmit * 1 days;
        vm.warp(currentTime);
        vm.prank(owner);
        token.emitNewTokens(owner);
        daysToMax -= daysToEmit;
    }

    // wrap the vm to let 24 hours pass
    vm.warp(currentTime + 24 hours);
    // Final emission to reach or approach max supply
    vm.prank(owner);
    token.emitNewTokens(owner);

    // Assert that the total supply does not exceed the maximum supply
    assertLe(
        token.totalSupply(),
        token.TOTAL_SUPPLY(),
        "Should not exceed total supply"
    );
}

    function testEmissionPauseWithAccumulation() public {
        // Test pausing emissions with accumulated days
        vm.warp(block.timestamp + 3 days);

        // Pause emissions
        vm.prank(owner);
        token.setEmissionsPaused(true);
        vm.prank(owner);
        vm.expectRevert(ITokenInterface.EmissionsPausedError.selector);
        token.emitNewTokens(owner);

        // Unpause and verify accumulated emissions
        vm.prank(owner);
        token.setEmissionsPaused(false);

        vm.prank(owner);
        (uint256 mintedAmount, uint256 daysAccumulated) = token.emitNewTokens(
            owner
        );

        assertEq(daysAccumulated, 3, "Should accumulate days during pause");
        assertEq(
            mintedAmount,
            7_200 * 10 ** 18 * 3,
            "Should mint accumulated amount after unpause"
        );
    }

    // function testFuzz_AccumulatedEmissions(uint256 daysToWait) public {
    //     daysToWait = bound(daysToWait, 1, 365); // Bound to reasonable range

    //     vm.warp(block.timestamp + daysToWait * 1 days);
    //     vm.prank(owner);

    //     (uint256 mintedAmount, uint256 daysAccumulated) = token.emitNewTokens(owner);

    //     assertEq(daysAccumulated, daysToWait, "Should accumulate correct days");
    //     assertEq(
    //         mintedAmount,
    //         7_200 * 10**18 * daysToWait,
    //         "Should mint correct accumulated amount"
    //     );
    // }

    function testEmissionConsistency() public {
        // Test consistency of emissions over multiple accumulation periods
        uint256 totalEmitted = 0;
        uint256[] memory waitPeriods = new uint256[](5);
        waitPeriods[0] = 3; // 3 days
        waitPeriods[1] = 5; // 5 days
        waitPeriods[2] = 2; // 2 days
        waitPeriods[3] = 4; // 4 days
        waitPeriods[4] = 1; // 1 day

        for (uint256 i = 0; i < waitPeriods.length; i++) {
            vm.warp(block.timestamp + waitPeriods[i] * 1 days);
            vm.prank(owner);
            (uint256 mintedAmount, ) = token.emitNewTokens(owner);
            totalEmitted += mintedAmount;

            assertEq(
                mintedAmount,
                7_200 * 10 ** 18 * waitPeriods[i],
                "Emission amount mismatch"
            );
        }

        assertEq(
            totalEmitted,
            7_200 * 10 ** 18 * 15,
            "Total emitted amount mismatch"
        );
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


    function testHalvingBoundaries() public {
        uint256 startTime = block.timestamp;

        // Test just before halving
        vm.warp(startTime + (4 * 365 days - 1 days));
        vm.prank(owner);
        uint256 beforeHalving = token.getNextEmissionAmount();

        // Test right after halving
        vm.warp(startTime + (4 * 365 days + 1 days));
        vm.prank(owner);
        uint256 afterHalving = token.getNextEmissionAmount();

        assertEq(afterHalving * 2, beforeHalving, "Halving ratio incorrect");
    }

    function testDailyEmissionConsistency() public {
        uint256 startTime = block.timestamp;

        // Test emissions for 30 consecutive days in each period
        uint256[] memory periodStarts = new uint256[](5);
        periodStarts[0] = 0; // First period
        periodStarts[1] = 4 * 365; // Second period
        periodStarts[2] = 8 * 365; // Third period
        periodStarts[3] = 12 * 365; // Fourth period
        periodStarts[4] = 16 * 365; // Fifth period

        uint256[] memory expectedEmissions = new uint256[](5);
        expectedEmissions[0] = 7_200 * 10 ** 18;
        expectedEmissions[1] = 3_600 * 10 ** 18;
        expectedEmissions[2] = 1_800 * 10 ** 18;
        expectedEmissions[3] = 900 * 10 ** 18;
        expectedEmissions[4] = 450 * 10 ** 18;

        for (uint256 i = 0; i < periodStarts.length; i++) {
            for (uint256 day = 0; day < 30; day++) {
                vm.warp(startTime + (periodStarts[i] + day) * 1 days);
                vm.prank(owner);
                uint256 emission = token.getNextEmissionAmount();
                assertEq(
                    emission,
                    expectedEmissions[i],
                    string.concat(
                        "Emission incorrect in period ",
                        vm.toString(i)
                    )
                );
            }
        }
    }

    function testEmissionsPausing() public {
        // Test pausing emissions
        vm.prank(owner);
        token.setEmissionsPaused(true);

        vm.warp(block.timestamp + 1 days);
        vm.prank(owner);
        vm.expectRevert(ITokenInterface.EmissionsPausedError.selector);
        token.emitNewTokens(owner);

        // Test unpausing
        vm.prank(owner);
        token.setEmissionsPaused(false);

        vm.prank(owner);
        token.emitNewTokens(owner);
        assertGt(token.totalSupply(), token.INITIAL_SUPPLY());
    }

    function testReentrancyProtection() public {
        // Deploy malicious receiver contract
        MaliciousReceiver malicious = new MaliciousReceiver(address(token));

        // Warp time to allow emission
        vm.warp(block.timestamp + 1 days);

        // First emission to malicious contract
        vm.prank(owner);
        vm.expectRevert();
        token.emitNewTokens(address(malicious));
    }

    
    // TODO: fix this test later
    function testInvariantMaintenance() public {
        uint256 startTime = block.timestamp;
        uint256 totalEmitted = 0;
        uint256 emissionCount = 0;

        // Test emissions while maintaining invariants
        for (uint256 day = 1; day <= 7300; day++) { // 20 years
            vm.warp(startTime + (day * 1 days));
            vm.prank(owner);

            //uint256 beforeMint = token.totalSupply();
            (uint256 emittedTotal, uint256 daysToEmit) = token.emitNewTokens(owner);
            //uint256 emitted = token.totalSupply() - beforeMint;
            emit log_named_uint("Day", daysToEmit);
            emit log_named_uint("Emitted", emittedTotal);
            totalEmitted += emittedTotal;
            emissionCount++;

            // Verify invariants
            assertLe(token.totalSupply(), token.TOTAL_SUPPLY(), "Total supply exceeded");
            assertGe(token.totalSupply(), token.INITIAL_SUPPLY(), "Supply below locked amount");
            // assertEq(
            //     emittedTotal,
            //     token.getNextEmissionAmount(),
            //     "Emission amount mismatch"
            // );

            // Verify halving periods
            uint256 currentYear = day / 365;
            uint256 expectedEmission = 7_200 * 10**18 >> (currentYear / 4);
            if (currentYear < 20) {
                assertEq(
                    token.getNextEmissionAmount(),
                    expectedEmission,
                    "Incorrect emission rate for year"
                );
            }
        }
    }

    function testFailureModes() public {
        // Test various failure modes
        vm.prank(owner);

        // Try to emit with zero address
        vm.expectRevert("Invalid distributor address");
        token.emitNewTokens(address(0));

        // Try to emit twice in same day
        token.emitNewTokens(owner);
        vm.expectRevert("Wait 24 hours between emissions");
        token.emitNewTokens(owner);

        // Try to emit after end period
        vm.warp(block.timestamp + 21 * 365 days);
        vm.expectRevert("Emission period ended");
        token.emitNewTokens(owner);

    }

    function testGasOptimization() public {
        uint256 gasStart;
        uint256 gasUsed;

        // Test emission gas usage
        gasStart = gasleft();
        vm.prank(owner);
        vm.warp(block.timestamp + 1 days);
        token.emitNewTokens(owner);
        gasUsed = gasStart - gasleft();
        emit log_named_uint("Gas used for emission", gasUsed);

        // Test 30 days emission gas usage
        vm.warp(block.timestamp + 30 days);
        gasStart = gasleft();
        vm.prank(owner);
        token.emitNewTokens(owner);
        gasUsed = gasStart - gasleft();
        emit log_named_uint("Gas used for 30 days emission", gasUsed);
    }

    function testIntegrationWithStaking() public {
        // Deploy mock staking contract
        MockStaking staking = new MockStaking(address(token));

        // Test emission to staking contract
        vm.warp(block.timestamp + 1 days);
        vm.prank(owner);
        token.emitNewTokens(address(staking));

        // Verify staking contract received tokens
        assertEq(token.balanceOf(address(staking)), 7_200 * 10 ** 18);
    }

    function testCompleteEmissionScenario() public {
         // Add guardians
        address guardian1 = address(0x1);
        address guardian2 = address(0x2);
        _addGuardian(guardian1);
        _addGuardian(guardian2);

        // Test complete emission cycle with governance actions
        vm.startPrank(owner);
        // Emit tokens for a year
        for (uint256 i = 0; i < 365; i++) {
            vm.warp(block.timestamp + 1 days);
            token.emitNewTokens(owner);

            // Every 90 days, simulate governance action
            if (i % 90 == 0) {
                token.setEmissionsPaused(true);
                token.setEmissionsPaused(false);
            }
        }

        vm.stopPrank();
    }

    function testCompleteStakingIntegration() public {
        // Deploy staking contract
        MockStaking staking = new MockStaking(address(token));
        
        address user1 = address(0x15);
        address user2 = address(0x25);
        
        // Try smaller amount first
        vm.startPrank(owner);
        token.transfer(user1, 10_000 * 10**18);  
        token.transfer(user2, 10_000 * 10**18);
        vm.stopPrank();

        emit log_named_uint("User1 balance after transfer:", token.balanceOf(user1));
        emit log_named_uint("User2 balance after transfer:", token.balanceOf(user2));

        
        // test staking 
        vm.startPrank(user1);   
        token.approve(address(staking), type(uint256).max);
        staking.stake(10_000 * 10**18);
        vm.stopPrank();

        assertEq(staking.stakedBalance(user1), 10_000 * 10**18);
        
        // Advance time and test rewards
        vm.warp(block.timestamp + 10 days);
        uint256 rewards = staking.calculateRewards(user1);
        assertGt(rewards, 0);

        // Test withdrawal
        vm.prank(user1);
        staking.withdraw(10_000 * 10**18);
        assertEq(staking.stakedBalance(user1), 0);  
    }

    function testStakingWithEmissions() public {
        MockStaking staking = new MockStaking(address(token));

        // Emit tokens to staking contract
        vm.warp(block.timestamp + 1 days);
        vm.prank(owner);
        token.emitNewTokens(address(staking));

        // Verify staking contract received tokens
        uint256 expectedEmission = 7_200 * 10 ** 18;
        assertEq(token.balanceOf(address(staking)), expectedEmission);

        // Test staking of emitted tokens
        vm.prank(owner);
        token.approve(address(staking), expectedEmission);
        vm.prank(owner);
        staking.stake(expectedEmission);

        assertEq(staking.totalStaked(), expectedEmission);
    }

    function testStakingIntegrationScenarios() public {
        MockStaking staking = new MockStaking(address(token));
        address user1 = address(0x1);
        address user2 = address(0x2);

        // Setup initial balances
        vm.startPrank(owner);
        token.transfer(user1, 10_000 * 10 ** 18);
        token.transfer(user2, 10_000 * 10 ** 18);
        vm.stopPrank();

        // Scenario 1: Multiple users staking
        vm.startPrank(user1);
        token.approve(address(staking), type(uint256).max);
        staking.stake(5_000 * 10 ** 18);
        vm.stopPrank();

        vm.startPrank(user2);
        token.approve(address(staking), type(uint256).max);
        staking.stake(3_000 * 10 ** 18);
        vm.stopPrank();

        assertEq(staking.totalStaked(), 8_000 * 10 ** 18);

        // Scenario 2: Emissions with staking
        for (uint256 i = 0; i < 5; i++) {
            // Emit tokens daily
            vm.warp(block.timestamp + 1 days);
            vm.prank(owner);
            token.emitNewTokens(address(staking));

            // Calculate expected rewards
            (, , uint256 user1Rewards) = staking.getStakeInfo(user1);
            (, , uint256 user2Rewards) = staking.getStakeInfo(user2);

            emit log_named_uint("Day", i + 1);
            emit log_named_uint("User1 Rewards", user1Rewards);
            emit log_named_uint("User2 Rewards", user2Rewards);
        }

        // Scenario 3: Reward claiming 
        vm.warp(block.timestamp + 30 days - 1 days);
        vm.prank(owner);
        token.emitNewTokens(address(staking));

        // Claim rewards across halving period
        vm.prank(user1);
        staking.claimRewards();
        vm.prank(user2);
        staking.claimRewards();

        // Scenario 4: Emergency situations
        vm.prank(owner);
        token.setEmissionsPaused(true);

        vm.warp(block.timestamp + 1 days);
        vm.prank(owner);
        vm.expectRevert(ITokenInterface.EmissionsPausedError.selector);
        token.emitNewTokens(address(staking));

        // Test emergency withdrawal
        uint256 user1BalanceBefore = token.balanceOf(user1);
        vm.prank(user1);
        staking.emergencyWithdraw();
        uint256 user1BalanceAfter = token.balanceOf(user1);
        assertGt(user1BalanceAfter, user1BalanceBefore);

        // Scenario 5: Staking limits and edge cases
        vm.startPrank(user2);
        vm.expectRevert();
        staking.stake(0);

        staking.withdraw(1000 * 10 ** 18);
        vm.expectRevert();
        staking.withdraw(type(uint256).max);
        vm.stopPrank();
    }

    function testStakingWithGovernanceActions() public {
        MockStaking staking = new MockStaking(address(token));
        address guardian = address(0x1);
        _addGuardian(guardian);
       // get the guardian list
       address[] memory guardianList = token.getGuardianList();
       assertEq(guardianList.length, 1);
       assertEq(guardianList[0], guardian);

        // Scenario 1: Emergency pause during staking
        vm.startPrank(guardian);
        token.proposeEmergencyPause();

        bytes32 actionId = keccak256(
            abi.encodePacked("PAUSE", block.timestamp)
        );
        token.executeEmergencyPause(actionId);
        vm.stopPrank();

        // Verify staking still works during pause
        vm.startPrank(owner);
        token.transfer(address(this), 1000 * 10 ** 18);
        token.approve(address(staking), 1000 * 10 ** 18);
        vm.stopPrank();
        // vm.startPrank(address(this));
        // staking.stake(1000 * 10 ** 18);
        // vm.stopPrank();

        // // Scenario 2: Blacklist interaction
        // address maliciousUser = address(0x9);
        // vm.prank(owner);
        // token.transfer(maliciousUser, 1000 * 10 ** 18);

        // vm.startPrank(maliciousUser);
        // token.approve(address(staking), 1000 * 10 ** 18);
        // staking.stake(1000 * 10 ** 18);
        // vm.stopPrank();

        // // Blacklist user
        // vm.prank(owner);
        // token.setBlacklisted(maliciousUser, true);

        // // Verify blacklisted user can withdraw but not stake
        // vm.startPrank(maliciousUser);
        // staking.emergencyWithdraw();
        // token.approve(address(staking), 1000 * 10 ** 18);
        // vm.expectRevert("Blacklisted");
        // staking.stake(1000 * 10 ** 18);
        // vm.stopPrank();
    }
}

// Helper contract for testing reentrancy
contract MaliciousReceiver {
    BitDSMToken private immutable token;
    bool private attacked;

    constructor(address _token) {
        token = BitDSMToken(_token);
        attacked = false;
    }

    // This function will be called when tokens are transferred to this contract
    function _beforeTokenTransfer(address, address, uint256) internal {
        if (!attacked) {
            attacked = true;
            // Try to trigger reentrancy by calling emitNewTokens again
            token.emitNewTokens(address(this));
        }
    }

    // Fallback function to handle direct transfers
    receive() external payable {
        if (!attacked) {
            attacked = true;
            token.emitNewTokens(address(this));
        }
    }
}
