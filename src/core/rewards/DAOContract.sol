// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract DAOContract {
    address public multisig; // DAO's controlling address

    // Global split ratio (in basis points, e.g., 70% = 7000)
    uint16 public operatorSplitBips; // Percentage to operators
    uint16 public avsSplitBips;      // Percentage to AVSs

    // Mapping for AVS weights
    mapping(address => uint256) public avsWeights;
    address[] public activeAVSs;

    event AVSWeightUpdated(address indexed avs, uint256 oldWeight, uint256 newWeight);
    event AVSAdded(address indexed avs);
    event AVSRemoved(address indexed avs);
    event SplitUpdated(uint16 operatorSplitBips, uint16 avsSplitBips);

    modifier onlyMultisig() {
        require(msg.sender == multisig, "Not authorized");
        _;
    }

    constructor(address _multisig, uint16 _operatorSplitBips, uint16 _avsSplitBips) {
        require(_multisig != address(0), "Invalid multisig address");
        require(_operatorSplitBips + _avsSplitBips == 10000, "Invalid split");
        multisig = _multisig;
        operatorSplitBips = _operatorSplitBips;
        avsSplitBips = _avsSplitBips;
    }

    /**
     * @dev Updates the split ratio between operators and AVSs
     * @param _operatorSplitBips Percentage for operators (in basis points)
     * @param _avsSplitBips Percentage for AVSs (in basis points)
     */
    function updateSplit(uint16 _operatorSplitBips, uint16 _avsSplitBips) external onlyMultisig {
        require(_operatorSplitBips + _avsSplitBips == 10000, "Invalid split");
        operatorSplitBips = _operatorSplitBips;
        avsSplitBips = _avsSplitBips;
        emit SplitUpdated(_operatorSplitBips, _avsSplitBips);
    }

    /**
     * @dev Sets the weight for an AVS
     * @param avs Address of the AVS
     * @param weight Weight of the AVS
     */
    function setAVSWeight(address avs, uint256 weight) external onlyMultisig {
        require(avs != address(0), "Invalid AVS address");
        if (avsWeights[avs] == 0) {
            activeAVSs.push(avs);
            emit AVSAdded(avs);
        }
        uint256 oldWeight = avsWeights[avs];
        avsWeights[avs] = weight;
        emit AVSWeightUpdated(avs, oldWeight, weight);
    }

    /**
     * @dev Removes an AVS from the list
     * @param avs Address of the AVS
     */
    function removeAVS(address avs) external onlyMultisig {
        require(avsWeights[avs] != 0, "AVS not active");
        avsWeights[avs] = 0;

        for (uint256 i = 0; i < activeAVSs.length; i++) {
            if (activeAVSs[i] == avs) {
                activeAVSs[i] = activeAVSs[activeAVSs.length - 1];
                activeAVSs.pop();
                break;
            }
        }
        emit AVSRemoved(avs);
    }

    /**
     * @dev Returns the weight of a specific AVS
     */
    function getAVSWeight(address avs) external view returns (uint256) {
        return avsWeights[avs];
    }

    /**
     * @dev Returns the list of active AVSs
     */
    function getActiveAVSs() external view returns (address[] memory) {
        return activeAVSs;
    }

    /**
     * @dev Returns the total weight of all active AVSs
     */
    function getTotalWeight() external view returns (uint256 totalWeight) {
        for (uint256 i = 0; i < activeAVSs.length; i++) {
            totalWeight += avsWeights[activeAVSs[i]];
        }
    }
}
