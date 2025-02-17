// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import "../src/core/BitcoinPodManager.sol";
import "../src/core/BitcoinPod.sol";
import "../src/interfaces/IBitDSMServiceManager.sol";
import {BitDSMRegistry} from "../src/core/BitDSMRegistry.sol";
import {IDelegationManager} from "@eigenlayer/src/contracts/interfaces/IDelegationManager.sol";
import {ISignatureUtils} from "@eigenlayer/src/contracts/interfaces/ISignatureUtils.sol";
import {IStrategy} from "@eigenlayer/src/contracts/interfaces/IStrategy.sol";
import {Quorum, StrategyParams} from "@eigenlayer-middleware/src/interfaces/IECDSAStakeRegistryEventsAndErrors.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "../src/libraries/BitcoinUtils.sol";

contract MockServiceManager {
    event BitcoinWithdrawalTransactionSigned(address indexed pod, address indexed operator, uint256 amount);

    BitcoinPodManager public podManager;

    constructor() {}

    function initialize(address podManager_) public {
        podManager = BitcoinPodManager(podManager_);
    }
    // solhint-disable-next-line

    function deregisterOperatorFromAVS(address) external {}

    function registerOperatorToAVS(
        address,
        ISignatureUtils.SignatureWithSaltAndExpiry memory // solhint-disable-next-line
    ) external {}

    function confirmDeposit(address pod, bytes32 transactionId, uint256 amount) external {
        podManager.confirmBitcoinDeposit(pod, transactionId, amount);
    }

    function withdrawBitcoinPSBT(address pod, uint256 amount, bytes calldata psbtTransaction) external {
        podManager.setSignedBitcoinWithdrawTransactionPod(pod, psbtTransaction);
        emit BitcoinWithdrawalTransactionSigned(pod, msg.sender, amount);
    }

    function withdrawBitcoinCompleteTx(address pod, uint256 amount, bytes calldata completeTx) external {
        podManager.setSignedBitcoinWithdrawTransactionPod(pod, completeTx);
        emit BitcoinWithdrawalTransactionSigned(pod, msg.sender, amount);
    }

    function confirmWithdrawal(address pod) external {
        podManager.withdrawBitcoinAsTokens(pod);
    }
    // function verifyBTCAddress(string calldata btcAddress, bytes calldata script, bytes calldata operatorBtcPubKey) external pure returns (bool) {
    //      // extract publickeys from the script
    //     (bytes memory operatorKey, bytes memory userKey) = BitcoinUtils.extractPublicKeys(script);
    //     // check if userKey is 33 bytes
    //     require(userKey.length == 33, "Invalid user key length. It should be 33 bytes");
    //     // verify correct operator BTC key is used in script
    //     require(_areEqual(operatorKey, operatorBtcPubKey), "Invalid operator BTC key");
    //     // get scriptPubKey
    //     bytes32 scriptPubKey = BitcoinUtils.getScriptPubKey(script);
    //     // convert scriptPubKey to bytes
    //     bytes memory result = new bytes(32);
    //     assembly {
    //         mstore(add(result, 32), scriptPubKey)
    //     }
    //     // convert scriptPubKey to bech32address
    //     string memory bech32Address = BitcoinUtils.convertScriptPubKeyToBech32Address(result);
    //     // verify the address is correct
    //     return _areEqual(bytes(bech32Address), bytes(btcAddress));
    // }

    function _areEqual(bytes memory a, bytes memory b) internal pure returns (bool) {
        return keccak256(a) == keccak256(b);
    }
}

contract MockDelegationManager {
    function getOperatorShares(address, address[] memory strategies) external pure returns (uint256[] memory) {
        uint256[] memory response = new uint256[](strategies.length);
        for (uint256 i; i < strategies.length; i++) {
            response[i] = 1000;
        }
        return response; // Return a dummy value for simplicity
    }
}

