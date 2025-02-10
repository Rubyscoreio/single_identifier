// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {Emitter} from "./types/Structs.sol";

import {ISingleIdentifierRegistry} from "./interfaces/ISingleIdentifierRegistry.sol";
import {MessageLib} from "./lib/MessageLib.sol";
import {ISingleRouter} from "./interfaces/ISingleRouter.sol";
import {IConnector} from "./interfaces/IConnector.sol";
import {SingleRouter} from "./SingleRouter.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @title SingleIdentifierID
/// @notice The main contract of the Single Identifier protocol, responsible for controlling emitters, fees, and router
contract SingleIdentifierID is AccessControlUpgradeable, EIP712Upgradeable, UUPSUpgradeable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    string public constant NAME = "Rubyscore_Single_Identifier_Id";
    string public constant VERSION = "0.0.1";
    bytes32 private constant TYPE_HASH =
    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    // Upgradeable storage
    // v0.0.1
    /// @notice Fee that charged by protocol for creating and updating SIDs
    uint256 public protocolFee;
    /// @notice Sum of all charged fees in contract balance
    uint256 public protocolBalance;
    /// @notice Address of actual router contract
    SingleRouter public router;

    /// @notice Emitters data
    mapping(bytes32 emitterId => Emitter emitter) public emitters;
    /// @notice Sum of all fees charged by emitter in contract balance
    mapping(bytes32 emitterId => uint256 balance) public emittersBalances;
    // Upgradeable storage end

    event EmitterRegistered(bytes32 indexed emitterId, address indexed emitterAddress, uint256 registryChainId);
    event SentRegisterSIDMessage(bytes32 indexed schemaId, uint32 indexed protocolId, address indexed user, uint256 registryDst);
    event SentUpdateSIDMessage(bytes32 indexed id, uint32 indexed protocolId, address indexed user, uint256 registryDst);
    event Withdrawal(address indexed receiver, uint256 amount);
    event UpdateEmitter(bytes32 indexed emitterId, address indexed newEmitter);
    event SetProtocolFee(uint256 fee);
    event SetRouter(address indexed newRouter);
    event SetEmitterBalance(bytes32 indexed emitterId, uint256 newBalance);

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

    /// @notice Checks if the emitter with specified id exists
    /// @param _emitterId - Id that should be checked
    modifier checkEmitter(bytes32 _emitterId) {
        if (emitters[_emitterId].emitterId == bytes32(0)) revert EmitterNotExists();
        _;
    }

    /// @notice Initializes upgradeable contract
    /// @param _protocolFee - Protocol fee
    /// @param _admin - Admin address, cant be 0x0
    /// @param _operator - Operator address, can't be 0x0
    /// @param _router - Router address, can't be 0x0
    /// @dev _router address zero check is performed in the _setRouter function
    function initialize(
        uint256 _protocolFee,
        address _admin,
        address _operator,
        address _router
    ) external initializer {
        if (_admin == address(0)) revert AddressIsZero();
        if (_operator == address(0)) revert AddressIsZero();

        protocolFee = _protocolFee;
        _setRouter(_router);

        __AccessControl_init();
        __EIP712_init(NAME, VERSION);
        __UUPSUpgradeable_init();

        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(OPERATOR_ROLE, _operator);
    }

    /// @notice Registers an emitter and sends registering message for SID with the new emitter
    /// @param _schemaId - Id of schema that would be used by the emitter
    /// @param _connectorId - Id of connector that should be used for sending registering message
    /// @param _expirationDate - Timestamp when emitter expires
    /// @param _fee - Fee that would be collected by the emitter for registering and updating SID
    /// @param _registryChainId - Id of the chain with registry
    /// @param _emitterAddress - Address of the emitters owner
    /// @param _data - Data that would be sent with registering message
    /// @param _metadata - Metadata that would be sent with registering message
    /// @param _signature - Operators signature with RegistryEmitterParams
    /// @param _registerEmitterSignature - Operators signature with RegisterParams
    function registerSIDWithEmitter(
        bytes32 _schemaId,
        uint32 _connectorId,
        uint64 _expirationDate,
        uint256 _fee,
        uint256 _registryChainId,
        address _emitterAddress,
        bytes calldata _data,
        string calldata _metadata,
        bytes calldata _signature,
        bytes calldata _registerEmitterSignature
    ) external payable {
        bytes32 emitterId = registerEmitter(
            _schemaId,
            _registryChainId,
            _emitterAddress,
            _expirationDate,
            _fee,
            _signature
        );

        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("RegisterParams(bytes32 schemaId,address user,bytes data,string metadata)"),
                    _schemaId,
                    msg.sender,
                    keccak256(_data),
                    keccak256(abi.encodePacked(_metadata))
                )
            )
        );

        if (_emitterAddress != ECDSA.recover(digest, _registerEmitterSignature)) revert SignatureInvalid();

        _sendRegisterSIDMessage(
            emitterId,
            _schemaId,
            _connectorId,
            _fee,
            _registryChainId,
            _expirationDate,
            _data,
            _metadata
        );
    }

    /// @notice Checks signature and sends SID registering message
    /// @param _emitterId - Id of emitter that should be used for registering SID
    /// @param _connectorId - Id of connector that should be used for sending registering message
    /// @param _data - Data that would be sent with registering message
    /// @param _signature - Operators signature with RegisterParams
    /// @param _metadata - Metadata that would be sent with registering message
    function registerSID(
        bytes32 _emitterId,
        uint32 _connectorId,
        bytes calldata _data,
        bytes calldata _signature,
        string calldata _metadata
    ) external payable checkEmitter(_emitterId) {
        if (_data.length == 0) revert DataIsEmpty();
        if (_signature.length != 65) revert SignatureInvalid();

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

        if (emitter.owner != ECDSA.recover(digest, _signature)) revert SignatureInvalid();

        _sendRegisterSIDMessage(
            _emitterId,
            emitter.schemaId,
            _connectorId,
            emitter.fee,
            emitter.registryChainId,
            emitter.expirationDate,
            _data,
            _metadata
        );
    }

    /// @notice Checks signature and sends SID update message
    /// @param _emitterId - Id of emitter that should be used for updating SID
    /// @param _connectorId - Id of connector that should be used for sending updating message
    /// @param _sidId - Id of SID that should be updated
    /// @param _expirationDate - Timestamp when SID expires
    /// @param _data - Data that would be sent with updating message
    /// @param _metadata - Metadata that would be sent with updating message
    /// @param _signature - Operators signature with RegistryEmitterParams
    function updateSID(
        bytes32 _emitterId,
        uint32 _connectorId,
        bytes32 _sidId,
        uint64 _expirationDate,
        bytes calldata _data,
        string calldata _metadata,
        bytes memory _signature
    ) external payable checkEmitter(_emitterId) {
        if (_expirationDate < block.timestamp) revert ExpirationDateInvalid();
        if (_data.length == 0) revert DataIsEmpty();
        if (_signature.length != 65) revert SignatureInvalid();
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

        if (emitter.owner != ECDSA.recover(digest, _signature)) revert SignatureInvalid();

        _sendUpdateSIDMessage(
            emitter.emitterId,
            _connectorId,
            emitter.fee,
            emitter.registryChainId,
            _sidId,
            _expirationDate,
            _data,
            _metadata
        );
    }

    /// @notice Updates emitter owner address
    /// @param _emitterId - Id of emitter that should be updated
    /// @param _newEmitter - New emitter owner address, can't be 0x0
    function updateEmitter(bytes32 _emitterId, address _newEmitter) external onlyRole(OPERATOR_ROLE) checkEmitter(_emitterId) {
        if (_newEmitter == address(0)) revert AddressIsZero();

        emitters[_emitterId].owner = _newEmitter;

        emit UpdateEmitter(_emitterId, _newEmitter);
    }

    /// @notice Updates fee for emitter
    /// @param _emitterId - Id of emitter that should be updated
    /// @param _fee - New fee for emitter
    function updateFee(bytes32 _emitterId, uint256 _fee) external checkEmitter(_emitterId) {
        Emitter storage emitter = emitters[_emitterId];

        if (msg.sender != emitter.owner) revert SenderNotEmitter();

        emitters[_emitterId].fee = _fee;
    }

    /// @notice Sends fees collected by emitter to specified address
    /// @param _emitterId - Id of emitter whose fees should be withdrawn
    /// @param _receiver - Address where fees should be sent, can't be 0x0
    function withdraw(bytes32 _emitterId, address payable _receiver) external checkEmitter(_emitterId) {
        if (_receiver == address(0)) revert AddressIsZero();

        Emitter memory emitter = emitters[_emitterId];
        if (msg.sender != emitter.owner) revert SenderNotEmitter();

        uint256 amount = emittersBalances[_emitterId];
        emittersBalances[_emitterId] = 0;

        (bool sent,) = _receiver.call{value: amount}("");
        require(sent, "Failed to send Ether");

        emit Withdrawal(_receiver, amount);
    }

    /// @notice Sends collected protocol fees to specified address
    /// @param _receiver - Address where fees should be sent, can't be 0x0
    function withdraw(address payable _receiver) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_receiver == address(0)) revert AddressIsZero();

        uint256 amount = protocolBalance;
        protocolBalance = 0;

        (bool sent,) = _receiver.call{value: amount}("");
        require(sent, "Failed to send Ether");

        emit Withdrawal(_receiver, amount);
    }

    /// @notice Sets protocol fee
    /// @param _fee - New protocol fee
    function setProtocolFee(uint256 _fee) external onlyRole(OPERATOR_ROLE) {
        _setProtocolFee(_fee);
    }

    /// @notice Sets router address
    /// @param _router - New router address, can't be 0x0
    /// @dev _router address zero check is performed in the _setRouter function
    function setRouter(address _router) external onlyRole(OPERATOR_ROLE) {
        _setRouter(_router);
        emit SetRouter(_router);
    }

    /// @notice Sets router address. It should be used ONLY as a last resort to eliminate the consequences of errors.
    /// @param _emitterId - Id of the emitter
    /// @param _balance - New balance
    function setEmitterBalance(bytes32 _emitterId, uint256 _balance) external onlyRole(DEFAULT_ADMIN_ROLE) checkEmitter(_emitterId) {
        emittersBalances[_emitterId] = _balance;
        emit SetEmitterBalance(_emitterId, _balance);
    }

    /// @notice Registers new emitter
    /// @param _schemaId - Id of schema that would be used by the emitter
    /// @param _registryChainId - Id of the chain with registry
    /// @param _emitterAddress - Address of the emitters owner
    /// @param _expirationDate - Timestamp when emitter expires
    /// @param _fee - Fee that would be collected by the emitter for registering and updating SID
    /// @param _signature - Operators signature with RegistryEmitterParams
    /// @return Id of the newly created emitter
    function registerEmitter(
        bytes32 _schemaId,
        uint256 _registryChainId,
        address _emitterAddress,
        uint64 _expirationDate,
        uint256 _fee,
        bytes calldata _signature
    ) public returns (bytes32) {
        if (_schemaId == bytes32(0)) revert SchemaIdInvalid();
        if (_expirationDate <= block.timestamp) revert ExpirationDateInvalid();
        if (_registryChainId == uint256(0)) revert ChainIdInvalid();
        if (_emitterAddress == address(0)) revert AddressIsZero();
        if (_signature.length == 0) revert SignatureInvalid();

        bytes32 emitterId = _generateEmitterId(_schemaId, _registryChainId);
        if (emitters[emitterId].emitterId != bytes32(0)) revert EmitterAlreadyExists();

        bytes32 registerDigest = _hashTypedDataV4WithoutDomain(
            keccak256(
                abi.encode(
                    keccak256("RegistryEmitterParams(bytes32 schemaId,address emitterAddress,uint256 registryChainId,uint256 fee,uint64 expirationDate)"),
                    _schemaId,
                    _emitterAddress,
                    _registryChainId,
                    _fee,
                    _expirationDate
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

    /// @dev limit upgrade to only operator
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(OPERATOR_ROLE) {}

    /// @notice Generates emitter id
    /// @param _schemaId - Id of schema that is used by emitter
    /// @param _registryChainId - Id of the chain with the registry
    /// @return Generated emitter id
    function _generateEmitterId(bytes32 _schemaId, uint256 _registryChainId) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_schemaId, _registryChainId));
    }

    /// @notice Sends a register SID message to the registry
    /// @param _emitterId - Id of emitter that should be used for registering SID
    /// @param _schemaId - Id of schema that should
    /// @param _connectorId - Id of connector that should be used for sending registering message
    /// @param _fee - Fee that would be added to emitter balance
    /// @param _registryChainId - Id of the chain with registry
    /// @param _expirationDate - Timestamp when SID expires
    /// @param _data - Data that would be sent with registering message
    /// @param _metadata - Metadata that would be sent with registering message
    function _sendRegisterSIDMessage(
        bytes32 _emitterId,
        bytes32 _schemaId,
        uint32 _connectorId,
        uint256 _fee,
        uint256 _registryChainId,
        uint64 _expirationDate,
        bytes calldata _data,
        string calldata _metadata
    ) internal {
        emittersBalances[_emitterId] += _fee;
        protocolBalance += protocolFee;

        IConnector connector = router.getRoute(_connectorId, _registryChainId);
        bytes memory payload = MessageLib.encodeMessage(
            MessageLib.SendMessage(
                _schemaId,
                msg.sender,
                _expirationDate,
                _data,
                _metadata
            )
        );

        uint256 quote = connector.quote(_registryChainId, payload);

        uint256 totalFeeAmount = _fee + protocolFee + quote;
        if (msg.value < totalFeeAmount) revert WrongFeeAmount();

        connector.sendMessage{value: quote}(_registryChainId, payload);

        emit SentRegisterSIDMessage(_schemaId, _connectorId, msg.sender, _registryChainId);
    }

    /// @notice Sends an update SID message to the registry
    /// @param _emitterId - Id of emitter that should be used for updating SID
    /// @param _connectorId - Id of connector that should be used for sending updating message
    /// @param _fee - Fee that would be added to emitter balance
    /// @param _registryChainId - Id of the chain with registry
    /// @param _sidId - Id of SID that should be updated
    /// @param _expirationDate - Timestamp when SID expires
    /// @param _data - Data that would be sent with updating message
    /// @param _metadata - Metadata that would be sent with updating message
    function _sendUpdateSIDMessage(
        bytes32 _emitterId,
        uint32 _connectorId,
        uint256 _fee,
        uint256 _registryChainId,
        bytes32 _sidId,
        uint64 _expirationDate,
        bytes calldata _data,
        string calldata _metadata
    ) internal {
        emittersBalances[_emitterId] += _fee;
        protocolBalance += protocolFee;

        IConnector connector = router.getRoute(_connectorId, _registryChainId);
        bytes memory payload = MessageLib.encodeMessage(
            MessageLib.UpdateMessage(
                _sidId,
                _expirationDate,
                _data,
                _metadata
            )
        );

        uint256 quote = connector.quote(_registryChainId, payload);

        uint256 totalFeeAmount = _fee + protocolFee + quote;
        if (msg.value < totalFeeAmount) revert WrongFeeAmount();

        connector.sendMessage{value: quote}(_registryChainId, payload);

        emit SentUpdateSIDMessage(_sidId, _connectorId, msg.sender, _registryChainId);
    }

    /// @notice Sets router address
    /// @param _router - New router address, can't be 0x0
    function _setRouter(address _router) private {
        if (_router == address(0)) revert AddressIsZero();
        router = SingleRouter(_router);
    }

    /// @notice Sets protocol fee
    /// @param _fee - New protocol fee
    function _setProtocolFee(uint256 _fee) private {
        protocolFee = _fee;
        emit SetProtocolFee(_fee);
    }

    /// @notice Calculates domain separator for EIP712 hash from only name and version
    /// @param structHash - Hash of the struct that would be hashed
    /// @return Struct hash hashed with domain separator
    function _hashTypedDataV4WithoutDomain(bytes32 structHash) private pure returns (bytes32) {
        bytes32 hashedName = keccak256(bytes(NAME));
        bytes32 hashedVersion = keccak256(bytes(VERSION));

        bytes32 domainSeparator = keccak256(abi.encode(TYPE_HASH, hashedName, hashedVersion, uint256(0), address(0)));
        return MessageHashUtils.toTypedDataHash(domainSeparator, structHash);
    }
}
