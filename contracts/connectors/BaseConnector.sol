// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import {SingleRouter} from "../SingleRouter.sol";
import {MessageLib} from "../lib/MessageLib.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ISingleIdentifierRegistry} from "../interfaces/ISingleIdentifierRegistry.sol";
import {SingleIdentifierID} from "../SingleIdentifierID.sol";

/// @title BaseConnector
/// @notice Base functionality for all connectors
abstract contract BaseConnector is AccessControl {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    SingleRouter public router;                 /// @notice Address of actual router contract
    SingleIdentifierID public singleId;         /// @notice Address of actual SingleIdentifierID contract
    ISingleIdentifierRegistry public registry;  /// @notice Address of actual SingleIdentifierRegistry contract
    uint32 public connectorId;                  /// @notice Id of that connector

    mapping(uint256 nativeChainId => uint256 customChainId) public customChainIds;  /// @notice Custom chain id for native chain id
    mapping(uint256 customChainId => uint256 nativeChainId) public nativeChainIds;  /// @notice Native chain id for custom chain id

    event SetRouter(address indexed router);
    event SetRegistry(address indexed registry);
    event SetSingleId(address indexed singleId);
    event SetChainIds(uint256 indexed nativeChainId, uint256 indexed customChainId);
    event SetConnectorId(uint32 indexed connectorId);

    error SenderIsNotPeer(uint32 eid, address sender);
    error SenderIsNotSingleId(address sender);
    error SenderIsNotRouter(address sender);
    error AddressIsZero();

    constructor(address _admin, address _operator, address _registry) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(OPERATOR_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, _operator);

        _setRegistry(_registry);
    }

    /// @notice Sets registry address
    /// @param _registry - New registry address, can't be 0x0
    /// @dev _registry address zero check is performed in the _setRegistry function
    function setRegistry(address _registry) external onlyRole(OPERATOR_ROLE) {
        _setRegistry(_registry);
    }

    /// @notice Sets router address
    /// @param _router - New router address, can't be 0x0
    function setRouter(address _router) external onlyRole(OPERATOR_ROLE) {
        if (_router == address(0)) revert AddressIsZero();

        router = SingleRouter(_router);
        emit SetRouter(_router);
    }

    /// @notice Sets SingleIdentifierID contract address
    /// @param _singleId - New single identifier address, can't be 0x0
    /// @dev _singleId address zero check is performed in the _setSingleId function
    function setSingleId(address _singleId) external onlyRole(OPERATOR_ROLE) {
        _setSingleId(_singleId);
    }

    /// @notice Adds assignment between several native - custom chain id pairs
    /// @param _nativeChainIds - Array of native chain ids
    /// @param _customChainIds - Array of custom chain ids
    /// @dev _nativeChainIds and _customChainIds should have the same length
    function setChainIds(uint256[] calldata _nativeChainIds, uint256[] calldata _customChainIds) external onlyRole(OPERATOR_ROLE) {
        require(_nativeChainIds.length == _customChainIds.length, "Invalid arrays length.");

        for (uint256 i = 0; i < _nativeChainIds.length; i++) {
            _setChainId(_nativeChainIds[i], _customChainIds[i]);
        }
    }

    /// @notice Adds assignment between native - custom chain id pair
    /// @param _nativeChainId - Native chain id
    /// @param _customChainId - Custom chain id
    function setChainId(uint256 _nativeChainId, uint256 _customChainId) external onlyRole(OPERATOR_ROLE) {
        _setChainId(_nativeChainId, _customChainId);
    }

    /// @notice Sets connector id
    /// @param _connectorId - New connector id
    function setConnectorId(uint32 _connectorId) external {
        if (msg.sender != address(router)) revert SenderIsNotRouter(msg.sender);

        connectorId = _connectorId;
        emit SetConnectorId(_connectorId);
    }

    /// @notice Assigns chain id for native chain id and vice versa
    /// @param _nativeChainId - Native chain id
    /// @param _customChainId - Custom chain id
    function _setChainId(uint256 _nativeChainId, uint256 _customChainId) private {
        nativeChainIds[_customChainId] = _nativeChainId;
        customChainIds[_nativeChainId] = _customChainId;

        emit SetChainIds(_nativeChainId, _customChainId);
    }

    /// @notice Sets SingleIdentifierRegistry contract address
    /// @param _registry - New registry address, can't be 0x0
    function _setRegistry(address _registry) private {
        if (_registry == address(0)) revert AddressIsZero();

        registry = ISingleIdentifierRegistry(_registry);
        emit SetRegistry(_registry);
    }

    /// @notice Sets SingleIdentifierID contract address
    /// @param _singleId - New single identifier address, can't be 0x0
    function _setSingleId(address _singleId) private {
        if (_singleId == address(0)) revert AddressIsZero();

        singleId = SingleIdentifierID(_singleId);
        emit SetSingleId(_singleId);
    }

    /// @notice Checks if the method with specified selector is supported by the connector
    /// @param selector - Selector of the method
    /// @return Is the method supported
    function supportMethod(bytes4 selector) external pure virtual returns (bool);

    /// @notice Checks if the sender is the SingleIdentifierID contract
    modifier onlySingleId() {
        if (msg.sender != address(singleId)) revert SenderIsNotSingleId(msg.sender);
        _;
    }
}