contract MockAppRegistry {
    mapping(address => AppRegistrationStatus) public appStatus;
    address public owner;

    enum AppRegistrationStatus {
        UNREGISTERED,
        REGISTERED
    }

    event AppRegistrationStatusUpdated(address indexed app, AppRegistrationStatus status);
    event AppMetadataURIUpdated(address indexed app, string metadataURI);

    function initialize(address initialOwner) public {
        owner = initialOwner;
    }

    function registerApp(address app) public {
        require(appStatus[app] == AppRegistrationStatus.UNREGISTERED, "AppRegistry: app already registered");
        appStatus[app] = AppRegistrationStatus.REGISTERED;
        emit AppRegistrationStatusUpdated(app, AppRegistrationStatus.REGISTERED);
    }

    function deregisterApp(address app) public {
        require(msg.sender == owner, "AppRegistry: caller is not owner");
        require(appStatus[app] == AppRegistrationStatus.REGISTERED, "AppRegistry: app not registered");
        appStatus[app] = AppRegistrationStatus.UNREGISTERED;
        emit AppRegistrationStatusUpdated(app, AppRegistrationStatus.UNREGISTERED);
    }

    function isAppRegistered(address app) public view returns (bool) {
        return appStatus[app] == AppRegistrationStatus.REGISTERED;
    }
}

