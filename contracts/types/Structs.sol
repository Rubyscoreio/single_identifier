// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

    /// @notice SID data in registry
    struct SID {
        bytes32 SIDId;          /// @notice Id of that SID
        bytes32 schemaId;       /// @notice Id of schema used in this SID
        uint64 expirationDate;  /// @notice Timestamp when SID expires
        uint64 revocationDate;  /// @notice Timestamp when SID was revoked, 0 if not revoked
        bool revoked;           /// @notice Indicates is this SID revoked
        address user;           /// @notice Address to which this SID is assigned
        bytes data;             /// @notice SIDs data
        string metadata;        /// @notice SIDs metadata
    }

    /// @notice Schema in storage
    /// @dev Used for storing schemas
    struct SIDSchema {
        bytes32 schemaId;
        string name;        /// @notice Schema name
        string description; /// @notice Schema description
        string schema;      /// @notice Schema data
        address emitter;    /// @notice Address of the owner of the emitter that registered this schema
    }

    /// @notice Schema params
    /// @dev Used for registering new schema
    struct SIDSchemaParams {
        string name;        /// @notice Schema name
        string description; /// @notice Schema description
        string schema;      /// @notice Schema data
        address emitter;    /// @notice Address of the owner of the emitter that registered this schema
    }

    /// @notice Emitter data in registry
    struct Emitter {
        bytes32 emitterId;      /// @notice Emitter id
        bytes32 schemaId;       /// @notice Id of the schema used by that emitter
        uint64 expirationDate;  /// @notice Timestamp when emitter becomes invalid
        uint256 fee;            /// @notice Fees for creating and updating SIDs
        uint256 registryChainId;/// @notice Id of the chain where the registry is deployed
        address owner;          /// @notice Address that can act as that emitter
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
