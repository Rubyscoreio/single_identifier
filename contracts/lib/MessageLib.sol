// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

/// @title MessageLib
/// @notice Library for encoding and decoding messages
library MessageLib {

    /// @notice Single message for sending
    struct SendMessage {
        bytes32 schemaId;       /// @notice Id of schema that was used for encoding message
        address user;           /// @notice Address that sent the message
        uint64 expirationDate;  /// @notice Timestamp when message expires
        bytes data;             /// @notice Message data
        string metadata;        /// @notice Message metadata
    }

    /// @notice Message for updating already sent message
    struct UpdateMessage {
        bytes32 id;             /// @notice Id of message that should be updated
        uint64 expirationDate;  /// @notice Updated timestamp when message expires
        bytes data;             /// @notice Updated message data
        string metadata;        /// @notice Updated message metadata
    }

    /// @notice Message types
    enum MessageType {TYPE_SEND_REGISTER, TYPE_SEND_UPDATE}

    /// @notice Decoded message
    struct DecodedMessage {
        MessageType messageType;        /// @notice Type of message
        SendMessage sendMessage;        /// @notice Message data if messageType is TYPE_SEND_REGISTER, otherwise 0
        UpdateMessage renewalMessage;   /// @notice Renewal message data if messageType is TYPE_SEND_UPDATE, otherwise 0
    }

    uint8 public constant TYPE_SEND_REGISTER = 1;/// @notice Constant for register message type
    uint8 public constant TYPE_SEND_UPDATE = 2;/// @notice Constant for update message type

    /// @notice Encodes message for sending
    /// @param _message - Message that should be encoded
    /// @return Encoded message
    function encodeMessage(SendMessage memory _message) internal pure returns (bytes memory) {
        return abi.encode(TYPE_SEND_REGISTER, _message.schemaId, _message.user, _message.expirationDate, _message.data, _message.metadata);
    }

    /// @notice Encodes message for updating already sent message
    /// @param _message - Message that should be encoded
    /// @return Encoded message
    function encodeMessage(UpdateMessage memory _message) internal pure returns (bytes memory) {
        return abi.encode(TYPE_SEND_UPDATE, _message.id, _message.expirationDate, _message.data, _message.metadata);
    }

    /// @notice Decodes message
    /// @param _rawData - Raw received data that should be decoded
    /// @return Decoded message
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
