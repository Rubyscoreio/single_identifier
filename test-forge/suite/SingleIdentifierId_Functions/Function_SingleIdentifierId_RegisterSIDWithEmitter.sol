// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import {Base_SingleIdentifierId_Functions} from "./Base_SingleIdentifierId_Functions.sol";
import {EmitterFull} from "test-forge/harness/Harness_SingleIdentifierID.sol";

import {IConnector} from "contracts/interfaces/IConnector.sol";
import {SingleIdentifierID} from "contracts/SingleIdentifierID.sol";
import {SingleRouter} from "contracts/SingleRouter.sol";
import {MessageLib} from "contracts/lib/MessageLib.sol";

abstract contract Function_SingleIdentifierId_RegisterSIDWithEmitter is Base_SingleIdentifierId_Functions {

    /**
        Target: SingleIdentifierID - registerSIDWithEmitter
        Checks: Correct execution
        Restrictions:
            - _emitter.schemaId can't be zero
            - _emitter.expirationDate greater than current timestamp
            - _emitter.owner can't be zero address
            - _emitter.registryChainId can't be zero
            - _data can't be empty
            - _emitter.fee + protocolFee + quote should not except maximal uint256
        Flow: registerSIDWithEmitter function called with the correct params and correct value
        Expects:
            - new emitter created with the correct data
            - fee was added to emitter balance
            - fee was added to protocol balance
            - router.getRoute was called with the correct params
            - connector.quote was called with the correct params
            - connector.sendMessage was called with the correct params
            - EmitterRegistered event was emitted with the correct data
            - SentRegisterSIDMessage event was emitted with the correct data
    */
    function test_RegisterSIDWithEmitter_Ok(
        EmitterFull memory _emitter,
        uint32 _connectorId,
        bytes calldata _data,
        string calldata _metadata,
        uint32 _operatorPrivateKeyIndex,
        uint32 _emitterPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.basic.schemaId != bytes32(0));
        vm.assume(_emitter.basic.expirationDate > block.timestamp);
        vm.assume(_emitter.basic.registryChainId != uint256(0));
        vm.assume(_data.length != 0);
        vm.assume(_defaultFee + _defaultQuote < type(uint256).max - _emitter.basic.fee);

        /// Preparing environment
        uint256 protocolFee = singleId.protocolFee();

        uint256 protocolBalanceBefore = singleId.protocolBalance();
        uint256 emitterBalanceBefore = singleId.emittersBalances(_emitter.basic.emitterId);

        uint256 operatorPrivateKey = vm.deriveKey(_testMnemonic, _operatorPrivateKeyIndex);
        uint256 emitterPrivateKey = vm.deriveKey(_testMnemonic, _emitterPrivateKeyIndex);

        address operator = vm.addr(operatorPrivateKey);
        address emitter = vm.addr(emitterPrivateKey);

        vm.label(operator, "operator");
        vm.label(emitter, "emitter");

        singleId.helper_grantRole(OPERATOR_ROLE, operator);

        _emitter.basic.emitterId = singleId.workaround_generateEmitterId(_emitter.basic.schemaId, _emitter.basic.registryChainId);
        _emitter.basic.owner = emitter;

        /// Preparing signatures
        bytes32 registerEmitterDigest = singleId.workaround_hashTypedDataV4WithoutDomain(
            keccak256(
                abi.encode(
                    keccak256("RegistryEmitterParams(bytes32 schemaId,address emitterAddress,uint256 registryChainId,uint256 fee,uint64 expirationDate)"),
                    _emitter.basic.schemaId,
                    emitter,
                    _emitter.basic.registryChainId,
                    _emitter.basic.fee,
                    _emitter.basic.expirationDate
                )
            )
        );
        bytes32 registerSIDDigest = singleId.workaround_hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("RegisterParams(bytes32 schemaId,address user,bytes data,string metadata)"),
                    _emitter.basic.schemaId,
                    address(this),
                    keccak256(_data),
                    keccak256(abi.encodePacked(_metadata))
                )
            )
        );

        bytes memory registerEmitterSignature = helper_sign(operatorPrivateKey, registerEmitterDigest);
        bytes memory signature = helper_sign(emitterPrivateKey, registerSIDDigest);

        bytes memory messagePayload = MessageLib.encodeMessage(
            MessageLib.SendMessage(
                _emitter.basic.schemaId,
                address(this),
                _emitter.basic.expirationDate,
                _data,
                _metadata
            )
        );

        uint256 quote = connector.quote(_emitter.basic.registryChainId, messagePayload);

        vm.deal(address(this), _emitter.basic.fee + quote + protocolFee);

        vm.expectCall(
            address(router),
            abi.encodeWithSelector(SingleRouter.getRoute.selector, _connectorId, _emitter.basic.registryChainId)
        );
        vm.expectCall(
            address(connector),
            abi.encodeWithSelector(IConnector.quote.selector, _emitter.basic.registryChainId, messagePayload)
        );
        vm.expectCall(
            address(connector),
            quote,
            abi.encodeWithSelector(IConnector.sendMessage.selector, _emitter.basic.registryChainId, messagePayload)
        );

        vm.expectEmit();
        emit SingleIdentifierID.EmitterRegistered(_emitter.basic.emitterId, emitter, _emitter.basic.registryChainId);
        vm.expectEmit();
        emit SingleIdentifierID.SentRegisterSIDMessage(_emitter.basic.schemaId, _connectorId, address(this), _emitter.basic.registryChainId);
        // Executing function
        singleId.registerSIDWithEmitter{value: _emitter.basic.fee + protocolFee + _defaultQuote}(
            _emitter.basic.schemaId,
            _connectorId,
            _emitter.basic.expirationDate,
            _emitter.basic.fee,
            _emitter.updatingFee,
            _emitter.basic.registryChainId,
            emitter,
            _data,
            _metadata,
            registerEmitterSignature,
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
        assertEq(addedEmitterId, _emitter.basic.emitterId, "Created emitter has invalid emitterId");
        assertEq(addedSchemaId, _emitter.basic.schemaId, "Created emitter has invalid schemaId");
        assertEq(addedExpirationDate, _emitter.basic.expirationDate, "Created emitter has invalid expirationDate");
        assertEq(addedRegisteringFee, _emitter.basic.fee, "Created emitter has invalid registering fee");
        assertEq(addedUpdatingFee, _emitter.updatingFee, "Created emitter has invalid updating fee");
        assertEq(addedRegistryChainId, _emitter.basic.registryChainId, "Created emitter has invalid registryChainId");
        assertEq(addedOwner, _emitter.basic.owner, "Created emitter has invalid owner");
        assertEq(protocolBalanceBefore + protocolFee, singleId.protocolBalance(), "Protocol balance was not increased");
        assertEq(emitterBalanceBefore + _emitter.basic.fee, singleId.emittersBalances(_emitter.basic.emitterId), "Emitter balance was not increased");
    }

    /**
        Target: SingleIdentifierID - registerSIDWithEmitter
        Checks: Revert when called with an invalid emitter signature
        Restrictions:
            - _emitter.schemaId can't be zero
            - _emitter.expirationDate greater than current timestamp
            - _emitter.owner can't be zero address
            - _emitter.registryChainId can't be zero
            - _emitter.fee + protocolFee + quote should not except maximal uint256
        Flow: registerSIDWithEmitter function called with the invalid signature, correct params and without value
        Expects:
            - execution reverts with the 'SignatureInvalid()' error
    */
    function test_RegisterSIDWithEmitter_RevertIf_EmitterSignatureIsInvalid(
        EmitterFull memory _emitter,
        uint32 _connectorId,
        bytes calldata _data,
        string calldata _metadata,
        uint32 _operatorPrivateKeyIndex,
        uint32 _emitterPrivateKeyIndex,
        uint32 _fakeSignerKeyIndex
    ) public {
        uint256 protocolFee = singleId.protocolFee();

        /// Validating restrictions
        vm.assume(_emitter.basic.schemaId != bytes32(0));
        vm.assume(_emitter.basic.expirationDate > block.timestamp);
        vm.assume(_emitter.basic.registryChainId != uint256(0));
        vm.assume(_emitterPrivateKeyIndex != _fakeSignerKeyIndex);
        vm.assume(protocolFee + _defaultQuote < type(uint256).max - _emitter.basic.fee);

        /// Preparing environment
        uint256 operatorPrivateKey = vm.deriveKey(_testMnemonic, _operatorPrivateKeyIndex);
        uint256 emitterPrivateKey = vm.deriveKey(_testMnemonic, _emitterPrivateKeyIndex);
        uint256 fakeSignerPrivateKey = vm.deriveKey(_testMnemonic, _fakeSignerKeyIndex);

        address operator = vm.addr(operatorPrivateKey);
        address emitter = vm.addr(emitterPrivateKey);
        address fakeSigner = vm.addr(fakeSignerPrivateKey);

        vm.label(operator, "operator");
        vm.label(emitter, "emitter");
        vm.label(fakeSigner, "fakeSigner");

        singleId.helper_grantRole(OPERATOR_ROLE, operator);

        _emitter.basic.emitterId = singleId.workaround_generateEmitterId(_emitter.basic.schemaId, _emitter.basic.registryChainId);
        _emitter.basic.owner = emitter;

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
        bytes32 registerSIDDigest = singleId.workaround_hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("RegisterParams(bytes32 schemaId,address user,bytes data,string metadata)"),
                    _emitter.basic.schemaId,
                    address(this),
                    keccak256(_data),
                    keccak256(abi.encodePacked(_metadata))
                )
            )
        );

        bytes memory registerEmitterSignature = helper_sign(operatorPrivateKey, registerEmitterDigest);
        bytes memory invalidSignature = helper_sign(fakeSignerPrivateKey, registerSIDDigest);

        vm.expectRevert(abi.encodeWithSignature("SignatureInvalid()"));
        // Executing function
        singleId.registerSIDWithEmitter(
            _emitter.basic.schemaId,
            _connectorId,
            _emitter.basic.expirationDate,
            _emitter.basic.fee,
            _emitter.updatingFee,
            _emitter.basic.registryChainId,
            emitter,
            _data,
            _metadata,
            registerEmitterSignature,
            invalidSignature
        );
    }

}
