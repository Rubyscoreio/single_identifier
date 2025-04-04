// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

import {SIDSchemaParams, SIDSchema, SID} from "../types/Structs.sol";
import {MessageLib} from "../lib/MessageLib.sol";

interface ISingleIdentifierRegistry {

    /// @notice Registry SID from received message
    /// @param _payload - Received message
    /// @dev Function is a cross-chain endpoint for registering SID
    function registrySID(MessageLib.SendMessage memory _payload) external;

    /// @notice Update SID from received message
    /// @param _payload - Received message
    /// @dev Function is a cross-chain endpoint for updating SID
    function updateSID(MessageLib.UpdateMessage memory _payload) external;

    /// @notice Registers new schema
    /// @param _schema - Schema data
    /// @param _signature - Operators signature with SchemaRegistryParams
    function schemaRegistry(SIDSchemaParams calldata _schema, bytes calldata _signature) external;

    /// @notice Update emitter address for schema by schema id
    /// @param _schemaId - Id of schema that should be updated
    /// @param _emitter - New emitter address
    function updateSchemaEmitter(bytes32 _schemaId, address _emitter) external;

    /// @notice Revoke SID by SID id
    /// @param _passportId - Id of SID that should be revoked
    function revoke(bytes32 _passportId) external;
}
