// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

interface IConnector {

    function sendMessage(uint256 _registryDst, bytes calldata _payload) external payable;

    function quote(uint256 _registryDst, bytes memory _payload) external view returns (uint256);

    function getProtocolId() external view returns (bytes32);

    function getDestinationChainId(uint256 nativeChainId) external view returns (uint256);

    function setConnectorId(uint32 _connectorId) external;

    function connectorId() external view returns (uint32);
}