contract BitcoinPodManagerTest is Test {
    BitDSMRegistry public bitDSMRegistry;
    BitcoinPodManager public podManager;
    MockAppRegistry public appRegistry;
    address public testOwner;
    MockDelegationManager public delegationManager;
    MockServiceManager public serviceManager;
    address public operator;
    address public user;
    bytes public operatorBtcPubKey;
    string public userBtcAddress;
    uint256 public totalPods;
    bytes public lockScript;

    function _deployProxiedServiceManager() internal returns (MockServiceManager) {
        // Deploy ProxyAdmin if not already deployed
        ProxyAdmin proxyAdmin = new ProxyAdmin();

        // Deploy implementation
        MockServiceManager impl = new MockServiceManager();

        // Deploy and initialize proxy in one step
        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy(
            address(impl),
            address(proxyAdmin),
            abi.encodeWithSelector(MockServiceManager.initialize.selector, address(podManager))
        );
        return MockServiceManager(address(proxy));
    }

    function setUp() public {
        delegationManager = new MockDelegationManager();
        bitDSMRegistry = new BitDSMRegistry(IDelegationManager(address(delegationManager)));
        appRegistry = new MockAppRegistry();
        testOwner = address(this);
        appRegistry.initialize(testOwner);
        podManager = new BitcoinPodManager();
        serviceManager = _deployProxiedServiceManager();
        podManager.initialize(address(appRegistry), address(bitDSMRegistry), address(serviceManager));
        //  serviceManager = new MockServiceManager(address(podManager));

        // initialize strategy
        IStrategy mockStrategy = IStrategy(address(0x1234));
        Quorum memory quorum = Quorum({strategies: new StrategyParams[](1)});
        quorum.strategies[0] = StrategyParams({strategy: mockStrategy, multiplier: 10_000});

        bitDSMRegistry.initialize(address(serviceManager), 100, quorum);
        operator = address(0x1);
        user = address(0x2);
        operatorBtcPubKey = hex"03cb23542f698ed1e617a623429b585d98fb91e44839949db4126b2a0d5a7320b0";
        userBtcAddress = "tb1qccmqzwmm95pkyg9zl09mqm6kv95tulydtrr6rswezhnfdtt5hg9qwd09jn";
        lockScript =
            hex"522103cb23542f698ed1e617a623429b585d98fb91e44839949db4126b2a0d5a7320b02103fa33caff610ac48ad20c4bd9fa8d7c5b9a5c56b6d6315343f16cb93e59fafd0252ae";
    }

    function testPodCreation() public {
        // First, register the operator
        ISignatureUtils.SignatureWithSaltAndExpiry memory operatorSignature;
        vm.prank(operator);
        bitDSMRegistry.registerOperatorWithSignature(operatorSignature, operator, operatorBtcPubKey);

        // Now, create a pod as the user
        vm.prank(user);
        podManager.createPod(operator, userBtcAddress, lockScript);

        address podAddress = podManager.getUserPod(user);
        assertTrue(podAddress != address(0), "Pod should be created");

        BitcoinPod pod = BitcoinPod(podAddress);
        assertEq(pod.owner(), user, "Pod owner should be the user");
        assertEq(pod.getOperator(), operator, "Pod operator should be set correctly");
        assertEq(bytes(pod.getBitcoinAddress()), bytes(userBtcAddress), "Bitcoin address should be set correctly");
        assertEq(pod.getOperatorBtcPubKey(), operatorBtcPubKey, "Operator BTC public key should be set correctly");
    }

    function testCannotCreatePodWithUnregisteredOperator() public {
        vm.prank(user);
        vm.expectRevert("Invalid operator");
        podManager.createPod(operator, userBtcAddress, lockScript);
    }

    function testCannotCreateMultiplePods() public {
        ISignatureUtils.SignatureWithSaltAndExpiry memory operatorSignature;
        // Register operator
        vm.prank(operator);
        bitDSMRegistry.registerOperatorWithSignature(operatorSignature, operator, operatorBtcPubKey);

        // Create first pod
        vm.prank(user);
        podManager.createPod(operator, userBtcAddress, lockScript);

        // Try to create second pod
        vm.prank(user);
        vm.expectRevert("User already has a pod");
        podManager.createPod(operator, userBtcAddress, lockScript);
    }

    function testUserCannotMintBurnOrDeposit() public {
        // Register operator and create pod
        ISignatureUtils.SignatureWithSaltAndExpiry memory operatorSignature;
        vm.prank(operator);
        bitDSMRegistry.registerOperatorWithSignature(operatorSignature, operator, operatorBtcPubKey);
        vm.prank(user);
        podManager.createPod(operator, userBtcAddress, lockScript);

        address podAddress = podManager.getUserPod(user);
        BitcoinPod pod = BitcoinPod(podAddress);

        vm.startPrank(user);

        // Test mint
        vm.expectRevert("Only manager can perform this action");
        pod.mint(100);

        // Test burn
        vm.expectRevert("Only manager can perform this action");
        pod.burn(50);

        // Remove the deposit test as it's not part of the BitcoinPod contract

        vm.stopPrank();
    }

    function testArbitraryAddressCannotMintOrBurn() public {
        // Register operator and create pod
        ISignatureUtils.SignatureWithSaltAndExpiry memory operatorSignature;
        vm.prank(operator);
        bitDSMRegistry.registerOperatorWithSignature(operatorSignature, operator, operatorBtcPubKey);
        vm.prank(user);
        podManager.createPod(operator, userBtcAddress, lockScript);

        address podAddress = podManager.getUserPod(user);
        BitcoinPod pod = BitcoinPod(podAddress);

        address arbitraryAddress = address(0x1234);
        vm.startPrank(arbitraryAddress);

        // Test mint
        vm.expectRevert("Only manager can perform this action");
        pod.mint(100);

        // Test burn
        vm.expectRevert("Only manager can perform this action");
        pod.burn(50);

        vm.stopPrank();
    }

    function testPodCreationAndOwnership() public {
        // Register operator
        ISignatureUtils.SignatureWithSaltAndExpiry memory operatorSignature;

        vm.prank(operator);
        bitDSMRegistry.registerOperatorWithSignature(operatorSignature, operator, operatorBtcPubKey);

        // Create pod as user
        vm.prank(user);
        podManager.createPod(operator, userBtcAddress, lockScript);

        // Get the pod address
        address podAddress = podManager.getUserPod(user);

        // Check if the pod address is a contract
        assertTrue(podAddress.code.length > 0, "Pod address should be a contract");
    }

    function testDepositFlow() public {
        // Setup
        ISignatureUtils.SignatureWithSaltAndExpiry memory operatorSignature;
        vm.prank(operator);
        bitDSMRegistry.registerOperatorWithSignature(operatorSignature, operator, operatorBtcPubKey);

        vm.prank(user);
        address podAddress = podManager.createPod(operator, userBtcAddress, lockScript);

        bytes32 txId = bytes32("test_tx_id");
        uint256 depositAmount = 1;

        // User initiates deposit request
        vm.prank(user);
        podManager.verifyBitcoinDepositRequest(podAddress, txId, depositAmount);

        // Verify deposit request state
        BitcoinPodManager.BitcoinDepositRequest memory request = podManager.getBitcoinDepositRequest(podAddress);
        assertEq(request.transactionId, txId);
        assertEq(request.amount, depositAmount);
        assertTrue(request.isPending);

        // Service manager confirms deposit
        vm.prank(address(serviceManager));
        podManager.confirmBitcoinDeposit(podAddress, txId, depositAmount);

        // Verify deposit completion
        BitcoinPod pod = BitcoinPod(podAddress);
        assertEq(pod.getBitcoinBalance(), depositAmount);
        assertEq(podManager.getTotalTVL(), depositAmount);

        // Verify request is cleared
        request = podManager.getBitcoinDepositRequest(podAddress);
        assertEq(request.transactionId, bytes32(0));
        assertFalse(request.isPending);
    }

    function testCannotDepositWhilePreviousRequestPending() public {
        // Setup
        ISignatureUtils.SignatureWithSaltAndExpiry memory operatorSignature;
        vm.prank(operator);
        bitDSMRegistry.registerOperatorWithSignature(operatorSignature, operator, operatorBtcPubKey);

        vm.prank(user);
        address podAddress = podManager.createPod(operator, userBtcAddress, lockScript);

        // First deposit request
        vm.prank(user);
        podManager.verifyBitcoinDepositRequest(podAddress, bytes32("tx1"), 1);

        // Try second deposit request
        vm.prank(user);
        vm.expectRevert("Request already pending");
        podManager.verifyBitcoinDepositRequest(podAddress, bytes32("tx2"), 2);
    }

    function testWithdrawalPSBTFlow() public {
        // Setup pod with balance
        ISignatureUtils.SignatureWithSaltAndExpiry memory operatorSignature;
        vm.prank(operator);
        bitDSMRegistry.registerOperatorWithSignature(operatorSignature, operator, operatorBtcPubKey);

        vm.prank(user);
        address podAddress = podManager.createPod(operator, userBtcAddress, lockScript);
        // create deposit request
        vm.prank(user);
        podManager.verifyBitcoinDepositRequest(podAddress, bytes32("deposit_tx"), 2);
        // Add some balance first
        vm.prank(address(serviceManager));
        podManager.confirmBitcoinDeposit(podAddress, bytes32("deposit_tx"), 2);

        // Initiate withdrawal
        string memory withdrawAddress = "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa";
        vm.prank(user);
        podManager.withdrawBitcoinPSBTRequest(podAddress, withdrawAddress);

        // Verify withdrawal request state
        assertEq(podManager.getBitcoinWithdrawalAddress(podAddress), withdrawAddress);

        // Service manager processes withdrawal
        bytes memory signedPSBT = "signed_psbt_data";
        vm.prank(address(serviceManager));
        podManager.setSignedBitcoinWithdrawTransactionPod(podAddress, signedPSBT);

        // Complete withdrawal
        vm.prank(address(serviceManager));
        podManager.withdrawBitcoinAsTokens(podAddress);

        // Verify final state
        BitcoinPod pod = BitcoinPod(podAddress);
        assertEq(pod.getBitcoinBalance(), 0);
        assertEq(podManager.getTotalTVL(), 0);
        assertEq(podManager.getBitcoinWithdrawalAddress(podAddress), "");
    }

    function testAppDelegationFlow() public {
        // Setup
        ISignatureUtils.SignatureWithSaltAndExpiry memory operatorSignature;
        vm.prank(operator);
        bitDSMRegistry.registerOperatorWithSignature(operatorSignature, operator, operatorBtcPubKey);

        vm.prank(user);
        address podAddress = podManager.createPod(operator, userBtcAddress, lockScript);

        // create deposit request
        vm.prank(user);
        podManager.verifyBitcoinDepositRequest(podAddress, bytes32("deposit_tx"), 2);
        // confirm deposit
        vm.prank(address(serviceManager));
        podManager.confirmBitcoinDeposit(podAddress, bytes32("deposit_tx"), 2);

        // Register app
        address app = address(0x123);
        vm.prank(testOwner);
        appRegistry.registerApp(app);

        // Delegate pod
        vm.prank(user);
        podManager.delegatePod(podAddress, app);
        assertEq(podManager.getPodApp(podAddress), app);

        // Test app locking
        vm.prank(app);
        podManager.lockPod(podAddress);
        assertTrue(BitcoinPod(podAddress).isLocked());

        // Test app unlocking
        vm.prank(app);
        podManager.unlockPod(podAddress);
        assertFalse(BitcoinPod(podAddress).isLocked());

        // Undelegate pod
        vm.prank(user);
        podManager.undelegatePod(podAddress);
        assertEq(podManager.getPodApp(podAddress), address(0));
    }

    function testCannotWithdrawFromLockedPod() public {
        // Setup
        ISignatureUtils.SignatureWithSaltAndExpiry memory operatorSignature;
        vm.prank(operator);
        bitDSMRegistry.registerOperatorWithSignature(operatorSignature, operator, operatorBtcPubKey);

        vm.prank(user);
        address podAddress = podManager.createPod(operator, userBtcAddress, lockScript);

        // Register and delegate to app
        address app = address(0x123);
        vm.prank(testOwner);
        appRegistry.registerApp(app);

        vm.prank(user);
        podManager.delegatePod(podAddress, app);

        // Lock pod
        vm.prank(app);
        podManager.lockPod(podAddress);

        // Try withdrawal
        vm.prank(user);
        vm.expectRevert("Pod is locked");
        podManager.withdrawBitcoinPSBTRequest(podAddress, "withdraw_address");
    }

    function testCannotWithdrawFromDelegatedPod() public {
        // Setup
        ISignatureUtils.SignatureWithSaltAndExpiry memory operatorSignature;
        vm.prank(operator);
        bitDSMRegistry.registerOperatorWithSignature(operatorSignature, operator, operatorBtcPubKey);

        vm.prank(user);
        address podAddress = podManager.createPod(operator, userBtcAddress, lockScript);

        // Register and delegate to app
        address app = address(0x123);
        vm.prank(testOwner);
        appRegistry.registerApp(app);

        // Add console logs to verify state
        console.log("App registered:", appRegistry.isAppRegistered(app));

        vm.prank(user);
        podManager.delegatePod(podAddress, app);

        // Verify delegation
        console.log("Pod delegated to:", podManager.getPodApp(podAddress));
        console.log("Expected app:", app);

        // Try withdrawal with specific error message
        vm.prank(user);
        vm.expectRevert("Pod is delegated");
        podManager.withdrawBitcoinPSBTRequest(podAddress, "withdraw_address");
    }

    function testPauseUnpauseFlow() public {
        // Pause contract
        podManager.pause();

        // Try to create pod while paused
        ISignatureUtils.SignatureWithSaltAndExpiry memory operatorSignature;
        vm.prank(operator);
        bitDSMRegistry.registerOperatorWithSignature(operatorSignature, operator, operatorBtcPubKey);

        vm.prank(user);
        vm.expectRevert("Pausable: paused");
        podManager.createPod(operator, userBtcAddress, lockScript);

        // Unpause and verify operations work
        podManager.unpause();

        vm.prank(user);
        address podAddress = podManager.createPod(operator, userBtcAddress, lockScript);
        assertNotEq(podAddress, address(0));
    }

    function testCompleteWithdrawalFlow() public {
        // Setup pod with balance
        ISignatureUtils.SignatureWithSaltAndExpiry memory operatorSignature;
        vm.prank(operator);
        bitDSMRegistry.registerOperatorWithSignature(operatorSignature, operator, operatorBtcPubKey);

        vm.prank(user);
        address podAddress = podManager.createPod(operator, userBtcAddress, lockScript);
        // create deposit request
        vm.prank(user);
        podManager.verifyBitcoinDepositRequest(podAddress, bytes32("deposit_tx"), 2);
        // Add balance
        vm.prank(address(serviceManager));
        podManager.confirmBitcoinDeposit(podAddress, bytes32("deposit_tx"), 2);

        // Initiate complete withdrawal
        string memory withdrawAddress = "1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa";
        bytes memory preSignedTx = "pre_signed_tx_data";
        vm.prank(user);
        podManager.withdrawBitcoinCompleteTxRequest(podAddress, preSignedTx, withdrawAddress);

        // Service manager completes withdrawal
        bytes memory completeTx = "complete_tx_data";
        vm.startPrank(address(serviceManager));
        podManager.setSignedBitcoinWithdrawTransactionPod(podAddress, completeTx);
        podManager.withdrawBitcoinAsTokens(podAddress);
        vm.stopPrank();

        // Verify final state
        BitcoinPod pod = BitcoinPod(podAddress);
        assertEq(pod.getBitcoinBalance(), 0);
        assertEq(podManager.getTotalTVL(), 0);
        assertEq(podManager.getBitcoinWithdrawalAddress(podAddress), "");
    }

    function testVerifyBTCAddressGeneric() public {
        // Example P2WSH script with known public keys
        // This is a mock script representing a 2-of-2 multisig witness script
        bytes memory script =
            hex"522103cb23542f698ed1e617a623429b585d98fb91e44839949db4126b2a0d5a7320b02103fa33caff610ac48ad20c4bd9fa8d7c5b9a5c56b6d6315343f16cb93e59fafd0252ae";

        // The corresponding bech32 address for the above script (testnet)
        string memory expectedBtcAddress = "tb1qccmqzwmm95pkyg9zl09mqm6kv95tulydtrr6rswezhnfdtt5hg9qwd09jn";

        // Mock the operator's BTC public key in the registry
        // First public key from the script above

        bytes memory mockOperatorBtcPubKey = hex"03cb23542f698ed1e617a623429b585d98fb91e44839949db4126b2a0d5a7320b0";

        // Mock the registry to return our test operator's BTC public key
        // vm.mockCall(
        //     address(mockStakeRegistry),
        //     abi.encodeWithSignature("getOperatorBtcPublicKey(address)", operator),
        //     abi.encode(mockOperatorBtcPubKey)
        // );

        (bytes memory pubKey1, bytes memory pubKey2) = BitcoinUtils.extractPublicKeys(script);
        console.log("pubKey1 length", pubKey1.length);
        console.log("mockOperatorBtcPubKey length", mockOperatorBtcPubKey.length);
        assertEq(pubKey1.length, mockOperatorBtcPubKey.length, "Invalid public key Lenght");
        bool hashkey = keccak256(pubKey1) == keccak256(mockOperatorBtcPubKey);
        console.log("hashkey", hashkey);
        assertEq(hashkey, true, "Invalid public key Hash");
        console.logBytes(pubKey1);
        console.logBytes(pubKey2);

        // Call verifyBTCAddress as operator
        vm.prank(operator);
        //vm.expectEmit(true, true, false, true);
        //emit BTCAddressVerified(operator, expectedBtcAddress);
        BTCAddressTestContract btcAddressTestContract = new BTCAddressTestContract();
        bool isBtcAddress = btcAddressTestContract.verifyBTCAddress(expectedBtcAddress, script, mockOperatorBtcPubKey);
        assertEq(isBtcAddress, true, "Invalid BTC address");
        //testing extractpublickeys

        // test getScriptPubKey
        //bytes32  scriptPubKey = BitcoinUtils.getScriptPubKey(script);
        //assertEq(scriptPubKey, hex"0020ab38e9a92e1bdabd59bb4095f6e0a16f9e1e95c71b47465e86f480a80c536813", "Invalid scriptPubKey");
        //console.logBytes32(scriptPubKey);
        // test convertScriptPubKeyToBech32Address
        //string memory bech32Address = BitcoinUtils.convertScriptPubKeyToBech32Address(scriptPubKey);
        //assertEq(bech32Address, expectedBtcAddress, "Invalid bech32 address");
        //assertEq(pubKey1, mockOperatorBtcPubKey, "Invalid public key 1");
        //require(pubKey2.length == 33, "Invalid public key 2 length");
    }

    function testVerifyBTCAddressInternal() public {
        // Example P2WSH script with known public keys
        // This is a mock script representing a 2-of-2 multisig witness script
        bytes memory script =
            hex"522103cb23542f698ed1e617a623429b585d98fb91e44839949db4126b2a0d5a7320b02103fa33caff610ac48ad20c4bd9fa8d7c5b9a5c56b6d6315343f16cb93e59fafd0252ae";

        // The corresponding bech32 address for the above script (testnet)
        string memory expectedBtcAddress = "tb1qccmqzwmm95pkyg9zl09mqm6kv95tulydtrr6rswezhnfdtt5hg9qwd09jn";

        // Mock the operator's BTC public key in the registry
        // First public key from the script above

        bytes memory mockOperatorBtcPubKey = hex"03cb23542f698ed1e617a623429b585d98fb91e44839949db4126b2a0d5a7320b0";

        // Call verifyBTCAddress as operator
        vm.prank(operator);
        BTCAddressTestContract btcAddressTestContract = new BTCAddressTestContract();
        bool isBtcAddress = btcAddressTestContract.verifyBTCAddress(expectedBtcAddress, script, mockOperatorBtcPubKey);
        assertEq(isBtcAddress, true, "Invalid BTC address");
    }

    function testFailVerifyBTCAddressInvalidOperator() public {
        bytes memory script =
            hex"522102c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee521021c1db6e604a4909a6e70f1994e37df6dfdcb19c8ee4c9648f37087e5f36388b352ae";
        string memory btcAddress = "tb1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3q0sl5k7";

        // Call with non-operator address should fail
        vm.prank(address(0xbad));
        BTCAddressTestContract btcAddressTestContract = new BTCAddressTestContract();
        btcAddressTestContract.verifyBTCAddress(btcAddress, script, operatorBtcPubKey);
    }

    function testFailVerifyBTCAddressInvalidScript() public {
        // Invalid script (wrong length)
        bytes memory invalidScript = hex"1234";
        string memory btcAddress = "tb1qrp33g0q5c5txsp9arysrx4k6zdkfs4nce4xj0gdcccefvpysxf3q0sl5k7";
        // deploy the mock contract
        BTCAddressTestContract btcAddressTestContract = new BTCAddressTestContract();
        vm.prank(operator);
        btcAddressTestContract.verifyBTCAddress(btcAddress, invalidScript, operatorBtcPubKey);
    }

    function testWithdrawalRequestCancellation() public {
        // Setup
        ISignatureUtils.SignatureWithSaltAndExpiry memory operatorSignature;
        vm.prank(operator);
        bitDSMRegistry.registerOperatorWithSignature(operatorSignature, operator, operatorBtcPubKey);

        vm.prank(user);
        address podAddress = podManager.createPod(operator, userBtcAddress, lockScript);

        // Add some balance first through deposit
        vm.prank(user);
        podManager.verifyBitcoinDepositRequest(podAddress, bytes32("deposit_tx"), 2);
        vm.prank(address(serviceManager));
        podManager.confirmBitcoinDeposit(podAddress, bytes32("deposit_tx"), 2);

        // Initiate withdrawal
        string memory withdrawAddress = "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx";
        vm.prank(user);
        podManager.withdrawBitcoinPSBTRequest(podAddress, withdrawAddress);

        // Verify withdrawal request state
        assertEq(podManager.getBitcoinWithdrawalAddress(podAddress), withdrawAddress);
        assertTrue(BitcoinPod(podAddress).getPodState() == IBitcoinPod.PodState.Inactive);

        // Cancel withdrawal request
        vm.prank(user);
        podManager.cancelWithdrawalRequest(podAddress);

        // Verify cancellation
        assertEq(podManager.getBitcoinWithdrawalAddress(podAddress), "");
        assertTrue(BitcoinPod(podAddress).getPodState() == IBitcoinPod.PodState.Active);
    }

    function testCannotCancelWithdrawalAfterPSBTSubmission() public {
        // Setup
        ISignatureUtils.SignatureWithSaltAndExpiry memory operatorSignature;
        vm.prank(operator);
        bitDSMRegistry.registerOperatorWithSignature(operatorSignature, operator, operatorBtcPubKey);

        vm.prank(user);
        address podAddress = podManager.createPod(operator, userBtcAddress, lockScript);

        // Add balance
        vm.prank(user);
        podManager.verifyBitcoinDepositRequest(podAddress, bytes32("deposit_tx"), 2);
        vm.prank(address(serviceManager));
        podManager.confirmBitcoinDeposit(podAddress, bytes32("deposit_tx"), 2);

        // Initiate withdrawal
        string memory withdrawAddress = "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx";
        vm.prank(user);
        podManager.withdrawBitcoinPSBTRequest(podAddress, withdrawAddress);

        // Service manager submits PSBT
        bytes memory signedPSBT = "signed_psbt_data";
        vm.prank(address(serviceManager));
        podManager.setSignedBitcoinWithdrawTransactionPod(podAddress, signedPSBT);

        // Try to cancel withdrawal - should fail
        vm.prank(user);
        vm.expectRevert(
            abi.encodeWithSelector(IBitcoinPodManager.WithdrawalTransactionAlreadySubmitted.selector, podAddress)
        );
        podManager.cancelWithdrawalRequest(podAddress);
    }

    function testCannotCancelNonExistentWithdrawal() public {
        // Setup
        ISignatureUtils.SignatureWithSaltAndExpiry memory operatorSignature;
        vm.prank(operator);
        bitDSMRegistry.registerOperatorWithSignature(operatorSignature, operator, operatorBtcPubKey);

        vm.prank(user);
        address podAddress = podManager.createPod(operator, userBtcAddress, lockScript);

        // Try to cancel non-existent withdrawal
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(IBitcoinPodManager.NoWithdrawalRequestToCancel.selector, podAddress));
        podManager.cancelWithdrawalRequest(podAddress);
    }

    function testOnlyOwnerCanCancelWithdrawal() public {
        // Setup
        ISignatureUtils.SignatureWithSaltAndExpiry memory operatorSignature;
        vm.prank(operator);
        bitDSMRegistry.registerOperatorWithSignature(operatorSignature, operator, operatorBtcPubKey);

        vm.prank(user);
        address podAddress = podManager.createPod(operator, userBtcAddress, lockScript);

        // Initiate withdrawal
        string memory withdrawAddress = "tb1qw508d6qejxtdg4y5r3zarvary0c5xw7kxpjzsx";
        vm.prank(user);
        podManager.withdrawBitcoinPSBTRequest(podAddress, withdrawAddress);

        // Try to cancel from non-owner address
        address nonOwner = address(0x999);
        vm.prank(nonOwner);
        vm.expectRevert("Not the pod owner");
        podManager.cancelWithdrawalRequest(podAddress);
    }
}
// Mock contract to test verifyBTCAddress

contract BTCAddressTestContract is BitcoinPodManager {
    function verifyBTCAddress(string calldata btcAddress, bytes calldata script, bytes memory operatorBtcKey)
        external
        pure
        returns (bool)
    {
        return _verifyBTCAddress(btcAddress, script, operatorBtcKey);
    }
}
