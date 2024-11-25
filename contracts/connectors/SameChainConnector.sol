// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import {MessageLib} from "../lib/MessageLib.sol";
import {SingleRouter} from "../SingleRouter.sol";
import {BaseConnector} from "./BaseConnector.sol";
import {ISingleIdentifierRegistry} from "../interfaces/ISingleIdentifierRegistry.sol";

contract SameChainConnector is BaseConnector {

    event UpdateRegistry(address indexed registry);

    function quote(uint32 /*registryDst*/, bytes memory /*payload*/) public virtual view returns (uint256) {
        return 0;
    }

    function supportMethod(bytes4 selector) external pure override returns (bool) {
        return selector == this.receiveMessage.selector;
    }

    constructor(address _admin, address _operator, address _registry) BaseConnector(_admin, _operator, _registry) {}

    function receiveMessage(bytes memory _payload) external {
        if (!router.isAvailablePeer(block.chainid, connectorId, msg.sender)) revert SenderIsNotPeer(uint32(block.chainid));

        MessageLib.DecodedMessage memory decodedPayload = MessageLib.decodeMessage(_payload);

        if (decodedPayload.messageType == MessageLib.MessageType.TYPE_SEND_REGISTER) {
            registry.registrySID(decodedPayload.sendMessage);
        } else if (decodedPayload.messageType == MessageLib.MessageType.TYPE_SEND_UPDATE) {
            registry.updateSID(decodedPayload.renewalMessage);
        }
    }

    function sendMessage(uint256 /*registryDst*/, bytes memory _payload) external payable {
        SameChainConnector(address(registry)).receiveMessage(_payload);
    }
}
