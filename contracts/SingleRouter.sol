// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {IConnector} from "./interfaces/IConnector.sol";
import {Destination} from "./types/Structs.sol";

/// @title SingleRouter
/// @notice Responsible for routing messages between chains
contract SingleRouter is AccessControlUpgradeable, UUPSUpgradeable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    // Upgradeable storage
    // v0.0.1
    address[] public connectorsList; /// @dev deprecated

    mapping(uint32 connectorId => IConnector connector) public connectors;/// @notice Connectors addresses
    mapping(uint256 chainId => mapping(uint32 connectorId => bytes32 peer)) public peers; /// @notice Addresses of peers for connectors on chains in bytes32 format
    // Upgradeable storage end

    /// @notice Returns connector address for specified chain and connector id
    /// @param _connectorId - Id of connector to search on destination chain
    /// @param _destinationChainId - Chain where connector should be searched
    /// @return Address of the connector with specified id on the target chain, if not found returns zero address
    /// @dev If _destinationChainId targets to current chain, returns special connector
    function getRoute(uint32 _connectorId, uint256 _destinationChainId) external view returns (IConnector) {
        IConnector connector;

        if (block.chainid == _destinationChainId) {
            connector = connectors[0];
        } else {
            connector = connectors[_connectorId];
        }

        return connector;
    }

    /// @notice Returns peer address for specified chain and connector id
    /// @param _connectorId - Id of connector on specified chain
    /// @param _chainId - Id of the chain that should be used for sending message
    /// @return Peer address
    function getPeer(uint32 _connectorId, uint256 _chainId) external view returns (bytes32) {
        bytes32 peer = peers[_chainId][_connectorId];
        if (peer == bytes32(0)) revert PeerNotExist(_chainId);

        return peer;
    }

    /// @notice Checks if the sender is available peer for specified chain and connector id
    /// @param _chainId - Id of the chain that should be used for sending message
    /// @param _connectorId - Id of connector on specified chain
    /// @param _sender - Address of the sender
    /// @return Is the sender an available peer
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

    /// @notice Initializes upgradeable contract
    /// @param _operator - Operator address, can't be zero address
    function initialize(address _operator) external initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        if (_operator == address(0)) revert AddressIsZero();

        _grantRole(OPERATOR_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, _operator);
    }

    /// @notice Sets peer address for specified chain and connector id
    /// @param _chainId - Id of the chain where peer is deployed
    /// @param _connectorId - Id of connector for that peer
    /// @param _peer - Peer address in bytes32 format, can't be 0x0
    function setPeer(uint256 _chainId, uint32 _connectorId, bytes32 _peer) external onlyRole(OPERATOR_ROLE) {
        _setPeer(_chainId, _connectorId, _peer);
    }

    /// @notice Batched setPeer function
    /// @param _chainIds - Array of chain ids
    /// @param _connectorId - Array of chain connector ids
    /// @param _peers - Array of peer addresses in bytes32 format, can't be 0x0
    /// @dev _chainIds, _connectorId and _peers should have the same length
    function setPeers(uint32 _connectorId, uint256[]  calldata _chainIds, bytes32[]  calldata _peers) external onlyRole(OPERATOR_ROLE) {
        require(_chainIds.length == _peers.length, "Invalid arrays length.");

        for (uint256 i = 0; i < _chainIds.length; i++) {
            _setPeer(_chainIds[i], _connectorId, _peers[i]);
        }
    }

    /// @notice Batched setConnector function
    /// @param _connectorIds - Array of connector ids
    /// @param _connectors - Array of connector addresses
    /// @dev _connectorIds and _connectors should have the same length
    function setConnectors(uint32[] calldata _connectorIds, address[] calldata _connectors) external onlyRole(OPERATOR_ROLE) {
        require(_connectorIds.length == _connectors.length, "Invalid arrays length.");

        for (uint256 i = 0; i < _connectors.length; i++) {
            _setConnector(_connectorIds[i], _connectors[i]);
        }
    }

    /// @dev override for disabling authorised upgrades
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(OPERATOR_ROLE) {}

    /// @notice Sets connector address for specified connector id
    /// @param connectorId - Id of connector that should be used for sending message
    /// @param _connector - Connector address
    function setConnector(uint32 connectorId, address _connector) external onlyRole(OPERATOR_ROLE) {
        _setConnector(connectorId, _connector);
    }

    /// @notice Sets connector address for specified connector id
    /// @param _connectorId - Id of connector for which address should be assigned
    /// @param _connector - Connector address
    function _setConnector(uint32 _connectorId, address _connector) private {
        connectors[_connectorId] = IConnector(_connector);

        IConnector(_connector).setConnectorId(_connectorId);
        emit SetConnector(_connectorId, _connector);
    }

    /// @dev deprecated
    function _setConnector(address _connector) private {
        uint32 connectorId = uint32(connectorsList.length);

        connectors[connectorId] = IConnector(_connector);

        IConnector(_connector).setConnectorId(connectorId);
        emit SetConnector(connectorId, _connector);
    }

    /// @notice Sets peer address for specified chain and connector id
    /// @param _chainId - Id of the chain where peer is deployed
    /// @param _connectorId - Id of connector for that peer
    /// @param _peer - Peer address in bytes32 format, can't be 0x0
    function _setPeer(uint256 _chainId, uint32 _connectorId, bytes32 _peer) private {
        if (_peer == bytes32(0)) revert PeerInvalid();

        peers[_chainId][_connectorId] = _peer;
        emit PeerSet(_chainId, _connectorId, _peer);
    }
}
