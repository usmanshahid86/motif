// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract MultiSig is Initializable, OwnableUpgradeable {
    // Distribution weights (percentage, scaled to 100)
    struct DistributionWeights {
        uint256 appRegistryWeight;
        uint256 securityRegistryWeight;
        uint256 operatorWeight;
        uint256 tvlWeight;
    }

    DistributionWeights public weights;

    // Multisig members and confirmations
    address[] public members;
    uint256 public requiredConfirmations;

    mapping(bytes32 => uint256) public confirmations;
    mapping(bytes32 => mapping(address => bool)) public hasConfirmed;

    event WeightChangeProposed(bytes32 indexed proposalId, DistributionWeights proposedWeights);
    event WeightChangeConfirmed(bytes32 indexed proposalId, address indexed confirmer);
    event WeightChangeExecuted(bytes32 indexed proposalId, DistributionWeights newWeights);

    function initialize(address[] memory _members, uint256 _requiredConfirmations) external initializer {
        __Ownable_init();

        require(_members.length >= _requiredConfirmations, "Invalid multisig configuration");
        members = _members;
        requiredConfirmations = _requiredConfirmations;

        // Set default weights
        weights = DistributionWeights({
            appRegistryWeight: 25,
            securityRegistryWeight: 25,
            operatorWeight: 30,
            tvlWeight: 20
        });
    }

    modifier onlyMember() {
        require(isMember(msg.sender), "Not a multisig member");
        _;
    }

    function isMember(address account) public view returns (bool) {
        for (uint256 i = 0; i < members.length; i++) {
            if (members[i] == account) return true;
        }
        return false;
    }

    function proposeWeightChange(DistributionWeights memory newWeights) external onlyMember {
        require(
            newWeights.appRegistryWeight + newWeights.securityRegistryWeight + 
            newWeights.operatorWeight + newWeights.tvlWeight == 100,
            "Weights must add up to 100"
        );

        bytes32 proposalId = keccak256(abi.encode(newWeights));
        require(confirmations[proposalId] == 0, "Proposal already exists");

        confirmations[proposalId] = 1;
        hasConfirmed[proposalId][msg.sender] = true;

        emit WeightChangeProposed(proposalId, newWeights);
    }

    function confirmWeightChange(DistributionWeights memory newWeights) external onlyMember {
        bytes32 proposalId = keccak256(abi.encode(newWeights));
        require(confirmations[proposalId] > 0, "Proposal does not exist");
        require(!hasConfirmed[proposalId][msg.sender], "Already confirmed");

        confirmations[proposalId]++;
        hasConfirmed[proposalId][msg.sender] = true;

        emit WeightChangeConfirmed(proposalId, msg.sender);

        if (confirmations[proposalId] >= requiredConfirmations) {
            _executeWeightChange(proposalId, newWeights);
        }
    }

    function _executeWeightChange(bytes32 proposalId, DistributionWeights memory newWeights) internal {
        weights = newWeights;
        delete confirmations[proposalId];

        emit WeightChangeExecuted(proposalId, newWeights);
    }

    function getCurrentWeights() external view returns (DistributionWeights memory) {
        return weights;
    }
}
