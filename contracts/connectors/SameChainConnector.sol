// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import {MessageLib} from "../lib/MessageLib.sol";
import {SingleRouter} from "../SingleRouter.sol";
import {BaseConnector} from "./BaseConnector.sol";
import {ISingleIdentifierRegistry} from "../interfaces/ISingleIdentifierRegistry.sol";

/// @title SameChainConnector
/// @notice Connector for messages sent to the same chain where sender is
contract SameChainConnector is BaseConnector {

    event UpdateRegistry(address indexed registry);

    /// @notice Quotes the fee for sending message to the specified chain
    /// @return 0
    /// @dev For same chain messages fee is always 0
    function quote(uint256 /*registryDst*/, bytes memory /*payload*/) public virtual view returns (uint256) {
        return 0;
    }

    /// @notice Checks if the method with specified selector is supported by the connector
    /// @return true
    /// @dev For same chain messages always true
    function supportMethod(bytes4 /*selector*/) external pure override returns (bool) {
        return true;
    }

    /// @param _admin - Address of the admin
    /// @param _operator - Address of the operator
    /// @param _registry - Address of the registry contract
    constructor(address _admin, address _operator, address _registry) BaseConnector(_admin, _operator, _registry) {}

    function sendMessage(uint256 /*registryDst*/, bytes memory _payload) external payable onlySingleId {
        _receiveMessage(_payload);
    }

    function _receiveMessage(bytes memory _payload) internal {
        MessageLib.DecodedMessage memory decodedPayload = MessageLib.decodeMessage(_payload);

        if (decodedPayload.messageType == MessageLib.MessageType.TYPE_SEND_REGISTER) {
            registry.registrySID(decodedPayload.sendMessage);
        } else if (decodedPayload.messageType == MessageLib.MessageType.TYPE_SEND_UPDATE) {
            registry.updateSID(decodedPayload.renewalMessage);
        }
    }
}
