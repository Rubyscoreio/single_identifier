// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Base_SingleIdentifierId_Functions} from "./Base_SingleIdentifierId_Functions.sol";
import {EmitterFull} from "test-forge/harness/Harness_SingleIdentifierID.sol";

import {SingleIdentifierID} from "contracts/SingleIdentifierID.sol";

abstract contract Function_SingleIdentifierId_RegisterEmitter is Base_SingleIdentifierId_Functions {
    /**
        Target: SingleIdentifierID - registerEmitter
        Checks: Correct execution
        Restrictions:
            - _emitter.schemaId can't be zero
            - _emitter.expirationDate greater than current timestamp
            - _emitter.owner can't be zero address
            - _emitter.registryChainId can't be zero
        Flow: registerEmitter function called with the correct params and correct value
        Expects:
            - new emitter created with the correct data
            - EmitterRegistered event was emitted with the correct data
            - returned freshly created emitter
    */
    function test_RegisterEmitter_Ok(
        EmitterFull memory _emitter,
        uint32 _operatorPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.basic.schemaId != bytes32(0));
        vm.assume(_emitter.basic.expirationDate > block.timestamp);
        vm.assume(_emitter.basic.owner != address(0));
        vm.assume(_emitter.basic.registryChainId != uint256(0));

        /// Preparing environment
        uint256 operatorPrivateKey = vm.deriveKey(_testMnemonic, _operatorPrivateKeyIndex);

        address operator = vm.addr(operatorPrivateKey);

        vm.label(operator, "operator");

        singleId.helper_grantRole(OPERATOR_ROLE, operator);

        _emitter.basic.emitterId = singleId.workaround_generateEmitterId(_emitter.basic.schemaId, _emitter.basic.registryChainId);

        /// Preparing signatures
        bytes32 registerEmitterDigest = singleId.workaround_hashTypedDataV4WithoutDomain(
            keccak256(
                abi.encode(
                    keccak256("RegistryEmitterParams(bytes32 schemaId,address emitterAddress,uint256 registryChainId,uint256 fee,uint64 expirationDate)"),
                    _emitter.basic.schemaId,
                    _emitter.basic.owner,
                    _emitter.basic.registryChainId,
                    _emitter.basic.fee,
                    _emitter.basic.expirationDate
                )
            )
        );

        bytes memory signature = helper_sign(operatorPrivateKey, registerEmitterDigest);

        vm.expectEmit();
        emit SingleIdentifierID.EmitterRegistered(_emitter.basic.emitterId, _emitter.basic.owner, _emitter.basic.registryChainId);
        // Executing function
        bytes32 result = singleId.registerEmitter(
            _emitter.basic.schemaId,
            _emitter.basic.registryChainId,
            _emitter.basic.owner,
            _emitter.basic.expirationDate,
            _emitter.basic.fee,
            _emitter.updatingFee,
            signature
        );

        (
            bytes32 addedEmitterId,
            bytes32 addedSchemaId,
            uint64 addedExpirationDate,
            uint256 addedRegisteringFee,
            uint256 addedUpdatingFee,
            uint256 addedRegistryChainId,
            address addedOwner
        ) = singleId.getEmitter(_emitter.basic.emitterId);

        /// Asserting expectations
        assertEq(result, _emitter.basic.emitterId, "Returned emitter id is not correct");
        assertEq(addedEmitterId, _emitter.basic.emitterId, "Created emitter has invalid emitterId");
        assertEq(addedSchemaId, _emitter.basic.schemaId, "Created emitter has invalid schemaId");
        assertEq(addedExpirationDate, _emitter.basic.expirationDate, "Created emitter has invalid expirationDate");
        assertEq(addedRegisteringFee, _emitter.basic.fee, "Created emitter has invalid registering fee");
        assertEq(addedUpdatingFee, _emitter.updatingFee, "Created emitter has invalid updating fee");
        assertEq(addedRegistryChainId, _emitter.basic.registryChainId, "Created emitter has invalid registryChainId");
        assertEq(addedOwner, _emitter.basic.owner, "Created emitter has invalid owner");
    }

    /**
        Target: SingleIdentifierID - registerEmitter
        Checks: Revert when called with an invalid schema id
        Restrictions:
            - _emitter.schemaId can't be zero
            - _emitter.expirationDate greater than current timestamp
            - _emitter.owner can't be zero address
            - _emitter.registryChainId can't be zero
        Flow: registerEmitter function called with schema id equal to zero while other params are correct
        Expects:
            - execution reverts with the 'SchemaIdInvalid()' error
    */
    function test_RegisterEmitter_RevertIf_SchemaIdIsZero(
        EmitterFull memory _emitter,
        uint32 _operatorPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.basic.expirationDate > block.timestamp);
        vm.assume(_emitter.basic.owner != address(0));
        vm.assume(_emitter.basic.registryChainId != uint256(0));

        /// Preparing environment
        uint256 operatorPrivateKey = vm.deriveKey(_testMnemonic, _operatorPrivateKeyIndex);

        address operator = vm.addr(operatorPrivateKey);

        vm.label(operator, "operator");

        singleId.helper_grantRole(OPERATOR_ROLE, operator);

        _emitter.basic.emitterId = singleId.workaround_generateEmitterId(_emitter.basic.schemaId, _emitter.basic.registryChainId);

        /// Preparing signatures
        bytes32 registerEmitterDigest = singleId.workaround_hashTypedDataV4WithoutDomain(
            keccak256(
                abi.encode(
                    keccak256("RegistryEmitterParams(bytes32 schemaId,address emitterAddress,uint256 registryChainId,uint256 fee,uint64 expirationDate)"),
                    _emitter.basic.schemaId,
                    _emitter.basic.owner,
                    _emitter.basic.registryChainId,
                    _emitter.basic.fee,
                    _emitter.basic.expirationDate
                )
            )
        );

        bytes memory signature = helper_sign(operatorPrivateKey, registerEmitterDigest);

        vm.expectRevert(abi.encodeWithSignature("SchemaIdInvalid()"));
        // Executing function
        singleId.registerEmitter(
            0,
            _emitter.basic.registryChainId,
            _emitter.basic.owner,
            _emitter.basic.expirationDate,
            _emitter.basic.fee,
            _emitter.updatingFee,
            signature
        );
    }

    /**
        Target: SingleIdentifierID - registerEmitter
        Checks: Revert when expiration date is less or equal to current timestamp
        Restrictions:
            - _emitter.schemaId can't be zero
            - _emitter.expirationDate less or equal to current timestamp
            - _emitter.owner can't be zero address
            - _emitter.registryChainId can't be zero
        Flow: registerEmitter function called with expiration date less or equal to current timestamp while other params are correct
        Expects:
            - execution reverts with the 'ExpirationDateInvalid()' error
    */
    function test_RegisterEmitter_RevertIf_ExpirationDateIsInvalid(
        EmitterFull memory _emitter,
        uint32 _operatorPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.basic.schemaId != bytes32(0));
        vm.assume(_emitter.basic.expirationDate <= block.timestamp);
        vm.assume(_emitter.basic.owner != address(0));
        vm.assume(_emitter.basic.registryChainId != uint256(0));

        /// Preparing environment
        uint256 operatorPrivateKey = vm.deriveKey(_testMnemonic, _operatorPrivateKeyIndex);

        address operator = vm.addr(operatorPrivateKey);

        vm.label(operator, "operator");

        singleId.helper_grantRole(OPERATOR_ROLE, operator);

        _emitter.basic.emitterId = singleId.workaround_generateEmitterId(_emitter.basic.schemaId, _emitter.basic.registryChainId);

        /// Preparing signatures
        bytes32 registerEmitterDigest = singleId.workaround_hashTypedDataV4WithoutDomain(
            keccak256(
                abi.encode(
                    keccak256("RegistryEmitterParams(bytes32 schemaId,address emitterAddress,uint256 registryChainId,uint256 fee,uint64 expirationDate)"),
                    _emitter.basic.schemaId,
                    _emitter.basic.owner,
                    _emitter.basic.registryChainId,
                    _emitter.basic.fee,
                    _emitter.basic.expirationDate
                )
            )
        );

        bytes memory signature = helper_sign(operatorPrivateKey, registerEmitterDigest);

        vm.expectRevert(abi.encodeWithSignature("ExpirationDateInvalid()"));
        // Executing function
        singleId.registerEmitter(
            _emitter.basic.schemaId,
            _emitter.basic.registryChainId,
            _emitter.basic.owner,
            _emitter.basic.expirationDate,
            _emitter.basic.fee,
            _emitter.updatingFee,
            signature
        );
    }

    /**
        Target: SingleIdentifierID - registerEmitter
        Checks: Revert when called with a zero chain id
        Restrictions:
            - _emitter.schemaId can't be zero
            - _emitter.expirationDate less or equal to current timestamp
            - _emitter.owner can't be zero address
        Flow: registerEmitter function called with zero chain id while other params are correct
        Expects:
            - execution reverts with the 'ChainIdInvalid()' error
    */
    function test_RegisterEmitter_RevertIf_ChainIdIsZero(
        EmitterFull memory _emitter,
        uint32 _operatorPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.basic.schemaId != bytes32(0));
        vm.assume(_emitter.basic.expirationDate > block.timestamp);
        vm.assume(_emitter.basic.owner != address(0));

        /// Preparing environment
        uint256 operatorPrivateKey = vm.deriveKey(_testMnemonic, _operatorPrivateKeyIndex);

        address operator = vm.addr(operatorPrivateKey);

        vm.label(operator, "operator");

        singleId.helper_grantRole(OPERATOR_ROLE, operator);

        _emitter.basic.emitterId = singleId.workaround_generateEmitterId(_emitter.basic.schemaId, _emitter.basic.registryChainId);

        /// Preparing signatures
        bytes32 registerEmitterDigest = singleId.workaround_hashTypedDataV4WithoutDomain(
            keccak256(
                abi.encode(
                    keccak256("RegistryEmitterParams(bytes32 schemaId,address emitterAddress,uint256 registryChainId,uint256 fee,uint64 expirationDate)"),
                    _emitter.basic.schemaId,
                    _emitter.basic.owner,
                    _emitter.basic.registryChainId,
                    _emitter.basic.fee,
                    _emitter.basic.expirationDate
                )
            )
        );

        bytes memory signature = helper_sign(operatorPrivateKey, registerEmitterDigest);

        vm.expectRevert(abi.encodeWithSignature("ChainIdInvalid()"));
        // Executing function
        singleId.registerEmitter(
            _emitter.basic.schemaId,
            0,
            _emitter.basic.owner,
            _emitter.basic.expirationDate,
            _emitter.basic.fee,
            _emitter.updatingFee,
            signature
        );
    }

    /**
        Target: SingleIdentifierID - registerEmitter
        Checks: Revert when called with a zero emitter address
        Restrictions:
            - _emitter.schemaId can't be zero
            - _emitter.expirationDate less or equal to current timestamp
            - _emitter.registryChainId can't be zero
        Flow: registerEmitter function called with zero chain id while other params are correct
        Expects:
            - execution reverts with the 'ChainIdInvalid()' error
    */
    function test_RegisterEmitter_RevertIf_EmitterAddressIsZero(
        EmitterFull memory _emitter,
        uint32 _operatorPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.basic.schemaId != bytes32(0));
        vm.assume(_emitter.basic.expirationDate > block.timestamp);
        vm.assume(_emitter.basic.registryChainId != uint256(0));

        /// Preparing environment
        uint256 operatorPrivateKey = vm.deriveKey(_testMnemonic, _operatorPrivateKeyIndex);

        address operator = vm.addr(operatorPrivateKey);

        vm.label(operator, "operator");

        singleId.helper_grantRole(OPERATOR_ROLE, operator);

        _emitter.basic.emitterId = singleId.workaround_generateEmitterId(_emitter.basic.schemaId, _emitter.basic.registryChainId);

        /// Preparing signatures
        bytes32 registerEmitterDigest = singleId.workaround_hashTypedDataV4WithoutDomain(
            keccak256(
                abi.encode(
                    keccak256("RegistryEmitterParams(bytes32 schemaId,address emitterAddress,uint256 registryChainId,uint256 fee,uint64 expirationDate)"),
                    _emitter.basic.schemaId,
                    _emitter.basic.owner,
                    _emitter.basic.registryChainId,
                    _emitter.basic.fee,
                    _emitter.basic.expirationDate
                )
            )
        );

        bytes memory signature = helper_sign(operatorPrivateKey, registerEmitterDigest);

        vm.expectRevert(abi.encodeWithSignature("AddressIsZero()"));
        // Executing function
        singleId.registerEmitter(
            _emitter.basic.schemaId,
            _emitter.basic.registryChainId,
            address(0),
            _emitter.basic.expirationDate,
            _emitter.basic.fee,
            _emitter.updatingFee,
            signature
        );
    }

    /**
        Target: SingleIdentifierID - registerEmitter
        Checks: Revert when called with an empty signature
        Restrictions:
            - _emitter.schemaId can't be zero
            - _emitter.expirationDate less or equal to current timestamp
            - _emitter.owner can't be zero address
            - _emitter.registryChainId can't be zero
        Flow: registerEmitter function called with empty signature while other params are correct
        Expects:
            - execution reverts with the 'SignatureInvalid()' error
    */
    function test_RegisterEmitter_RevertIf_SignatureIsEmpty(
        EmitterFull memory _emitter
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.basic.schemaId != bytes32(0));
        vm.assume(_emitter.basic.expirationDate > block.timestamp);
        vm.assume(_emitter.basic.owner != address(0));
        vm.assume(_emitter.basic.registryChainId != uint256(0));

        /// Preparing environment
        _emitter.basic.emitterId = singleId.workaround_generateEmitterId(_emitter.basic.schemaId, _emitter.basic.registryChainId);

        vm.expectRevert(abi.encodeWithSignature("SignatureInvalid()"));
        // Executing function
        singleId.registerEmitter(
            _emitter.basic.schemaId,
            _emitter.basic.registryChainId,
            _emitter.basic.owner,
            _emitter.basic.expirationDate,
            _emitter.basic.fee,
            _emitter.updatingFee,
            bytes("")
        );
    }

    /**
        Target: SingleIdentifierID - registerEmitter
        Checks: Revert when emitter already exist
        Restrictions:
            - _emitter.schemaId can't be zero
            - _emitter.expirationDate greater than current timestamp
            - _emitter.owner can't be zero address
            - _emitter.registryChainId can't be zero
        Flow: registerEmitter function called with the data of already existing emitter
        Expects:
            - execution reverts with the 'EmitterAlreadyExists()' error
    */
    function test_RegisterEmitter_RevertIf_EmitterAlreadyExists(
        EmitterFull memory _emitter,
        uint32 _operatorPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.basic.schemaId != bytes32(0));
        vm.assume(_emitter.basic.expirationDate > block.timestamp);
        vm.assume(_emitter.basic.owner != address(0));
        vm.assume(_emitter.basic.registryChainId != uint256(0));

        /// Preparing environment
        uint256 operatorPrivateKey = vm.deriveKey(_testMnemonic, _operatorPrivateKeyIndex);

        address operator = vm.addr(operatorPrivateKey);

        vm.label(operator, "operator");

        singleId.helper_grantRole(OPERATOR_ROLE, operator);

        _emitter.basic.emitterId = singleId.workaround_generateEmitterId(_emitter.basic.schemaId, _emitter.basic.registryChainId);

        singleId.helper_setEmitter(_emitter);

        /// Preparing signatures
        bytes32 registerEmitterDigest = singleId.workaround_hashTypedDataV4WithoutDomain(
            keccak256(
                abi.encode(
                    keccak256("RegistryEmitterParams(bytes32 schemaId,address emitterAddress,uint256 registryChainId,uint256 fee,uint64 expirationDate)"),
                    _emitter.basic.schemaId,
                    _emitter.basic.owner,
                    _emitter.basic.registryChainId,
                    _emitter.basic.fee,
                    _emitter.basic.expirationDate
                )
            )
        );

        bytes memory signature = helper_sign(operatorPrivateKey, registerEmitterDigest);

        vm.expectRevert(abi.encodeWithSignature("EmitterAlreadyExists()"));
        // Executing function
        singleId.registerEmitter(
            _emitter.basic.schemaId,
            _emitter.basic.registryChainId,
            _emitter.basic.owner,
            _emitter.basic.expirationDate,
            _emitter.basic.fee,
            _emitter.updatingFee,
            signature
        );
    }

    /**
        Target: SingleIdentifierID - registerEmitter
        Checks: Revert if signature was signed not by an operator
        Restrictions:
            - _emitter.schemaId can't be zero
            - _emitter.expirationDate greater than current timestamp
            - _emitter.owner can't be zero address
            - _emitter.registryChainId can't be zero
        Flow: registerEmitter function called with the signature signed not by the operator while other params are correct
        Expects:
            - execution reverts with the 'AccessControl: account 0x... is missing role 0x...' error
    */
    function test_RegisterEmitter_RevertIf_SignatureSignerIsNotAnOperator(
        EmitterFull memory _emitter,
        uint32 _operatorPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.basic.schemaId != bytes32(0));
        vm.assume(_emitter.basic.expirationDate > block.timestamp);
        vm.assume(_emitter.basic.owner != address(0));
        vm.assume(_emitter.basic.registryChainId != uint256(0));

        /// Preparing environment
        uint256 operatorPrivateKey = vm.deriveKey(_testMnemonic, _operatorPrivateKeyIndex);

        address operator = vm.addr(operatorPrivateKey);

        vm.label(operator, "operator");

        _emitter.basic.emitterId = singleId.workaround_generateEmitterId(_emitter.basic.schemaId, _emitter.basic.registryChainId);

        /// Preparing signatures
        bytes32 registerEmitterDigest = singleId.workaround_hashTypedDataV4WithoutDomain(
            keccak256(
                abi.encode(
                    keccak256("RegistryEmitterParams(bytes32 schemaId,address emitterAddress,uint256 registryChainId,uint256 fee,uint64 expirationDate)"),
                    _emitter.basic.schemaId,
                    _emitter.basic.owner,
                    _emitter.basic.registryChainId,
                    _emitter.basic.fee,
                    _emitter.basic.expirationDate
                )
            )
        );

        bytes memory signature = helper_sign(operatorPrivateKey, registerEmitterDigest);

        expectMissingRole(operator, OPERATOR_ROLE);
        // Executing function
        singleId.registerEmitter(
            _emitter.basic.schemaId,
            _emitter.basic.registryChainId,
            _emitter.basic.owner,
            _emitter.basic.expirationDate,
            _emitter.basic.fee,
            _emitter.updatingFee,
            signature
        );
    }

}
