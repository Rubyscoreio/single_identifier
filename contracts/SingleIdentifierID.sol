// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {EIP712, MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Emitter} from "./types/Structs.sol";

import {ISingleIdentifierRegistry} from "./interfaces/ISingleIdentifierRegistry.sol";
import {MessageLib} from "./lib/MessageLib.sol";
import {ISingleRouter} from "./interfaces/ISingleRouter.sol";
import {IConnector} from "./interfaces/IConnector.sol";
import {SingleRouter} from "./SingleRouter.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract SingleIdentifierID is AccessControl, EIP712 {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    string public constant NAME = "Rubyscore_Single_Identifier_Id";
    string public constant VERSION = "0.0.1";
    bytes32 private constant TYPE_HASH =
    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    uint256 public protocolFee;
    uint256 public protocolBalance;
    SingleRouter public router;

    mapping(bytes32 emitterId => Emitter emitter) public emitters;
    mapping(bytes32 emitterId => uint256 balance) public emittersBalances;

    event EmitterRegistered(bytes32 indexed emitterId, address indexed emitterAddress, uint256 registryChainId);
    event SentRegisterSIDMessage(bytes32 indexed schemaId, uint32 indexed protocolId, address indexed user, uint256 registryDst);
    event SentUpdateSIDMessage(bytes32 indexed id, uint32 indexed protocolId, address indexed user, uint256 registryDst);
    event Withdrawal(address indexed receiver, uint256 amount);
    event UpdateEmitter(bytes32 indexed emitterId, address indexed newEmitter);
    event SetProtocolFee(uint256 fee);
    event SetRouter(address indexed newRouter);

    error EmitterNotExists();
    error EmitterAlreadyExists();
    error DataIsEmpty();
    error SignatureInvalid();
    error WrongFeeAmount();
    error SenderNotEmitter();
    error AddressIsZero();
    error SIDNotValid();
    error SchemaIdInvalid();
    error ProtocolIdInvalid();
    error ExpirationDateInvalid();
    error ChainIdInvalid();

    constructor(uint256 _protocolFee, address _admin, address _operator, address _router) EIP712(NAME, VERSION) {
        if (_admin == address(0)) revert AddressIsZero();
        if (_operator == address(0)) revert AddressIsZero();

        protocolFee = _protocolFee;
        _setRouter(_router);

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(OPERATOR_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, _operator);
    }

    function registerSID(bytes32 _emitterId, uint32 _connectorId, bytes calldata _data, bytes calldata _signature, string calldata _metadata) external payable checkEmitter(_emitterId) {
        if (_data.length == 0) revert DataIsEmpty();
        if (_signature.length == 0) revert SignatureInvalid();

        Emitter storage emitter = emitters[_emitterId];

        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("RegisterParams(bytes32 schemaId,address user,bytes data,string metadata)"),
                    emitter.schemaId,
                    msg.sender,
                    keccak256(_data),
                    keccak256(abi.encodePacked(_metadata))
                )
            )
        );
        _checkRole(OPERATOR_ROLE, ECDSA.recover(digest, _signature));

        _sendRegisterSIDMessage(_emitterId, emitter.schemaId, _connectorId, emitter.fee, emitter.registryChainId, emitter.expirationDate, _data, _metadata);
    }

    function registerSIDWithEmitter(
        bytes32 _schemaId,
        uint32 _connectorId,
        uint64 _expirationDate,
        uint256 _fee,
        uint256 _registryChainId,
        address _emitterAddress,
        bytes calldata _data,
        string calldata _metadata,
        bytes calldata _signature
    ) external payable {
        bytes32 emitterId = registerEmitter(_schemaId, _registryChainId, _emitterAddress, _expirationDate, _fee, _data, _metadata, _signature);
        _sendRegisterSIDMessage(emitterId, _schemaId, _connectorId, _fee, _registryChainId, _expirationDate, _data, _metadata);
    }

    function updateSID(bytes32 _emitterId, uint32 _connectorId, bytes32 _sidId, uint64 _expirationDate, bytes calldata _data, string calldata _metadata, bytes memory _signature) external payable checkEmitter(_emitterId) {
        if (_expirationDate < block.timestamp) revert ExpirationDateInvalid();
        if (_data.length == 0) revert DataIsEmpty();
        if (_signature.length == 0) revert SignatureInvalid();
        if (_sidId == bytes32(0)) revert SIDNotValid();

        Emitter storage emitter = emitters[_emitterId];

        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("UpdateParams(bytes32 sidId,uint64 expirationDate,bytes data,string metadata)"),
                    _sidId,
                    _expirationDate,
                    keccak256(_data),
                    keccak256(abi.encodePacked(_metadata))
                )
            )
        );
        _checkRole(OPERATOR_ROLE, ECDSA.recover(digest, _signature));

        _sendUpdateSIDMessage(emitter.emitterId, _connectorId, emitter.fee, emitter.registryChainId, _sidId, _expirationDate, _data, _metadata);
    }

    function updateEmitter(bytes32 _emitterId, address _newEmitter) external onlyRole(OPERATOR_ROLE) checkEmitter(_emitterId) {
        if (_newEmitter == address(0)) revert AddressIsZero();

        emitters[_emitterId].owner = _newEmitter;

        emit UpdateEmitter(_emitterId, _newEmitter);
    }

    function updateFee(bytes32 _emitterId, uint256 _fee) external checkEmitter(_emitterId) {
        Emitter storage emitter = emitters[_emitterId];

        if (msg.sender != emitter.owner) revert SenderNotEmitter();


        emitters[_emitterId].fee = _fee;
    }

    function withdraw(bytes32 _emitterId, address payable _receiver) external checkEmitter(_emitterId) {
        if (_receiver == address(0)) revert AddressIsZero();

        Emitter memory emitter = emitters[_emitterId];
        if (msg.sender != emitter.owner) revert SenderNotEmitter();

        uint256 amount = emittersBalances[_emitterId];

        (bool sent,) = _receiver.call{value: amount}("");
        require(sent, "Failed to send Ether");

        emittersBalances[_emitterId] = 0;

        emit Withdrawal(_receiver, amount);
    }

    function withdraw(address payable _receiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_receiver == address(0)) revert AddressIsZero();

        uint256 amount = protocolBalance;
        (bool sent,) = _receiver.call{value: amount}("");
        require(sent, "Failed to send Ether");
        protocolBalance = 0;

        emit Withdrawal(_receiver, amount);
    }

    function setProtocolFee(uint256 _fee) external onlyRole(OPERATOR_ROLE) {
        _setProtocolFee(_fee);
    }

    function setRouter(address _router) external onlyRole(OPERATOR_ROLE) {
        _setRouter(_router);
        emit SetRouter(_router);
    }

    function registerEmitter(
        bytes32 _schemaId,
        uint256 _registryChainId,
        address _emitterAddress,
        uint64 _expirationDate,
        uint256 _fee,
        bytes calldata _data,
        string calldata _metadata,
        bytes calldata _signature
    ) public returns (bytes32) {
        if (_schemaId == bytes32(0)) revert SchemaIdInvalid();
        if (_expirationDate < block.timestamp) revert ExpirationDateInvalid();
        if (_registryChainId == uint256(0)) revert ChainIdInvalid();
        if (_emitterAddress == address(0)) revert AddressIsZero();
        if (_data.length == 0) revert DataIsEmpty();
        if (_signature.length == 0) revert SignatureInvalid();

        bytes32 emitterId = _generateEmitterId(_schemaId, _registryChainId);
        if (emitters[emitterId].emitterId != bytes32(0)) revert EmitterAlreadyExists();

        bytes32 registerDigest = _hashTypedDataV4WithoutDomain(
            keccak256(
                abi.encode(
                    keccak256("SendWithRegistryParams(bytes32 schemaId,address emitterAddress,uint256 registryChainId,address user,bytes data,string metadata)"),
                    _schemaId,
                    _emitterAddress,
                    _registryChainId,
                    msg.sender,
                    keccak256(_data),
                    keccak256(abi.encodePacked(_metadata))
                )
            )
        );

        _checkRole(OPERATOR_ROLE, ECDSA.recover(registerDigest, _signature));

        emitters[emitterId] = Emitter(
            emitterId,
            _schemaId,
            _expirationDate,
            _fee,
            _registryChainId,
            _emitterAddress
        );

        emit EmitterRegistered(emitterId, _emitterAddress, _registryChainId);

        return emitterId;
    }

    function _generateEmitterId(bytes32 _schemaId, uint256 _registryChainId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_schemaId, _registryChainId));
    }

    function _setRouter(address _router) private {
        if (_router == address(0)) revert AddressIsZero();
        router = SingleRouter(_router);
    }

    function _setProtocolFee(uint256 _fee) private {
        protocolFee = _fee;
        emit SetProtocolFee(_fee);
    }

    function _hashTypedDataV4WithoutDomain(bytes32 structHash) private pure returns (bytes32) {
        bytes32 hashedName = keccak256(bytes(NAME));
        bytes32 hashedVersion = keccak256(bytes(VERSION));

        bytes32 domainSeparator = keccak256(abi.encode(TYPE_HASH, hashedName, hashedVersion, uint256(0), address(0)));
        return MessageHashUtils.toTypedDataHash(domainSeparator, structHash);
    }

    function _sendRegisterSIDMessage(bytes32 _emitterId, bytes32 _schemaId, uint32 _connectorId, uint256 _fee, uint256 _registryChainId, uint64 _expirationDate, bytes calldata _data, string calldata _metadata) internal {
        uint256 totalAmount = _fee + protocolFee;
        if (msg.value < totalAmount) revert WrongFeeAmount();

        emittersBalances[_emitterId] = _fee;
        protocolBalance += protocolFee;

        IConnector connector = router.getRoute(_connectorId, _registryChainId);
        bytes memory payload = MessageLib.encodeMessage(MessageLib.SendMessage(_schemaId, msg.sender, _expirationDate, _data, _metadata));

        uint256 fee = connector.quote(_registryChainId, payload);
        connector.sendMessage{ value: fee }(_registryChainId, payload);

        emit SentRegisterSIDMessage(_schemaId, _connectorId, msg.sender, _registryChainId);
    }

    function _sendUpdateSIDMessage(bytes32 _emitterId, uint32 _connectorId, uint256 _fee, uint256 _registryChainId, bytes32 _sidId, uint64 _expirationDate, bytes calldata _data, string calldata _metadata) internal {
        uint256 totalAmount = _fee + protocolFee;
        if (msg.value < totalAmount) revert WrongFeeAmount();

        emittersBalances[_emitterId] = _fee;
        protocolBalance += protocolFee;

        IConnector connector = router.getRoute(_connectorId, _registryChainId);
        bytes memory payload = MessageLib.encodeMessage(MessageLib.UpdateMessage(_sidId, _expirationDate, _data, _metadata));

        uint256 fee = connector.quote(_registryChainId, payload);
        connector.sendMessage{ value: fee }(_registryChainId, payload);

        emit SentUpdateSIDMessage(_sidId, _connectorId, msg.sender, _registryChainId);
    }

    modifier checkEmitter(bytes32 _emitterId) {
        if (emitters[_emitterId].emitterId == bytes32(0)) revert EmitterNotExists();
        _;
    }
}
