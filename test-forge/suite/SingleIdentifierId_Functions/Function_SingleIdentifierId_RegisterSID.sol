// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Base_SingleIdentifierId_Functions} from "./Base_SingleIdentifierId_Functions.sol";
import {EmitterFull} from "test-forge/harness/Harness_SingleIdentifierID.sol";

import {IConnector} from "contracts/interfaces/IConnector.sol";
import {SingleIdentifierID} from "contracts/SingleIdentifierID.sol";
import {SingleRouter} from "contracts/SingleRouter.sol";
import {MessageLib} from "contracts/lib/MessageLib.sol";

abstract contract Function_SingleIdentifierId_RegisterSID is Base_SingleIdentifierId_Functions {

    /**
        Target: SingleIdentifierID - registerSID
        Checks: Correct execution
        Restrictions:
            - _emitter.emitterId can't be zero
            - _data can't be empty
            - _fee + protocolFee + quote should not except maximal uint256
        Flow: registerSID function called with correct params and value
        Expects:
            - router.getRoute was called with the correct params
            - fee was added to emitter balance
            - fee was added to protocol balance
            - connector.quote was called with the correct params
            - connector.sendMessage was called with the correct params
            - SentRegisterSIDMessage event was emitted with the correct data
    */
    function test_RegisterSID_Ok(
        EmitterFull memory _emitter,
        uint32 _connectorId,
        bytes calldata _data,
        string calldata _metadata,
        uint32 _emitterPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.basic.emitterId != bytes32(0));
        vm.assume(_data.length != 0);
        vm.assume(_defaultFee + _defaultQuote < type(uint256).max - _emitter.basic.fee);

        /// Preparing environment
        uint256 protocolBalanceBefore = singleId.protocolBalance();
        uint256 emitterBalanceBefore = singleId.emittersBalances(_emitter.basic.emitterId);

        uint256 protocolFee = singleId.protocolFee();

        uint256 emitterPrivateKey = vm.deriveKey(_testMnemonic, _emitterPrivateKeyIndex);

        address emitter = vm.addr(emitterPrivateKey);

        vm.label(emitter, "emitter");

        _emitter.basic.emitterId = singleId.workaround_generateEmitterId(_emitter.basic.schemaId, _emitter.basic.registryChainId);
        _emitter.basic.owner = emitter;

        singleId.helper_setEmitter(_emitter);

        /// Preparing signature
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

        bytes memory emitterSignature = helper_sign(emitterPrivateKey, registerSIDDigest);

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

        vm.deal(address(this), _emitter.basic.fee + protocolFee + quote);

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
        emit SingleIdentifierID.SentRegisterSIDMessage(_emitter.basic.schemaId, _connectorId, address(this), _emitter.basic.registryChainId);
        // Executing function
        singleId.registerSID{value: _emitter.basic.fee + protocolFee + quote}(
            _emitter.basic.emitterId,
            _connectorId,
            _data,
            emitterSignature,
            _metadata
        );

        /// Asserting expectations
        assertEq(protocolBalanceBefore + protocolFee, singleId.protocolBalance(), "Protocol balance was not increased");
        assertEq(emitterBalanceBefore + _emitter.basic.fee, singleId.emittersBalances(_emitter.basic.emitterId), "Emitter balance was not increased");
    }

    /**
        Target: SingleIdentifierID - registerSID
        Checks: Revert when emitter did not exist
        Restrictions:
            - _emitter.emitterId can't be zero
            - _data can't be empty
            - _fee + protocolFee + quote should not except maximal uint256
        Flow: registerSID function called with invalid emitter id while other params and value are correct
        Expects:
            - execution reverts with the 'EmitterNotExists()' error
    */
    function test_RegisterSID_RevertIf_EmitterNotExists(
        EmitterFull memory _emitter,
        uint32 _connectorId,
        bytes calldata _data,
        string calldata _metadata,
        uint32 _emitterPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.basic.emitterId != bytes32(0));
        vm.assume(_data.length != 0);
        vm.assume(_defaultFee + _defaultQuote < type(uint256).max - _emitter.basic.fee);

        /// Preparing environment
        uint256 protocolFee = singleId.protocolFee();

        uint256 emitterPrivateKey = vm.deriveKey(_testMnemonic, _emitterPrivateKeyIndex);

        address emitter = vm.addr(emitterPrivateKey);

        vm.label(emitter, "emitter");

        _emitter.basic.emitterId = singleId.workaround_generateEmitterId(_emitter.basic.schemaId, _emitter.basic.registryChainId);
        _emitter.basic.owner = emitter;

        /// Preparing signature
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

        bytes memory emitterSignature = helper_sign(emitterPrivateKey, registerSIDDigest);

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

        vm.deal(address(this), _emitter.basic.fee + protocolFee + quote);

        vm.expectRevert(abi.encodeWithSignature("EmitterNotExists()"));
        // Executing function
        singleId.registerSID{value: _emitter.basic.fee + protocolFee + quote}(
            _emitter.basic.emitterId,
            _connectorId,
            _data,
            emitterSignature,
            _metadata
        );
    }

    /**
        Target: SingleIdentifierID - registerSID
        Checks: Revert when called with an invalid emitter signature
        Restrictions:
            - _emitter.emitterId can't be zero
            - _data can't be empty
            - _emitter.fee + protocolFee + quote should not except maximal uint256
        Flow: registerSID function called the invalid signature, correct params and without value
        Expects:
            - execution reverts with the 'SignatureInvalid()' error
    */
    function test_RegisterSID_RevertIf_EmitterSignatureIsInvalid(
        EmitterFull memory _emitter,
        uint32 _connectorId,
        bytes calldata _data,
        string calldata _metadata,
        uint32 _fakeSignerKeyIndex
    ) public {
        uint256 protocolFee = singleId.protocolFee();

        /// Validating restrictions
        vm.assume(_emitter.basic.emitterId != bytes32(0));
        vm.assume(_data.length != 0);
        vm.assume(protocolFee + _defaultQuote < type(uint256).max - _emitter.basic.fee);

        /// Preparing environment
        uint256 fakeSignerPrivateKey = vm.deriveKey(_testMnemonic, _fakeSignerKeyIndex);

        address fakeSigner = vm.addr(fakeSignerPrivateKey);

        vm.assume(fakeSigner != _emitter.basic.owner);

        vm.label(fakeSigner, "fakeSigner");

        singleId.helper_setEmitter(_emitter);

        /// Preparing signatures
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

        bytes memory invalidSignature = helper_sign(fakeSignerPrivateKey, registerSIDDigest);

        vm.expectRevert(abi.encodeWithSignature("SignatureInvalid()"));
        // Executing function
        singleId.registerSID(
            _emitter.basic.emitterId,
            _connectorId,
            _data,
            invalidSignature,
            _metadata
        );
    }

    /**
        Target: SingleIdentifierID - registerSID
        Checks: Revert when data is empty
        Restrictions:
            - _emitter.emitterId can't be zero
            - _fee + protocolFee + quote should not except maximal uint256
        Flow: registerSID function called with empty data while other params and value are correct
        Expects:
            - execution reverts with the 'DataIsEmpty()' error
    */
    function test_RegisterSID_RevertIf_DataIsEmpty(
        EmitterFull memory _emitter,
        uint32 _connectorId,
        bytes calldata _data,
        string calldata _metadata,
        uint32 _emitterPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.basic.emitterId != bytes32(0));
        vm.assume(_defaultFee + _defaultQuote < type(uint256).max - _emitter.basic.fee);

        /// Preparing environment
        uint256 protocolFee = singleId.protocolFee();

        uint256 emitterPrivateKey = vm.deriveKey(_testMnemonic, _emitterPrivateKeyIndex);

        address emitter = vm.addr(emitterPrivateKey);

        vm.label(emitter, "emitter");

        _emitter.basic.emitterId = singleId.workaround_generateEmitterId(_emitter.basic.schemaId, _emitter.basic.registryChainId);
        _emitter.basic.owner = emitter;

        singleId.helper_setEmitter(_emitter);

        /// Preparing signature
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

        bytes memory emitterSignature = helper_sign(emitterPrivateKey, registerSIDDigest);

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

        vm.deal(address(this), _emitter.basic.fee + protocolFee + quote);

        vm.expectRevert(abi.encodeWithSignature("DataIsEmpty()"));
        // Executing function
        singleId.registerSID{value: _emitter.basic.fee + protocolFee + quote}(
            _emitter.basic.emitterId,
            _connectorId,
            bytes(""),
            emitterSignature,
            _metadata
        );
    }

    /**
        Target: SingleIdentifierID - registerSID
        Checks: Revert when passed signature is empty
        Restrictions:
            - _emitter.emitterId can't be zero
            - _data can't be empty
            - _expirationDate greater than current timestamp
            - _fee + protocolFee + quote should not except maximal uint256
        Flow: registerSID function called with empty signature while other params and value are correct
        Expects:
            - execution reverts with the 'SignatureInvalid()' error
    */
    function test_RegisterSID_RevertIf_SignatureIsEmpty(
        EmitterFull memory _emitter,
        uint32 _connectorId,
        bytes calldata _data,
        string calldata _metadata,
        uint32 _emitterPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.basic.emitterId != bytes32(0));
        vm.assume(_data.length != 0);
        vm.assume(_defaultFee + _defaultQuote < type(uint256).max - _emitter.basic.fee);

        /// Preparing environment
        uint256 protocolFee = singleId.protocolFee();

        uint256 emitterPrivateKey = vm.deriveKey(_testMnemonic, _emitterPrivateKeyIndex);

        address emitter = vm.addr(emitterPrivateKey);

        vm.label(emitter, "emitter");

        _emitter.basic.emitterId = singleId.workaround_generateEmitterId(_emitter.basic.schemaId, _emitter.basic.registryChainId);
        _emitter.basic.owner = emitter;

        singleId.helper_setEmitter(_emitter);

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

        vm.deal(address(this), _emitter.basic.fee + protocolFee + quote);

        vm.expectRevert(abi.encodeWithSignature("SignatureInvalid()"));
        // Executing function
        singleId.registerSID{value: _emitter.basic.fee + protocolFee + quote}(
            _emitter.basic.emitterId,
            _connectorId,
            _data,
            bytes(""),
            _metadata
        );
    }

}
