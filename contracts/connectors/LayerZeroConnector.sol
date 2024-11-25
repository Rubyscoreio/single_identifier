// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import {MessageLib} from "../lib/MessageLib.sol";
import {OApp, Origin, OAppCore, MessagingFee} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/OApp.sol";
import { MessagingParams, MessagingReceipt } from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import {BaseConnector} from "./BaseConnector.sol";
import {OptionsBuilder} from "@layerzerolabs/lz-evm-oapp-v2/contracts/oapp/libs/OptionsBuilder.sol";
import "hardhat/console.sol";

contract LayerZeroConnector is BaseConnector, OApp {
    using OptionsBuilder for bytes;

    uint128 public gasLimit;

    event SetGasLimit(uint128 gasLimit);

    error GasLimitInvalid();

    function supportMethod(bytes4 selector) external pure override returns (bool) {
        return selector == this.lzReceive.selector;
    }

    function quote(uint256 _registryDst, bytes memory _payload) public view returns (uint256) {
        uint32 destination = uint32(customChainIds[_registryDst]);

        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(gasLimit, 0);

        MessagingFee memory fee = _quote(destination, _payload, options, false);

        return fee.nativeFee;
    }

    constructor(address _endpoint, address _admin, address _operator, address _registry, uint128 _gasLimit) OApp(_endpoint, _admin) BaseConnector(_admin, _operator, _registry) Ownable(_admin) {
        require(_endpoint != address(0), "Zero address check");

        _setGasLimit(_gasLimit);
    }

    function setGasLimit(uint128 _gasLimit) external onlyOwner {
        _setGasLimit(_gasLimit);
    }

    function sendMessage(uint256 _registryDst, bytes calldata _payload) external payable {
        bytes memory options = OptionsBuilder.newOptions().addExecutorLzReceiveOption(gasLimit, 0);
        uint32 destination = uint32(customChainIds[_registryDst]);
        console.log("SEND Chains: ", _registryDst, destination);
        _lzSend(
            destination,
            _payload,
            options,
            MessagingFee(msg.value, 0),
            payable(msg.sender)
        );
    }

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
        console.log("Receive Chains: ", srcChainId, uint256(_origin.srcEid));
        bytes32 peer = router.getPeer(connectorId, srcChainId);
        console.log("RECEIVE MESSAGE", address(uint160(uint256(peer))), address(uint160(uint256(_origin.sender))));
        // Ensure that the sender matches the expected peer for the source endpoint.
        if (peer != _origin.sender) revert OnlyPeer(_origin.srcEid, _origin.sender);

        // Call the internal OApp implementation of lzReceive.
        _lzReceive(_origin, _guid, _message, _executor, _extraData);
    }

    function _setGasLimit(uint128 _gasLimit) private {
        if (_gasLimit == 0) revert GasLimitInvalid();

        gasLimit = _gasLimit;
        emit SetGasLimit(_gasLimit);
    }

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

    function _getPeerOrRevert(uint32 _eid) internal view override returns (bytes32) {
        uint256 srcChainId = nativeChainIds[uint256(_eid)];
        bytes32 peer = router.getPeer(connectorId, srcChainId);
        return peer;
    }

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
