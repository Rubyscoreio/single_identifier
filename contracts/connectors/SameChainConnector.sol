// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import {MessageLib} from "../lib/MessageLib.sol";
import {SingleRouter} from "../SingleRouter.sol";
import {BaseConnector} from "./BaseConnector.sol";
import {ISingleIdentifierRegistry} from "../interfaces/ISingleIdentifierRegistry.sol";

contract SameChainConnector is BaseConnector {

    event UpdateRegistry(address indexed registry);

    function quote(uint256 /*registryDst*/, bytes memory /*payload*/) public virtual view returns (uint256) {
        return 0;
    }

    function supportMethod(bytes4 /*selector*/) external pure override returns (bool) {
        return true;
    }

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
