// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import {MessageLib} from "../lib/MessageLib.sol";
import {OApp, Origin, OAppCore, MessagingFee} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import { MessagingParams, MessagingReceipt } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import {BaseConnector} from "./BaseConnector.sol";
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";

/// @title LayerZeroConnector
/// @notice Connector for LayerZero protocol
contract LayerZeroConnector is BaseConnector, OApp {
    using OptionsBuilder for bytes;

    uint128 public gasLimit;/// @notice Gas limit for sending L0 messages

    event SetGasLimit(uint128 gasLimit);

    error GasLimitInvalid();

    /// @notice Checks if the method with specified selector is supported by the connector
    /// @param selector - Selector of the method
    /// @return Is the method supported
    /// @dev This method is override for checking if the connector supports the lzReceive method
    function supportMethod(bytes4 selector) external pure override returns (bool) {
        return selector == this.lzReceive.selector;
    }

    /// @notice Quotes the fee for sending message to the specified chain
    /// @param _registryDst - Id of the chain to which the message should be sent
    /// @param _payload - Message that should be sent
    /// @return Fee that should be paid for sending the message in native chain currency
    function quote(uint256 _registryDst, bytes memory _payload) public view returns (uint256) {
        uint32 destination = uint32(customChainIds[_registryDst]);

        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(gasLimit, 0);

        MessagingFee memory fee = _quote(destination, _payload, options, false);

        return fee.nativeFee;
    }

    /// @param _endpoint - Address of the L0 endpoint contract
    /// @param _admin - Address of the admin, will be assigned as owner
    /// @param _operator - Address of the operator
    /// @param _registry - Address of the registry contract
    /// @param _gasLimit - Gas limit for sending L0 messages, can't be 0
    /// @dev _gasLimit 0 check performed in _setGasLimit function
    constructor(address _endpoint, address _admin, address _operator, address _registry, uint128 _gasLimit) OApp(_endpoint, _admin) BaseConnector(_admin, _operator, _registry) Ownable(_admin) {
        require(_endpoint != address(0), "Zero address check");

        _setGasLimit(_gasLimit);
    }

    /// @notice Set gas limit for sending messages
    /// @param _gasLimit - Gas limit for sending messages, can't be 0
    /// @dev _gasLimit 0 check performed in _setGasLimit function
    function setGasLimit(uint128 _gasLimit) external onlyOwner {
        _setGasLimit(_gasLimit);
    }

    /// @notice External function for sending message through L0 protocol
    /// @param _registryDst - Native id of the destination chain
    /// @param _payload - Payload to send
    function sendMessage(uint256 _registryDst, bytes calldata _payload) external payable onlySingleId {
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(gasLimit, 0);
        uint32 destination = uint32(customChainIds[_registryDst]);

        _lzSend(
            destination,
            _payload,
            options,
            MessagingFee(msg.value, 0),
            payable(msg.sender)
        );
    }

    /// @notice Receives message from L0 protocol
    /// @param _origin - Origin of the message
    /// @param _guid - Guid of the message
    /// @param _message - Message payload
    /// @param _executor - Executor of the message
    /// @param _extraData - Extra data of the message
    function lzReceive(
        Origin calldata _origin,
        bytes32 _guid,
        bytes calldata _message,
        address _executor,
        bytes calldata _extraData
    ) public payable override {
        // Ensures that only the endpoint can attempt to lzReceive() messages to this OApp.
        if (address(endpoint) != msg.sender) revert OnlyEndpoint(msg.sender);
        uint256 srcChainId = nativeChainIds[_origin.srcEid];

        bytes32 peer = router.getPeer(connectorId, srcChainId);
        // Ensure that the sender matches the expected peer for the source endpoint.
        if (peer != _origin.sender) revert OnlyPeer(_origin.srcEid, _origin.sender);

        // Call the internal OApp implementation of lzReceive.
        _lzReceive(_origin, _guid, _message, _executor, _extraData);
    }

    /// @notice Set gas limit for sending messages
    /// @param _gasLimit - Gas limit for sending messages, can't be 0
    function _setGasLimit(uint128 _gasLimit) private {
        if (_gasLimit == 0) revert GasLimitInvalid();

        gasLimit = _gasLimit;
        emit SetGasLimit(_gasLimit);
    }

    /// @notice Sends message through L0 protocol
    /// @param _dstEid - Id of the destination chain
    /// @param _message - Message payload
    /// @param _options - Options for sending message
    /// @param _fee - Fees for sending message
    /// @param _refundAddress - Address to refund excess fees
    function _lzSend(
        uint32 _dstEid,
        bytes memory _message,
        bytes memory _options,
        MessagingFee memory _fee,
        address _refundAddress
    ) internal override returns (MessagingReceipt memory receipt) {
        // @dev Push corresponding fees to the endpoint, any excess is sent back to the _refundAddress from the endpoint.
        uint256 messageValue = _payNative(_fee.nativeFee);
        if (_fee.lzTokenFee > 0) _payLzToken(_fee.lzTokenFee);

        uint256 srcChainId = nativeChainIds[uint256(_dstEid)];
        bytes32 peer = router.getPeer(connectorId, srcChainId);

        return endpoint.send{ value: messageValue }(
            MessagingParams(_dstEid, peer, _message, _options, _fee.lzTokenFee > 0),
            _refundAddress
        );
    }

    /// @notice Get peer address for a given emitter id
    /// @param _eid - Emitter id
    /// @return peer - Peer address
    /// @dev Will revert if peer is not found
    function _getPeerOrRevert(uint32 _eid) internal view override returns (bytes32) {
        uint256 srcChainId = nativeChainIds[uint256(_eid)];
        bytes32 peer = router.getPeer(connectorId, srcChainId);
        return peer;
    }

    /// @notice Receives message from L0 protocol
    /// @param payload - Message payload
    function _lzReceive(
        Origin calldata,
        bytes32,
        bytes calldata payload,
        address,  // Executor address as specified by the OApp.
        bytes calldata  // Any extra data or options to trigger on receipt.
    ) internal override {
        MessageLib.DecodedMessage memory decodedPayload = MessageLib.decodeMessage(payload);

        if (decodedPayload.messageType == MessageLib.MessageType.TYPE_SEND_REGISTER) {
            registry.registrySID(decodedPayload.sendMessage);
        } else if (decodedPayload.messageType == MessageLib.MessageType.TYPE_SEND_UPDATE) {
            registry.updateSID(decodedPayload.renewalMessage);
        }
    }
}
