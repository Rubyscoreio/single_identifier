// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IMailbox} from "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";
import {InterchainGasPaymaster} from "@hyperlane-xyz/core/contracts/hooks/igp/InterchainGasPaymaster.sol";
import {MessageLib} from "../lib/MessageLib.sol";
import {BaseConnector} from "./BaseConnector.sol";

contract HyperlaneConnector is Ownable, BaseConnector {

    IMailbox public mailbox;
    InterchainGasPaymaster public igp;
    uint128 public gasLimit;

    event SetMailbox(address indexed mailbox);
    event SetIgp(address indexed ipg);
    event SetGasLimit(uint128 gasLimit);

    error GasLimitInvalid();

    function quote(uint32 _registryDst, bytes memory /*_payload*/) public virtual view returns (uint256) {
        uint32 destination = uint32(customChainIds[_registryDst]);
        uint256 gasPayment = igp.quoteGasPayment(destination, gasLimit);

        return gasPayment;
    }

    function supportMethod(bytes4 selector) external pure override returns (bool) {
        return selector == this.handle.selector;
    }

    constructor(address _admin, address _operator, address _mailbox, address igp, address _registry, uint128 _gasLimit) BaseConnector(_admin, _operator, _registry) Ownable(_admin) {
        _setMailbox(_mailbox);
        _setGasLimit(_gasLimit);
        _setIgp(igp);
    }

    function handle(uint32 _origin, bytes32 _sender, bytes calldata _message) external {
        require(msg.sender == address(mailbox), "ChainRumble: caller is not mailbox");

        uint256 srcChainId = nativeChainIds[uint256(_origin)];
        bytes32 peer = router.getPeer(connectorId, srcChainId);

        require(_sender == peer, "ChainRumble: sender is not peer");

        MessageLib.DecodedMessage memory decodedPayload = MessageLib.decodeMessage(_message);

        if (decodedPayload.messageType == MessageLib.MessageType.TYPE_SEND_REGISTER) {
            registry.registrySID(decodedPayload.sendMessage);
        } else if (decodedPayload.messageType == MessageLib.MessageType.TYPE_SEND_UPDATE) {
            registry.updateSID(decodedPayload.renewalMessage);
        }
    }

    function sendMessage(uint256 _registryDst, bytes calldata _payload) external payable {
        uint32 destination = uint32(customChainIds[_registryDst]);
        bytes32 peer = router.getPeer(connectorId, _registryDst);

        IMailbox(mailbox).dispatch{value: msg.value}(destination, peer, _payload, "");
    }

    function setMailbox(address _mailbox) external onlyOwner {
        _setMailbox(_mailbox);
    }

    function setIgp(address _igp) external onlyOwner {
        _setIgp(_igp);
    }

    function setGasLimit(uint128 _gasLimit) external onlyOwner {
        _setGasLimit(_gasLimit);
    }

    function _setMailbox(address _mailbox) private {
        if (_mailbox == address(0)) revert AddressIsZero();

        mailbox = IMailbox(_mailbox);
        emit SetMailbox(_mailbox);
    }

    function _setIgp(address _igp) private {
        if (_igp == address(0)) revert AddressIsZero();

        igp = InterchainGasPaymaster(_igp);
        emit SetIgp(_igp);
    }

    function _setGasLimit(uint128 _gasLimit) private {
        if (_gasLimit == 0) revert GasLimitInvalid();

        gasLimit = _gasLimit;
        emit SetGasLimit(_gasLimit);
    }
}
