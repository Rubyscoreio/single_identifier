// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

library MessageLib {

    struct SendMessage {
        bytes32 schemaId;
        address user;
        uint64 expirationDate;
        bytes data;
        string metadata;
    }

    struct UpdateMessage {
        bytes32 id;
        uint64 expirationDate;
        bytes data;
        string metadata;
    }

    enum MessageType {TYPE_SEND_REGISTER, TYPE_SEND_UPDATE}

    struct DecodedMessage {
        MessageType messageType;
        SendMessage sendMessage;
        UpdateMessage renewalMessage;
    }

    uint8 public constant TYPE_SEND_REGISTER = 1;
    uint8 public constant TYPE_SEND_UPDATE = 2;

    function encodeMessage(SendMessage memory _message) internal pure returns (bytes memory) {
        return abi.encode(TYPE_SEND_REGISTER, _message.schemaId, _message.user, _message.expirationDate, _message.data, _message.metadata);
    }

    function encodeMessage(UpdateMessage memory _message) internal pure returns (bytes memory) {
        return abi.encode(TYPE_SEND_UPDATE, _message.id, _message.expirationDate, _message.data, _message.metadata);
    }

    function decodeMessage(bytes memory _rawData) internal pure returns (DecodedMessage memory) {
        uint8 messageType;
        (messageType) = abi.decode(_rawData, (uint8));

        if (messageType == TYPE_SEND_REGISTER) {
            (,bytes32 schemaId,
                address user,
                uint64 expirationDate,
                bytes memory registerData,
                string memory metadata
            ) = abi.decode(_rawData, (uint8, bytes32, address, uint64, bytes, string));

            SendMessage memory sendMessage = SendMessage(schemaId, user, expirationDate, registerData, metadata);
            return DecodedMessage(MessageType.TYPE_SEND_REGISTER, sendMessage, UpdateMessage(bytes32(0), 0, "", ""));
        } else if (messageType == TYPE_SEND_UPDATE) {
            (, bytes32 id, uint64 expirationDate, bytes memory updateData, string memory metadata) = abi.decode(_rawData, (uint8, bytes32, uint64, bytes, string));

            UpdateMessage memory renewalMessage = UpdateMessage(id, expirationDate, updateData, metadata);
            return DecodedMessage(MessageType.TYPE_SEND_UPDATE, SendMessage(bytes32(0), address(0), 0, "", ""), renewalMessage);
        } else {
            revert("Unknown message type");
        }
    }
}
