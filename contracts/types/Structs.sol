// SPDX-License-Identifier: MIT
pragma solidity =0.8.24;

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

    struct SIDSchema {
        bytes32 schemaId;
        string name;
        string description;
        string schema;
        address emitter;
    }

    struct SIDSchemaParams {
        string name;
        string description;
        string schema;
        address emitter;
    }

    struct Emitter {
        bytes32 emitterId;
        bytes32 schemaId;
        uint64 expirationDate;
        uint256 fee;
        uint256 registryChainId;
        address owner;
    }

    struct Destination {
        uint256 chainId;
        uint32 layerZero;
        uint32 hyperlane;
    }

    struct Peers {
        bytes32 sender;
        bytes32 receiver;
    }
