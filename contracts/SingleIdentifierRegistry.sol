// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/EIP712Upgradeable.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {SID, SIDSchema, SIDSchemaParams} from "./types/Structs.sol";
import {ISingleIdentifierRegistry} from "./interfaces/ISingleIdentifierRegistry.sol";
import {MessageLib} from "./lib/MessageLib.sol";
import {SingleRouter} from "./SingleRouter.sol";
import {IConnector} from "./interfaces/IConnector.sol";

/// @title SingleIdentifierRegistry
/// @notice Registry, that contains Emitters schemas and SIDs
contract SingleIdentifierRegistry is ISingleIdentifierRegistry, EIP712Upgradeable, AccessControlUpgradeable, UUPSUpgradeable {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    string public constant NAME = "Rubyscore_Single_Identifier_Registry";
    string public constant VERSION = "0.0.1";

    // Upgradeable storage
    // v0.0.1
    SingleRouter public router;/// @notice Address of actual router contract

    mapping(bytes32 schemaId => SIDSchema schema) public schemas;   /// @notice Schemas data
    mapping(address emitter => bytes32 schemaId) public schemaIds;  /// @notice Schemas assigned to emitters
    mapping(bytes32 id => SID sid) public singleIdentifierData;     /// @notice SIDs data

    uint256 public sidCounter;      /// @notice SID counter
    uint256 public emitterCounter;  /// @notice Emitter counter
    // Upgradeable storage end

    event SchemaRegistered(bytes32 indexed schemaId, address indexed emitter);
    event EmitterUpdated(bytes32 indexed schemaId, address indexed newEmitterAddress);
    event EmitterRevoked(bytes32 indexed schemaId, address indexed emitter);
    event SIDRegistered(bytes32 indexed SIDId, address indexed user);
    event SIDRevoked(bytes32 indexed SIDId, address indexed user);
    event SIDUpdated(bytes32 indexed SIDId);
    event SetRouter(address indexed router);

    error SchemaNameMissing();
    error SchemaStringMissing();
    error SchemaNotExist();
    error EmitterInvalid();
    error SchemaAlreadyExists();
    error SIDAlreadyExists();
    error SIDNotExists();
    error SignatureInvalid();
    error OnlyEmitter();
    error UnknownSelector();
    error MethodNotFound(bytes data);
    error AddressIsZero();
    error SenderIsNotPeer(address sender);

    /// @notice Initializes upgradeable contract
    /// @param _operator - Operator address, can't be 0x0
    function initialize(address _operator) external initializer {
        __EIP712_init(NAME, VERSION);
        __AccessControl_init();
        __UUPSUpgradeable_init();

        if (_operator == address(0)) revert AddressIsZero();

        _grantRole(OPERATOR_ROLE, msg.sender);
        _grantRole(OPERATOR_ROLE, _operator);
    }

    /// @notice Registers new schema
    /// @param _schema - Schema data
    /// @param _signature - Operators signature with SchemaRegistryParams
    function schemaRegistry(SIDSchemaParams calldata _schema, bytes calldata _signature) external {
        if (bytes(_schema.name).length == 0) revert SchemaNameMissing();
        if (bytes(_schema.schema).length == 0) revert SchemaStringMissing();
        if (_signature.length == 0) revert SignatureInvalid();

        bytes32 schemaId = _generateSchemaId(msg.sender, _schema.schema);
        if (schemas[schemaId].schemaId != bytes32(0)) revert SchemaAlreadyExists();

        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("SchemaRegistryParams(string name,string description,string schema,address emitter)"),
                    keccak256(abi.encodePacked(_schema.name)),
                    keccak256(abi.encodePacked(_schema.description)),
                    keccak256(abi.encodePacked(_schema.schema)),
                    _schema.emitter
                )
            )
        );
        _checkRole(OPERATOR_ROLE, ECDSA.recover(digest, _signature));

        schemaIds[msg.sender] = schemaId;
        schemas[schemaId] = SIDSchema(
        schemaId,
            _schema.name,
            _schema.description,
            _schema.schema,
            _schema.emitter
        );
        emitterCounter++;

        emit SchemaRegistered(schemaId, msg.sender);
    }

    /// @notice Update emitter address for schema by schema id
    /// @param _schemaId - Id of schema that should be updated
    /// @param _emitter - New emitter address
    function updateSchemaEmitter(bytes32 _schemaId, address _emitter) external onlyRole(OPERATOR_ROLE) {
        SIDSchema storage schema = schemas[_schemaId];
        if (schema.schemaId == bytes32(0)) revert SchemaNotExist();
        if (_emitter == address(0)) revert EmitterInvalid();

        schemaIds[schema.emitter] = bytes32(0);
        schemaIds[_emitter] = _schemaId;
        schema.emitter = _emitter;

        emit EmitterUpdated(_schemaId, _emitter);
    }

    /// @notice Registry SID from received message
    /// @param _payload - Received message
    /// @dev Function is a cross-chain endpoint for registering SID
    function registrySID(MessageLib.SendMessage memory _payload) external onlyConnector {
        SIDSchema memory schema = schemas[_payload.schemaId];
        if (schema.schemaId == bytes32(0)) revert SchemaNotExist();

        bytes32 sidId = _generateSIDId(_payload.schemaId, _payload.user);

        if (singleIdentifierData[sidId].SIDId != bytes32(0)) revert SIDAlreadyExists();

        singleIdentifierData[sidId] = SID(
            bytes32(sidId),
            bytes32(_payload.schemaId),
            uint64(_payload.expirationDate),
            uint64(0),
            bool(false),
            address(_payload.user),
            bytes(_payload.data),
            string(_payload.metadata)
        );

        sidCounter++;

        emit SIDRegistered(sidId, _payload.user);
    }

    /// @notice Update SID from received message
    /// @param _payload - Received message
    /// @dev Function is a cross-chain endpoint for updating SID
    function updateSID(MessageLib.UpdateMessage memory _payload) external onlyConnector {

        SID storage sid = singleIdentifierData[_payload.id];
        if (sid.SIDId == bytes32(0)) revert SIDNotExists();

        if (_payload.expirationDate != uint64(0)) {
            sid.expirationDate = _payload.expirationDate;
        }

        if (_payload.data.length != 0) {
            sid.data = _payload.data;
        }

        if (bytes(_payload.metadata).length != 0) {
            sid.metadata = _payload.metadata;
        }

        emit SIDUpdated(_payload.id);
    }

    /// @notice Sets new router address
    /// @param _router - New router address, can't be zero address
    function setRouter(address _router) external onlyRole(OPERATOR_ROLE) {
        if (_router == address(0)) revert AddressIsZero();

        router = SingleRouter(_router);
        emit SetRouter(_router);
    }

    /// @dev override for disabling authorised upgrades
    function _authorizeUpgrade(address newImplementation) internal override onlyRole(OPERATOR_ROLE) {}

    /// @notice Generate schema id from emitter and schema
    /// @param _emitter - Address of emitter
    /// @param _schema - Schema in string format
    /// @return schemaId - Generated schema id
    function _generateSchemaId(address _emitter, string calldata _schema) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_emitter, _schema));
    }

    /// @notice Revoke SID by SID id
    /// @param _sidId - Id of SID that should be revoked
    function revoke(bytes32 _sidId) public {
        SID storage sid = singleIdentifierData[_sidId];
        if (sid.SIDId == bytes32(0)) revert SIDNotExists();

        SIDSchema memory schema = schemas[sid.schemaId];
        if (schema.emitter != msg.sender) revert OnlyEmitter();

        sid.revocationDate = uint64(block.timestamp);
        sid.revoked = true;

        emit SIDRevoked(_sidId, sid.user);
    }

    /// @notice Generate SID id from schema id and user address
    /// @param _schemaId - Id of schema
    /// @param _userAddress - Address for which SID id should be generated
    /// @return sidId - Generated SID id
    function _generateSIDId(bytes32 _schemaId, address _userAddress) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_schemaId, _userAddress));
    }

    /// @notice Ensures that message sender is a valid connector
    modifier onlyConnector() {
        uint32 connectorId = IConnector(msg.sender).connectorId();
        if (!router.isAvailablePeer(block.chainid, connectorId, msg.sender)) revert SenderIsNotPeer(msg.sender);
        _;
    }
}
