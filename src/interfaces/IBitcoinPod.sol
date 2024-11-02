// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBitcoinPod {
   

    function getBitcoinAddress() external view returns (bytes memory);
    function getOperatorBtcPubKey() external view returns (bytes memory);
    function getOperator() external view returns (address);
    function getBitcoinBalance() external view returns (uint256);
    function lock() external;
    function unlock() external;
    function isLocked() external view returns (bool);
    function mint(address operator, uint256 amount) external;
    function burn(address operator, uint256 amount) external;
}
