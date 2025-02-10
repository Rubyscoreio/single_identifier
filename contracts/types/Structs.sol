// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

    /// @notice SID data in registry
    /// @param SIDId - Id of that SID
    /// @param schemaId - Id of schema used in this SID
    /// @param expirationDate - Timestamp when SID expires
    /// @param revocationDate - Timestamp when SID was revoked, 0 if not revoked
    /// @param revoked - Indicates is this SID revoked
    /// @param user - Address to which this SID is assigned
    /// @param data - SIDs data
    /// @param metadata - SIDs metadata
    struct SID {
        bytes32 SIDId;
        bytes32 schemaId;
        uint64 expirationDate;
        uint64 revocationDate;
        bool revoked;
        address user;
        bytes data;
        string metadata;
    }

    /// @notice Schema in storage
    /// @dev Used for storing schemas
    /// @param schemaId - Id of schema
    /// @param name - Schema name
    /// @param description - Schema description
    /// @param schema - Schema data
    /// @param emitter - Address of the owner of the emitter that registered this schema
    struct SIDSchema {
        bytes32 schemaId;
        string name;
        string description;
        string schema;
        address emitter;
    }

    /// @notice Schema params
    /// @dev Used for registering new schema
    /// @param name - Schema name
    /// @param description - Schema description
    /// @param schema - Schema data
    /// @param emitter - Address of the owner of the emitter that registered this schema
    struct SIDSchemaParams {
        string name;
        string description;
        string schema;
        address emitter;
    }

    /// @notice Emitter data in registry
    /// @param emitterId - Id of that emitter
    /// @param schemaId - Id of schema used by that emitter
    /// @param expirationDate - Timestamp when emitter becomes invalid
    /// @param fee - Fees for creating and updating SIDs
    /// @param registryChainId - Id of the chain where the registry is deployed
    /// @param owner - Address that can act as that emitter
    struct Emitter {
        bytes32 emitterId;
        bytes32 schemaId;
        uint64 expirationDate;
        uint256 fee;
        uint256 registryChainId;
        address owner;
    }

    /// @dev deprecated
    struct Destination {
        uint256 chainId;
        uint32 layerZero;
        uint32 hyperlane;
    }

    /// @dev deprecated
    struct Peers {
        bytes32 sender;
        bytes32 receiver;
    }
