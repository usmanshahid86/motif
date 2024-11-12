// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "forge-std/Test.sol";
import {BitDSMServiceManager} from "../src/core/BitDSMServiceManager.sol";
import {BitcoinPod} from "../src/core/BitcoinPod.sol";

import {ECDSAServiceManagerBase} from "@eigenlayer-middleware/src/unaudited/ECDSAServiceManagerBase.sol";
import {ISignatureUtils} from "@eigenlayer/src/contracts/interfaces/ISignatureUtils.sol";
import {IAVSDirectory} from "@eigenlayer/src/contracts/interfaces/IAVSDirectory.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {BitcoinPodManager} from "../src/core/BitcoinPodManager.sol";
contract MockAVSDirectory is IAVSDirectory {
    function registerOperatorToAVS(address, ISignatureUtils.SignatureWithSaltAndExpiry memory) external pure {}
    function deregisterOperatorFromAVS(address) external pure {}
    function updateAVSMetadataURI(string memory) external pure {}
    function OPERATOR_AVS_REGISTRATION_TYPEHASH() external pure returns (bytes32) {
        return bytes32(0);
    }
    function calculateOperatorAVSRegistrationDigestHash(
        address operator,
        address avs,
        bytes32 salt,
        uint256 expiry
    ) external pure returns (bytes32) {
        return bytes32(0);
    }
    function operatorSaltIsSpent(address operator, bytes32 salt) external pure returns (bool) {
        return false;
    }
}

contract MockECDSAStakeRegistry {
    function operatorRegistered(address) external pure returns (bool) {
        return true;
    }
}

contract BitDSMServiceManagerTest is Test {
    using ECDSA for bytes32;

    BitDSMServiceManager public serviceManager;
    BitcoinPod public pod;

    MockAVSDirectory public mockAVSDirectory;
    MockECDSAStakeRegistry public mockStakeRegistry;
    
    address public owner;
    address public operator;
    address public manager;
    address public operator2;
    uint256 private operatorPrivateKey;
    bytes public operatorBtcPubKey;
    bytes public bitcoinAddress;
    
    event BitcoinWithdrawalTransactionSigned(address indexed pod, address indexed operator, uint256 amount);
    function setUp() public {
        owner = address(this);
        operatorPrivateKey = 0x1; // This is the private key for operator1
        operator = vm.addr(operatorPrivateKey);
        operator2 = address(0x2);

        // Mock Bitcoin-related data
        operatorBtcPubKey = hex"02abc123"; // Example public key
        bitcoinAddress = hex"1234567890"; // Example Bitcoin address (padded to even length)
        
        mockAVSDirectory = new MockAVSDirectory();
        mockStakeRegistry = new MockECDSAStakeRegistry();
        // Deploy service manager
        serviceManager = new BitDSMServiceManager(
            address(mockAVSDirectory),
            address(mockStakeRegistry),
            address(0), // mock delegation manager
            address(0) // mock rewards coordinator 
        );
       // bitcoinPodManager = new BitcoinPodManager(
         //   address(serviceManager)
        //);
        pod = new BitcoinPod(
            address(serviceManager)
        );
        pod.initialize(owner, operator, operatorBtcPubKey, bitcoinAddress);
    }

    function testConfirmDeposit() public {
        uint256 amount = 1;
        // create a transaction confirmation request first         
        // Create deposit confirmation message
        bytes32 messageHash = keccak256(abi.encodePacked(
            address(pod),
            operator,
            amount,
          //  transactionId,
            true
        ));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        
        // Sign message with operator's private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(operatorPrivateKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Confirm deposit as operator
        vm.prank(operator);
        serviceManager.confirmDeposit(address(pod), signature);
        
        // Assert pod state changes
        assertEq(pod.bitcoinBalance(), amount);
    }

    function testWithdrawBitcoinPSBT() public {
        uint256 amount = 1 ether;
        bytes memory psbtTx = hex"0200000001"; // Example PSBT transaction
        
        // Create PSBT signature message
        bytes32 messageHash = keccak256(abi.encodePacked(
            address(pod),
            amount,
            psbtTx,
            bitcoinAddress
        ));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        
        // Sign message
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(operatorPrivateKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Expect event emission
        vm.expectEmit(true, true, false, true);
        emit BitcoinWithdrawalTransactionSigned(address(pod), operator, amount);

        // Submit PSBT as operator
        vm.prank(operator);
        serviceManager.withdrawBitcoinPSBT(address(pod), amount, psbtTx, signature);
    }
    
    function testWithdrawBitcoinCompleteTx() public {
        uint256 amount = 1 ether;
        bytes memory completeTx = hex"0200000001"; // Example complete transaction
        
        // Create complete tx signature message
        bytes32 messageHash = keccak256(abi.encodePacked(
            address(pod),
            amount,
            completeTx
        ));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        
        // Sign message
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(operatorPrivateKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Submit complete transaction as operator
        vm.prank(operator);
        serviceManager.withdrawBitcoinCompleteTx(address(pod), amount, completeTx, signature);
    }

    function testConfirmWithdrawal() public {
        bytes memory transaction = hex"0200000001"; // Example Bitcoin transaction
        
        // Create withdrawal confirmation message
        bytes32 messageHash = keccak256(abi.encodePacked(
            address(pod),
            transaction
        ));
        bytes32 ethSignedMessageHash = messageHash.toEthSignedMessageHash();
        
        // Sign message
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(operatorPrivateKey, ethSignedMessageHash);
        bytes memory signature = abi.encodePacked(r, s, v);

        // Confirm withdrawal as operator
        vm.prank(operator);
        serviceManager.confirmWithdrawal(address(pod), transaction, signature);
    }


    function testFailConfirmDepositUnauthorized() public {
        bytes memory signature = new bytes(65);
        
        // Try to confirm deposit from unauthorized address
        vm.prank(address(0xbad));
        vm.expectRevert("Unauthorized operator");
        serviceManager.confirmDeposit(address(pod), signature);
    }

    function testFailWithdrawBitcoinPSBTInvalidSignature() public {
        uint256 amount = 1 ether;
        bytes memory psbtTx = hex"0200000001";
        bytes memory invalidSignature = new bytes(65);

        vm.prank(operator);
        vm.expectRevert("Invalid signature");
        serviceManager.withdrawBitcoinPSBT(address(pod), amount, psbtTx, invalidSignature);
    }

    function testFailWithdrawBitcoinCompleteTxUnauthorized() public {
        uint256 amount = 1 ether;
        
        bytes memory completeTx = hex"0200000001";
        bytes memory signature = new bytes(65);

        vm.prank(address(0xbad));
        vm.expectRevert("Unauthorized operator");
        serviceManager.withdrawBitcoinCompleteTx(address(pod), amount, completeTx, signature);
    }

    function testFailConfirmWithdrawalInvalidTransaction() public {
        bytes memory invalidTx = new bytes(0);
        bytes memory signature = new bytes(65);

        vm.prank(operator);
        vm.expectRevert("Invalid transaction");
        serviceManager.confirmWithdrawal(address(pod), invalidTx, signature);
    }
}

