// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {IConnector} from "./interfaces/IConnector.sol";
import {Destination} from "./types/Structs.sol";


contract SingleRouter is AccessControlUpgradeable, UUPSUpgradeable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    address[] public connectorsList;

    mapping(uint32 connectorId => IConnector connector) public connectors;
    mapping(uint256 chainId => mapping(uint32 connectorId => bytes32 peer)) public peers;

    function getRoute(uint32 _connectorId, uint256 _destinationChainId) external view returns (IConnector) {
        IConnector connector;

        if (block.chainid == _destinationChainId) {
            connector = connectors[0];
        } else {
            connector = connectors[_connectorId];
        }

        return connector;
    }

    function getPeer(uint32 _connectorId, uint256 _chainId) external view returns (bytes32) {
        bytes32 peer = peers[_chainId][_connectorId];
        if (peer == bytes32(0)) revert PeerNotExist(_chainId);

        return peer;
    }

    function isAvailablePeer(uint256 _chainId, uint32 _connectorId, address _sender) external view returns (bool) {
        bytes32 senderInBytes32 = bytes32(uint256(uint160(_sender)));

        bytes32 peer = peers[_chainId][_connectorId];
        return senderInBytes32 == peer;
    }

    event PeerSet(uint256 indexed chainId, uint32 indexed _connectorId, bytes32 peer);
    event SetConnector(uint32 indexed connectorId, address indexed transferProtocol);
    event SetProtocolChainId(uint32 protocolChainId, uint256 chainId);

    error PeerNotExist(uint256 chainId);
    error PeerInvalid();
    error AddressIsZero();

    function initialize(address _operator) external initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        if (_operator == address(0)) revert AddressIsZero();

        _grantRole(OPERATOR_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, _operator);
    }

    function setPeer(uint256 _chainId, uint32 _connectorId, bytes32 _peer) external onlyRole(OPERATOR_ROLE) {
        _setPeer(_chainId, _connectorId, _peer);
    }

    function setPeers(uint32 _connectorId, uint256[]  calldata _chainIds, bytes32[]  calldata _peers) external onlyRole(OPERATOR_ROLE) {
        require(_chainIds.length == _peers.length, "Invalid arrays length.");

        for (uint256 i = 0; i < _chainIds.length; i++) {
            _setPeer(_chainIds[i], _connectorId, _peers[i]);
        }
    }

    function setConnectors(uint32[] calldata _connectorIds, address[] calldata _connectors) external onlyRole(OPERATOR_ROLE) {
        require(_connectorIds.length == _connectors.length, "Invalid arrays length.");

        for (uint256 i = 0; i < _connectors.length; i++) {
            _setConnector(_connectorIds[i], _connectors[i]);
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(OPERATOR_ROLE) {}

    function setConnector(uint32 connectorId, address _connector) external onlyRole(OPERATOR_ROLE) {
        _setConnector(connectorId, _connector);
    }

    function _setConnector(uint32 _connectorId, address _connector) private {
        connectors[_connectorId] = IConnector(_connector);

        IConnector(_connector).setConnectorId(_connectorId);
        emit SetConnector(_connectorId, _connector);
    }

    function _setConnector(address _connector) private {
        uint32 connectorId = uint32(connectorsList.length);

        connectors[connectorId] = IConnector(_connector);

        IConnector(_connector).setConnectorId(connectorId);
        emit SetConnector(connectorId, _connector);
    }

    function _setPeer(uint256 _chainId, uint32 _connectorId, bytes32 _peer) private {
        if (_peer == bytes32(0)) revert PeerInvalid();

        peers[_chainId][_connectorId] = _peer;
        emit PeerSet(_chainId, _connectorId, _peer);
    }
}
