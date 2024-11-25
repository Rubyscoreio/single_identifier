// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import {SingleRouter} from "../SingleRouter.sol";
import {MessageLib} from "../lib/MessageLib.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ISingleIdentifierRegistry} from "../interfaces/ISingleIdentifierRegistry.sol";

abstract contract BaseConnector is AccessControl {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    SingleRouter public router;
    ISingleIdentifierRegistry public registry;
    uint32 public connectorId;

    mapping(uint256 nativeChainId => uint256 customChainId) public customChainIds;
    mapping(uint256 customChainId => uint256 nativeChainId) public nativeChainIds;

    event SetRouter(address indexed router);
    event SetRegistry(address indexed registry);
    event SetChainIds(uint256 indexed nativeChainId, uint256 indexed customChainId);
    event SetConnectorId(uint32 indexed connectorId);

    error SenderIsNotPeer(uint32 eid);
    error SenderIsNotRouter(address sender);
    error AddressIsZero();

    constructor(address _admin, address _operator, address _registry) {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(OPERATOR_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, _operator);

        _setRegistry(_registry);
    }

    function setRegistry(address _registry) external onlyRole(OPERATOR_ROLE) {
        _setRegistry(_registry);
        emit SetRegistry(_registry);
    }

    function setRouter(address _router) external onlyRole(OPERATOR_ROLE) {
        if (_router == address(0)) revert AddressIsZero();

        router = SingleRouter(_router);
        emit SetRouter(_router);
    }

    function setChainIds(uint256[] calldata _nativeChainIds, uint256[] calldata _customChainIds) external onlyRole(OPERATOR_ROLE) {
        require(_nativeChainIds.length == _customChainIds.length, "Invalid arrays length.");

        for (uint256 i = 0; i < _nativeChainIds.length; i++) {
            _setChainId(_nativeChainIds[i], _customChainIds[i]);
        }
    }

    function setChainId(uint256 _nativeChainId, uint256 _customChainId) external onlyRole(OPERATOR_ROLE) {
        _setChainId(_nativeChainId, _customChainId);
    }

    function setConnectorId(uint32 _connectorId) external {
        if (msg.sender != address(router)) revert SenderIsNotRouter(msg.sender);

        connectorId = _connectorId;
        emit SetConnectorId(_connectorId);
    }

    function _setChainId(uint256 _nativeChainId, uint256 _customChainId) private {
        nativeChainIds[_customChainId] = _nativeChainId;
        customChainIds[_nativeChainId] = _customChainId;

        emit SetChainIds(_nativeChainId, _customChainId);
    }

    function _setRegistry(address _registry) private {
        if (_registry == address(0)) revert AddressIsZero();

        registry = ISingleIdentifierRegistry(_registry);
    }

    function supportMethod(bytes4 selector) external pure virtual returns (bool);
}
