// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import {Emitter} from "contracts/types/Structs.sol";
import {IConnector} from "contracts/interfaces/IConnector.sol";
import {MessageLib} from "contracts/lib/MessageLib.sol";
import {SingleIdentifierID} from "contracts/SingleIdentifierID.sol";
import {SingleRouter} from "contracts/SingleRouter.sol";

import {Storage_SingleIdentifierID} from "test-forge/storage/Storage_SingleIdentifierID.sol";

abstract contract Suite_SingleIdentifierID_ProtocolFlow is Storage_SingleIdentifierID {
    using ECDSA for bytes32;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    function helper_sign(uint256 _privateKey, bytes32 _digest) public returns (bytes memory signature) {
        address signer = vm.addr(_privateKey);

        vm.startPrank(signer);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, _digest);

        signature = abi.encodePacked(r, s, v);
        vm.stopPrank();
    }

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
        Emitter memory _emitter,
        uint32 _connectorId,
        bytes calldata _data,
        string calldata _metadata,
        uint32 _operatorPrivateKeyIndex,
        uint32 _emitterPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.schemaId != bytes32(0));
        vm.assume(_emitter.expirationDate > block.timestamp);
        vm.assume(_emitter.registryChainId != uint256(0));
        vm.assume(_data.length != 0);
        vm.assume(_defaultFee + _defaultQuote < type(uint256).max - _emitter.fee);

        /// Preparing environment
        uint256 protocolFee = singleId.protocolFee();

        uint256 protocolBalanceBefore = singleId.protocolBalance();
        uint256 emitterBalanceBefore = singleId.emittersBalances(_emitter.emitterId);

        uint256 operatorPrivateKey = vm.deriveKey(_testMnemonic, _operatorPrivateKeyIndex);
        uint256 emitterPrivateKey = vm.deriveKey(_testMnemonic, _emitterPrivateKeyIndex);

        address operator = vm.addr(operatorPrivateKey);
        address emitter = vm.addr(emitterPrivateKey);

        vm.label(operator, "operator");
        vm.label(emitter, "emitter");

        singleId.helper_grantRole(OPERATOR_ROLE, operator);

        _emitter.emitterId = singleId.workaround_generateEmitterId(_emitter.schemaId, _emitter.registryChainId);
        _emitter.owner = emitter;

        /// Preparing signatures
        bytes32 registerEmitterDigest = singleId.workaround_hashTypedDataV4WithoutDomain(
            keccak256(
                abi.encode(
                    keccak256("RegistryEmitterParams(bytes32 schemaId,address emitterAddress,uint256 registryChainId,uint256 fee,uint64 expirationDate)"),
                    _emitter.schemaId,
                    emitter,
                    _emitter.registryChainId,
                    _emitter.fee,
                    _emitter.expirationDate
                )
            )
        );
        bytes32 registerSIDDigest = singleId.workaround_hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("RegisterParams(bytes32 schemaId,address user,bytes data,string metadata)"),
                    _emitter.schemaId,
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
                _emitter.schemaId,
                address(this),
                _emitter.expirationDate,
                _data,
                _metadata
            )
        );

        uint256 quote = connector.quote(_emitter.registryChainId, messagePayload);

        vm.deal(address(this), _emitter.fee + quote + protocolFee);

        vm.expectCall(
            address(router),
            abi.encodeWithSelector(SingleRouter.getRoute.selector, _connectorId, _emitter.registryChainId)
        );
        vm.expectCall(
            address(connector),
            abi.encodeWithSelector(IConnector.quote.selector, _emitter.registryChainId, messagePayload)
        );
        vm.expectCall(
            address(connector),
            quote,
            abi.encodeWithSelector(IConnector.sendMessage.selector, _emitter.registryChainId, messagePayload)
        );

        vm.expectEmit();
        emit SingleIdentifierID.EmitterRegistered(_emitter.emitterId, emitter, _emitter.registryChainId);
        vm.expectEmit();
        emit SingleIdentifierID.SentRegisterSIDMessage(_emitter.schemaId, _connectorId, address(this), _emitter.registryChainId);
        // Executing function
        singleId.registerSIDWithEmitter{value: _emitter.fee + protocolFee + _defaultQuote}(
            _emitter.schemaId,
            _connectorId,
            _emitter.expirationDate,
            _emitter.fee,
            _emitter.registryChainId,
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
            uint256 addedFee,
            uint256 addedRegistryChainId,
            address addedOwner
        ) = singleId.emitters(_emitter.emitterId);

        /// Asserting expectations
        assertEq(addedEmitterId, _emitter.emitterId, "Created emitter has invalid emitterId");
        assertEq(addedSchemaId, _emitter.schemaId, "Created emitter has invalid schemaId");
        assertEq(addedExpirationDate, _emitter.expirationDate, "Created emitter has invalid expirationDate");
        assertEq(addedFee, _emitter.fee, "Created emitter has invalid fee");
        assertEq(addedRegistryChainId, _emitter.registryChainId, "Created emitter has invalid registryChainId");
        assertEq(addedOwner, _emitter.owner, "Created emitter has invalid owner");
        assertEq(protocolBalanceBefore + protocolFee, singleId.protocolBalance(), "Protocol balance was not increased");
        assertEq(emitterBalanceBefore + _emitter.fee, singleId.emittersBalances(_emitter.emitterId), "Emitter balance was not increased");
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
        Emitter memory _emitter,
        uint32 _connectorId,
        bytes calldata _data,
        string calldata _metadata,
        uint32 _operatorPrivateKeyIndex,
        uint32 _emitterPrivateKeyIndex,
        uint32 _fakeSignerKeyIndex
    ) public {
        uint256 protocolFee = singleId.protocolFee();

        /// Validating restrictions
        vm.assume(_emitter.schemaId != bytes32(0));
        vm.assume(_emitter.expirationDate > block.timestamp);
        vm.assume(_emitter.registryChainId != uint256(0));
        vm.assume(_emitterPrivateKeyIndex != _fakeSignerKeyIndex);
        vm.assume(protocolFee + _defaultQuote < type(uint256).max - _emitter.fee);

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

        _emitter.emitterId = singleId.workaround_generateEmitterId(_emitter.schemaId, _emitter.registryChainId);
        _emitter.owner = emitter;

        /// Preparing signatures
        bytes32 registerEmitterDigest = singleId.workaround_hashTypedDataV4WithoutDomain(
            keccak256(
                abi.encode(
                    keccak256("RegistryEmitterParams(bytes32 schemaId,address emitterAddress,uint256 registryChainId,uint256 fee,uint64 expirationDate)"),
                    _emitter.schemaId,
                    _emitter.owner,
                    _emitter.registryChainId,
                    _emitter.fee,
                    _emitter.expirationDate
                )
            )
        );
        bytes32 registerSIDDigest = singleId.workaround_hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("RegisterParams(bytes32 schemaId,address user,bytes data,string metadata)"),
                    _emitter.schemaId,
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
            _emitter.schemaId,
            _connectorId,
            _emitter.expirationDate,
            _emitter.fee,
            _emitter.registryChainId,
            emitter,
            _data,
            _metadata,
            registerEmitterSignature,
            invalidSignature
        );
    }

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
        Emitter memory _emitter,
        uint32 _connectorId,
        bytes calldata _data,
        string calldata _metadata,
        uint32 _emitterPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.emitterId != bytes32(0));
        vm.assume(_data.length != 0);
        vm.assume(_defaultFee + _defaultQuote < type(uint256).max - _emitter.fee);

        /// Preparing environment
        uint256 protocolBalanceBefore = singleId.protocolBalance();
        uint256 emitterBalanceBefore = singleId.emittersBalances(_emitter.emitterId);

        uint256 protocolFee = singleId.protocolFee();

        uint256 emitterPrivateKey = vm.deriveKey(_testMnemonic, _emitterPrivateKeyIndex);

        address emitter = vm.addr(emitterPrivateKey);

        vm.label(emitter, "emitter");

        _emitter.emitterId = singleId.workaround_generateEmitterId(_emitter.schemaId, _emitter.registryChainId);
        _emitter.owner = emitter;

        singleId.helper_setEmitter(_emitter);

        /// Preparing signature
        bytes32 registerSIDDigest = singleId.workaround_hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("RegisterParams(bytes32 schemaId,address user,bytes data,string metadata)"),
                    _emitter.schemaId,
                    address(this),
                    keccak256(_data),
                    keccak256(abi.encodePacked(_metadata))
                )
            )
        );

        bytes memory emitterSignature = helper_sign(emitterPrivateKey, registerSIDDigest);

        bytes memory messagePayload = MessageLib.encodeMessage(
            MessageLib.SendMessage(
                _emitter.schemaId,
                address(this),
                _emitter.expirationDate,
                _data,
                _metadata
            )
        );

        uint256 quote = connector.quote(_emitter.registryChainId, messagePayload);

        vm.deal(address(this), _emitter.fee + protocolFee + quote);

        vm.expectCall(
            address(router),
            abi.encodeWithSelector(SingleRouter.getRoute.selector, _connectorId, _emitter.registryChainId)
        );
        vm.expectCall(
            address(connector),
            abi.encodeWithSelector(IConnector.quote.selector, _emitter.registryChainId, messagePayload)
        );
        vm.expectCall(
            address(connector),
            quote,
            abi.encodeWithSelector(IConnector.sendMessage.selector, _emitter.registryChainId, messagePayload)
        );

        vm.expectEmit();
        emit SingleIdentifierID.SentRegisterSIDMessage(_emitter.schemaId, _connectorId, address(this), _emitter.registryChainId);
        // Executing function
        singleId.registerSID{value: _emitter.fee + protocolFee + quote}(
            _emitter.emitterId,
            _connectorId,
            _data,
            emitterSignature,
            _metadata
        );

        /// Asserting expectations
        assertEq(protocolBalanceBefore + protocolFee, singleId.protocolBalance(), "Protocol balance was not increased");
        assertEq(emitterBalanceBefore + _emitter.fee, singleId.emittersBalances(_emitter.emitterId), "Emitter balance was not increased");
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
        Emitter memory _emitter,
        uint32 _connectorId,
        bytes calldata _data,
        string calldata _metadata,
        uint32 _emitterPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.emitterId != bytes32(0));
        vm.assume(_data.length != 0);
        vm.assume(_defaultFee + _defaultQuote < type(uint256).max - _emitter.fee);

        /// Preparing environment
        uint256 protocolFee = singleId.protocolFee();

        uint256 emitterPrivateKey = vm.deriveKey(_testMnemonic, _emitterPrivateKeyIndex);

        address emitter = vm.addr(emitterPrivateKey);

        vm.label(emitter, "emitter");

        _emitter.emitterId = singleId.workaround_generateEmitterId(_emitter.schemaId, _emitter.registryChainId);
        _emitter.owner = emitter;

        /// Preparing signature
        bytes32 registerSIDDigest = singleId.workaround_hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("RegisterParams(bytes32 schemaId,address user,bytes data,string metadata)"),
                    _emitter.schemaId,
                    address(this),
                    keccak256(_data),
                    keccak256(abi.encodePacked(_metadata))
                )
            )
        );

        bytes memory emitterSignature = helper_sign(emitterPrivateKey, registerSIDDigest);

        bytes memory messagePayload = MessageLib.encodeMessage(
            MessageLib.SendMessage(
                _emitter.schemaId,
                address(this),
                _emitter.expirationDate,
                _data,
                _metadata
            )
        );

        uint256 quote = connector.quote(_emitter.registryChainId, messagePayload);

        vm.deal(address(this), _emitter.fee + protocolFee + quote);

        vm.expectRevert(abi.encodeWithSignature("EmitterNotExists()"));
        // Executing function
        singleId.registerSID{value: _emitter.fee + protocolFee + quote}(
            _emitter.emitterId,
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
        Emitter memory _emitter,
        uint32 _connectorId,
        bytes calldata _data,
        string calldata _metadata,
        uint32 _fakeSignerKeyIndex
    ) public {
        uint256 protocolFee = singleId.protocolFee();

        /// Validating restrictions
        vm.assume(_emitter.emitterId != bytes32(0));
        vm.assume(_data.length != 0);
        vm.assume(protocolFee + _defaultQuote < type(uint256).max - _emitter.fee);

        /// Preparing environment
        uint256 fakeSignerPrivateKey = vm.deriveKey(_testMnemonic, _fakeSignerKeyIndex);

        address fakeSigner = vm.addr(fakeSignerPrivateKey);

        vm.assume(fakeSigner != _emitter.owner);

        vm.label(fakeSigner, "fakeSigner");

        singleId.helper_setEmitter(_emitter);

        /// Preparing signatures
        bytes32 registerSIDDigest = singleId.workaround_hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("RegisterParams(bytes32 schemaId,address user,bytes data,string metadata)"),
                    _emitter.schemaId,
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
            _emitter.emitterId,
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
        Emitter memory _emitter,
        uint32 _connectorId,
        bytes calldata _data,
        string calldata _metadata,
        uint32 _emitterPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.emitterId != bytes32(0));
        vm.assume(_defaultFee + _defaultQuote < type(uint256).max - _emitter.fee);

        /// Preparing environment
        uint256 protocolFee = singleId.protocolFee();

        uint256 emitterPrivateKey = vm.deriveKey(_testMnemonic, _emitterPrivateKeyIndex);

        address emitter = vm.addr(emitterPrivateKey);

        vm.label(emitter, "emitter");

        _emitter.emitterId = singleId.workaround_generateEmitterId(_emitter.schemaId, _emitter.registryChainId);
        _emitter.owner = emitter;

        singleId.helper_setEmitter(_emitter);

        /// Preparing signature
        bytes32 registerSIDDigest = singleId.workaround_hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("RegisterParams(bytes32 schemaId,address user,bytes data,string metadata)"),
                    _emitter.schemaId,
                    address(this),
                    keccak256(_data),
                    keccak256(abi.encodePacked(_metadata))
                )
            )
        );

        bytes memory emitterSignature = helper_sign(emitterPrivateKey, registerSIDDigest);

        bytes memory messagePayload = MessageLib.encodeMessage(
            MessageLib.SendMessage(
                _emitter.schemaId,
                address(this),
                _emitter.expirationDate,
                _data,
                _metadata
            )
        );

        uint256 quote = connector.quote(_emitter.registryChainId, messagePayload);

        vm.deal(address(this), _emitter.fee + protocolFee + quote);

        vm.expectRevert(abi.encodeWithSignature("DataIsEmpty()"));
        // Executing function
        singleId.registerSID{value: _emitter.fee + protocolFee + quote}(
            _emitter.emitterId,
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
        Emitter memory _emitter,
        uint32 _connectorId,
        bytes calldata _data,
        string calldata _metadata,
        uint32 _emitterPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.emitterId != bytes32(0));
        vm.assume(_data.length != 0);
        vm.assume(_defaultFee + _defaultQuote < type(uint256).max - _emitter.fee);

        /// Preparing environment
        uint256 protocolFee = singleId.protocolFee();

        uint256 emitterPrivateKey = vm.deriveKey(_testMnemonic, _emitterPrivateKeyIndex);

        address emitter = vm.addr(emitterPrivateKey);

        vm.label(emitter, "emitter");

        _emitter.emitterId = singleId.workaround_generateEmitterId(_emitter.schemaId, _emitter.registryChainId);
        _emitter.owner = emitter;

        singleId.helper_setEmitter(_emitter);

        bytes memory messagePayload = MessageLib.encodeMessage(
            MessageLib.SendMessage(
                _emitter.schemaId,
                address(this),
                _emitter.expirationDate,
                _data,
                _metadata
            )
        );

        uint256 quote = connector.quote(_emitter.registryChainId, messagePayload);

        vm.deal(address(this), _emitter.fee + protocolFee + quote);

        vm.expectRevert(abi.encodeWithSignature("SignatureInvalid()"));
        // Executing function
        singleId.registerSID{value: _emitter.fee + protocolFee + quote}(
            _emitter.emitterId,
            _connectorId,
            _data,
            bytes(""),
            _metadata
        );
    }

    /**
        Target: SingleIdentifierID - updateSID
        Checks: Correct execution
        Restrictions:
            - _emitter.emitterId can't be empty
            - _expirationDate greater than current timestamp
            - _sidId can't be empty
            - _data can't be empty
            - _emitter.fee + protocolFee + quote should not except maximal uint256
        Flow: updateSID function called with the correct params and correct value
        Expects:
            - fee was added to emitter balance
            - fee was added to protocol balance
            - router.getRoute was called with the correct params
            - connector.quote was called with the correct params
            - connector.sendMessage was called with the correct params
            - EmitterRegistered event was emitted with the correct data
            - SentRegisterSIDMessage event was emitted with the correct data
    */
    function test_UpdateSID_Ok(
        Emitter memory _emitter,
        uint32 _connectorId,
        bytes32 _sidId,
        uint64 _expirationDate,
        bytes calldata _data,
        string calldata _metadata,
        uint32 _emitterPrivateKeyIndex
    ) public {
        vm.skip(true);
        /// Validating restrictions
        vm.assume(_expirationDate > block.timestamp);
        vm.assume(_data.length != 0);
        vm.assume(_emitter.emitterId != bytes32(0));
        vm.assume(_sidId != bytes32(0));
        vm.assume(_defaultFee + _defaultQuote < type(uint256).max - _emitter.fee);

        /// Preparing environment
        uint256 protocolBalanceBefore = singleId.protocolBalance();
        uint256 emitterBalanceBefore = singleId.emittersBalances(_emitter.emitterId);

        uint256 protocolFee = singleId.protocolFee();

        uint256 emitterPrivateKey = vm.deriveKey(_testMnemonic, _emitterPrivateKeyIndex);

        address emitter = vm.addr(emitterPrivateKey);

        singleId.helper_grantRole(OPERATOR_ROLE, emitter); // TODO: check

        vm.label(emitter, "emitter");

        singleId.helper_setEmitter(_emitter);

        /// Preparing signatures
        bytes32 updateSIDDigest = singleId.workaround_hashTypedDataV4(
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

        bytes memory signature = helper_sign(emitterPrivateKey, updateSIDDigest);

        bytes memory messagePayload = MessageLib.encodeMessage(
            MessageLib.UpdateMessage(
                _sidId,
                _expirationDate,
                _data,
                _metadata)
        );

        uint256 quote = connector.quote(_emitter.registryChainId, messagePayload);

        vm.deal(address(this), _emitter.fee + quote + protocolFee);

        vm.expectCall(
            address(router),
            abi.encodeWithSelector(SingleRouter.getRoute.selector, _connectorId, _emitter.registryChainId)
        );
        vm.expectCall(
            address(connector),
            abi.encodeWithSelector(IConnector.quote.selector, _emitter.registryChainId, messagePayload)
        );
        vm.expectCall(
            address(connector),
            quote,
            abi.encodeWithSelector(IConnector.sendMessage.selector, _emitter.registryChainId, messagePayload)
        );

        vm.expectEmit();
        emit SingleIdentifierID.SentUpdateSIDMessage(_sidId, _connectorId, address(this), _emitter.registryChainId);
        // Executing function
        singleId.updateSID{value: _emitter.fee + protocolFee + _defaultQuote}(
            _emitter.emitterId,
            _connectorId,
            _sidId,
            _expirationDate,
            _data,
            _metadata,
            signature
        );

        /// Asserting expectations
        assertEq(protocolBalanceBefore + protocolFee, singleId.protocolBalance(), "Protocol balance was not increased");
        assertEq(emitterBalanceBefore + _emitter.fee, singleId.emittersBalances(_emitter.emitterId), "Emitter balance was not increased");
    }

    /**
        Target: SingleIdentifierID - updateSID
        Checks: Revert when expiration date is less than current timestamp
        Restrictions:
            - _emitter.emitterId can't be empty
            - _expirationDate less than current timestamp
            - _sidId can't be empty
            - _data can't be empty
            - _emitter.fee + protocolFee + quote should not except maximal uint256
        Flow: updateSID function called with expiration date less than current timestamp while other params are correct
        Expects:
            - execution reverts with the 'ExpirationDateInvalid()' error
    */
    function test_UpdateSID_RevertIf_ExpirationDateIsInvalid(
        Emitter memory _emitter,
        uint32 _connectorId,
        bytes32 _sidId,
        uint64 _expirationDate,
        bytes calldata _data,
        string calldata _metadata,
        uint32 _emitterPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_expirationDate < block.timestamp);
        vm.assume(_data.length != 0);
        vm.assume(_emitter.emitterId != bytes32(0));
        vm.assume(_sidId != bytes32(0));

        /// Preparing environment
        uint256 emitterPrivateKey = vm.deriveKey(_testMnemonic, _emitterPrivateKeyIndex);

        address emitter = vm.addr(emitterPrivateKey);

        vm.label(emitter, "emitter");

        singleId.helper_setEmitter(_emitter);

        /// Preparing signatures
        bytes32 updateSIDDigest = singleId.workaround_hashTypedDataV4(
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

        bytes memory signature = helper_sign(emitterPrivateKey, updateSIDDigest);

        vm.expectRevert(abi.encodeWithSignature("ExpirationDateInvalid()"));
        // Executing function
        singleId.updateSID(
            _emitter.emitterId,
            _connectorId,
            _sidId,
            _expirationDate,
            _data,
            _metadata,
            signature
        );
    }

    /**
        Target: SingleIdentifierID - updateSID
        Checks: Revert when called with an empty data
        Restrictions:
            - _emitter.emitterId can't be empty
            - _expirationDate greater than current timestamp
            - _sidId can't be empty
            - _emitter.fee + protocolFee + quote should not except maximal uint256
        Flow: updateSID function called with empty data while other params are correct
        Expects:
            - execution reverts with the 'DataIsEmpty()' error
    */
    function test_UpdateSID_RevertIf_DataIsEmpty(
        Emitter memory _emitter,
        uint32 _connectorId,
        bytes32 _sidId,
        uint64 _expirationDate,
        bytes calldata _data,
        string calldata _metadata,
        uint32 _emitterPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_expirationDate > block.timestamp);
        vm.assume(_emitter.emitterId != bytes32(0));
        vm.assume(_sidId != bytes32(0));

        /// Preparing environment
        uint256 emitterPrivateKey = vm.deriveKey(_testMnemonic, _emitterPrivateKeyIndex);

        address emitter = vm.addr(emitterPrivateKey);

        vm.label(emitter, "emitter");

        singleId.helper_setEmitter(_emitter);

        /// Preparing signatures
        bytes32 updateSIDDigest = singleId.workaround_hashTypedDataV4(
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

        bytes memory signature = helper_sign(emitterPrivateKey, updateSIDDigest);

        vm.expectRevert(abi.encodeWithSignature("DataIsEmpty()"));
        // Executing function
        singleId.updateSID(
            _emitter.emitterId,
            _connectorId,
            _sidId,
            _expirationDate,
            bytes(""),
            _metadata,
            signature
        );
    }

    /**
        Target: SingleIdentifierID - updateSID
        Checks: Revert when called with an empty signature
        Restrictions:
            - _emitter.emitterId can't be empty
            - _expirationDate greater than current timestamp
            - _sidId can't be empty
            - _data can't be empty
        Flow: updateSID function called with empty signature while other params are correct
        Expects:
            - execution reverts with the 'SignatureInvalid()' error
    */
    function test_UpdateSID_RevertIf_SignatureIsEmpty(
        Emitter memory _emitter,
        uint32 _connectorId,
        bytes32 _sidId,
        uint64 _expirationDate,
        bytes calldata _data,
        string calldata _metadata,
        uint32 _emitterPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_expirationDate > block.timestamp);
        vm.assume(_data.length != 0);
        vm.assume(_emitter.emitterId != bytes32(0));
        vm.assume(_sidId != bytes32(0));

        /// Preparing environment
        uint256 emitterPrivateKey = vm.deriveKey(_testMnemonic, _emitterPrivateKeyIndex);

        address emitter = vm.addr(emitterPrivateKey);

        vm.label(emitter, "emitter");

        singleId.helper_setEmitter(_emitter);

        vm.expectRevert(abi.encodeWithSignature("SignatureInvalid()"));
        // Executing function
        singleId.updateSID(
            _emitter.emitterId,
            _connectorId,
            _sidId,
            _expirationDate,
            _data,
            _metadata,
            bytes("")
        );
    }

    /**
        Target: SingleIdentifierID - updateSID
        Checks: Revert if SID id is zero
        Restrictions:
            - _emitter.emitterId can't be empty
            - _expirationDate greater than current timestamp
            - _sidId can't be empty
            - _data can't be empty
        Flow: updateSID function called with zero sid id while other params are correct
        Expects:
            - reverts with the 'SIDNotValid()' error
    */
    function test_UpdateSID_RevertIf_SIDIdIsEmpty(
        Emitter memory _emitter,
        uint32 _connectorId,
        bytes32 _sidId,
        uint64 _expirationDate,
        bytes calldata _data,
        string calldata _metadata,
        uint32 _emitterPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_expirationDate > block.timestamp);
        vm.assume(_data.length != 0);
        vm.assume(_emitter.emitterId != bytes32(0));

        /// Preparing environment
        uint256 emitterPrivateKey = vm.deriveKey(_testMnemonic, _emitterPrivateKeyIndex);

        address emitter = vm.addr(emitterPrivateKey);

        vm.label(emitter, "emitter");

        singleId.helper_setEmitter(_emitter);

        /// Preparing signatures
        bytes32 updateSIDDigest = singleId.workaround_hashTypedDataV4(
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

        bytes memory signature = helper_sign(emitterPrivateKey, updateSIDDigest);

        vm.expectRevert(abi.encodeWithSignature("SIDNotValid()"));
        // Executing function
        singleId.updateSID(
            _emitter.emitterId,
            _connectorId,
            bytes32(0),
            _expirationDate,
            _data,
            _metadata,
            signature
        );
    }

    /**
        Target: SingleIdentifierID - updateSID
        Checks: Revert when signature is signed not by an emitter
        Restrictions:
            - _emitter.emitterId can't be empty
            - _expirationDate greater than current timestamp
            - _sidId can't be empty
            - _data can't be empty
        Flow: updateSID function called with the correct params and correct value
        Expects:
            - Revert with the 'AccessControl: account 0x... is missing role 0x...' error
    */
    function test_UpdateSID_RevertIf_SenderIsNotAnEmitter(
        Emitter memory _emitter,
        uint32 _connectorId,
        bytes32 _sidId,
        uint64 _expirationDate,
        bytes calldata _data,
        string calldata _metadata,
        uint32 _emitterPrivateKeyIndex
    ) public {
        vm.skip(true);
        /// Validating restrictions
        vm.assume(_expirationDate > block.timestamp);
        vm.assume(_data.length != 0);
        vm.assume(_emitter.emitterId != bytes32(0));
        vm.assume(_sidId != bytes32(0));
        vm.assume(_defaultFee + _defaultQuote < type(uint256).max - _emitter.fee);

        /// Preparing environment
        uint256 emitterPrivateKey = vm.deriveKey(_testMnemonic, _emitterPrivateKeyIndex);

        address emitter = vm.addr(emitterPrivateKey);

        vm.label(emitter, "emitter");

        singleId.helper_setEmitter(_emitter);

        /// Preparing signatures
        bytes32 updateSIDDigest = singleId.workaround_hashTypedDataV4(
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

        bytes memory invalidSignature = helper_sign(emitterPrivateKey, updateSIDDigest);

        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                StringsUpgradeable.toHexString(address(this)),
                " is missing role ",
                StringsUpgradeable.toHexString(uint256(OPERATOR_ROLE), 32)
            )
        );

        // Executing function
        singleId.updateSID(
            _emitter.emitterId,
            _connectorId,
            _sidId,
            _expirationDate,
            _data,
            _metadata,
            invalidSignature
        );
    }

    /**
        Target: SingleIdentifierID - updateEmitter
        Checks: Correct execution
        Restrictions:
            - _emitter.emitterId can't be empty
            - _newEmitter can't be zero
        Flow: updateEmitter function called with the correct params
        Expects:
            - new emitter owner was set
            - UpdateEmitter event was emitted with the correct data
    */
    function test_UpdateEmitter_Ok(
        Emitter memory _emitter,
        address _newEmitter,
        address _operator
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.emitterId != bytes32(0));
        vm.assume(_newEmitter != address(0));

        /// Preparing environment
        singleId.helper_grantRole(OPERATOR_ROLE, _operator);

        vm.label(_operator, "operator");

        singleId.helper_setEmitter(_emitter);

        vm.expectEmit();
        emit SingleIdentifierID.UpdateEmitter(_emitter.emitterId, _newEmitter);
        vm.prank(_operator);
        // Executing function
        singleId.updateEmitter(
            _emitter.emitterId,
            _newEmitter
        );

        /// Asserting expectations
        (,,,,,address newOwner) = singleId.emitters(_emitter.emitterId);
        assertEq(newOwner, _newEmitter, "New emitter owner was not set");
    }

    /**
        Target: SingleIdentifierID - updateEmitter
        Checks: Revert when called with a non-existent emitter
        Restrictions:
            - _newEmitter can't be zero
        Flow: updateEmitter function called with the non-existent emitter id while other params are correct
        Expects:
            - reverts with the 'EmitterNotExists()' error
    */
    function test_UpdateEmitter_RevertIf_EmitterNotExists(
        Emitter memory _emitter,
        address _newEmitter,
        address _operator
    ) public {
        /// Validating restrictions
        vm.assume(_newEmitter != address(0));

        /// Preparing environment
        singleId.helper_grantRole(OPERATOR_ROLE, _operator);

        vm.label(_operator, "operator");

        vm.prank(_operator);
        vm.expectRevert(abi.encodeWithSignature("EmitterNotExists()"));
        // Executing function
        singleId.updateEmitter(
            _emitter.emitterId,
            _newEmitter
        );
    }

    /**
        Target: SingleIdentifierID - updateEmitter
        Checks: Revert when called from non-operator address
        Restrictions:
            - _emitter.emitterId can't be empty
            - _newEmitter can't be zero
        Flow: updateEmitter function called with the correct params from a non-operator address
        Expects:
            - execution reverts with the 'AccessControl: account 0x... is missing role 0x...' error
    */
    function test_UpdateEmitter_RevertIf_SenderIsNotAnOperator(
        Emitter memory _emitter,
        address _newEmitter
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.emitterId != bytes32(0));
        vm.assume(_newEmitter != address(0));

        /// Preparing environment
        singleId.helper_setEmitter(_emitter);

        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                StringsUpgradeable.toHexString(address(this)),
                " is missing role ",
                StringsUpgradeable.toHexString(uint256(OPERATOR_ROLE), 32)
            )
        );
        // Executing function
        singleId.updateEmitter(
            _emitter.emitterId,
            _newEmitter
        );
    }

    /**
        Target: SingleIdentifierID - updateEmitter
        Checks: Revert when called new emitter owner is zero
        Restrictions:
            - _emitter.emitterId can't be empty
        Flow: updateEmitter function called with zero address as a new emitter owner while other params are correct
        Expects:
            - reverts with the 'AddressIsZero()' error
    */
    function test_UpdateEmitter_RevertIf_NewEmitterOwnerIsZero(
        Emitter memory _emitter,
        address _operator
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.emitterId != bytes32(0));

        /// Preparing environment
        singleId.helper_grantRole(OPERATOR_ROLE, _operator);

        vm.label(_operator, "operator");

        singleId.helper_setEmitter(_emitter);

        vm.expectRevert(abi.encodeWithSignature("AddressIsZero()"));
        vm.prank(_operator);
        // Executing function
        singleId.updateEmitter(
            _emitter.emitterId,
            address(0)
        );
    }

    /**
        Target: SingleIdentifierID - withdraw (emitter)
        Checks: Correct execution
        Restrictions:
            - _emitter.emitterId can't be empty
            - _receiver can't be zero address
        Flow: withdraw function called with the correct params
        Expects:
            - emitter balance set to 0
            - balance of the receiver increased by the emitter balance
            - call to _receiver should be sent with the correct value
            - Withdrawal event was emitted with the correct data
    */
    function test_WithdrawEmitter_Ok(
        Emitter memory _emitter,
        address payable _receiver,
        uint256 _amount
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.emitterId != bytes32(0));
        vm.assume(_receiver != address(0));
        assumePayable(_receiver);

        /// Preparing environment
        singleId.helper_setEmitter(_emitter);
        singleId.helper_setEmitterBalance(_emitter.emitterId, _amount);

        vm.deal(address(singleId), _amount);

        uint256 balanceSingleIdBefore = address(singleId).balance;
        uint256 balanceReceiverBefore = _receiver.balance;

        vm.expectCall(
            _receiver,
            _amount,
            ""
        );

        vm.expectEmit();
        emit SingleIdentifierID.Withdrawal(_receiver, _amount);
        vm.prank(_emitter.owner);
        // Executing function
        singleId.withdraw(
            _emitter.emitterId,
            _receiver
        );

        /// Asserting expectations
        uint256 balanceSingleIdAfter = address(singleId).balance;
        uint256 balanceEmitterAfter = singleId.emittersBalances(_emitter.emitterId);
        uint256 balanceReceiverAfter = _receiver.balance;

        assertEq(balanceEmitterAfter, 0, "Emitter balance was not set to 0");
        assertEq(balanceSingleIdAfter, balanceSingleIdBefore - _amount, "SingleId balance was changed incorrectly");
        assertEq(balanceReceiverAfter, balanceReceiverBefore + _amount, "Receiver balance was changed incorrectly");
    }

    /**
        Target: SingleIdentifierID - withdraw (emitter)
        Checks: Revert when called with a non-existent emitter
        Restrictions:
            - _receiver can't be zero address
        Flow: withdraw function called with the non-existent emitter id while other params are correct
        Expects:
            - execution reverts with the 'EmitterNotExists()' error
    */
    function test_WithdrawEmitter_RevertIf_EmitterNotExists(
        Emitter memory _emitter,
        address payable _receiver,
        uint256 _amount
    ) public {
        /// Validating restrictions
        vm.assume(_receiver != address(0));

        /// Preparing environment
        singleId.helper_setEmitterBalance(_emitter.emitterId, _amount);

        vm.expectRevert(abi.encodeWithSignature("EmitterNotExists()"));
        vm.prank(_emitter.owner);
        // Executing function
        singleId.withdraw(
            _emitter.emitterId,
            payable(_receiver)
        );
    }

    /**
        Target: SingleIdentifierID - withdraw (emitter)
        Checks: Revert when passed receiver is zero address
        Restrictions:
            - _emitter.emitterId can't be empty
        Flow: withdraw function called passing zero address as a receiver while other params are correct
        Expects:
            - reverts with the 'AddressIsZero()' error
    */
    function test_WithdrawEmitter_RevertIf_ReceiverIsZero(
        Emitter memory _emitter,
        uint256 _amount
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.emitterId != bytes32(0));

        /// Preparing environment
        singleId.helper_setEmitter(_emitter);
        singleId.helper_setEmitterBalance(_emitter.emitterId, _amount);

        vm.expectRevert(abi.encodeWithSignature("AddressIsZero()"));
        vm.prank(_emitter.owner);
        // Executing function
        singleId.withdraw(
            _emitter.emitterId,
            payable(address(0))
        );
    }

    /**
        Target: SingleIdentifierID - withdraw (emitter)
        Checks: Revert when caller is not an emitter owner
        Restrictions:
            - _emitter.emitterId can't be empty
            - _receiver can't be zero address
        Flow: withdraw function called from a non-owner address with correct params
        Expects:
            - reverts with the 'AccessControl: account 0x... is missing role 0x...' error
    */
    function test_WithdrawEmitter_RevertIf_SenderIsNotAnEmitter(
        Emitter memory _emitter,
        address _sender,
        address payable _receiver,
        uint256 _amount
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.emitterId != bytes32(0));
        vm.assume(_receiver != address(0));
        vm.assume(_sender != _emitter.owner);

        /// Preparing environment
        singleId.helper_setEmitter(_emitter);
        singleId.helper_setEmitterBalance(_emitter.emitterId, _amount);

        vm.expectRevert(abi.encodeWithSignature("SenderNotEmitter()"));
        vm.prank(_sender);
        // Executing function
        singleId.withdraw(
            _emitter.emitterId,
            payable(_receiver)
        );
    }

    /**
        Target: SingleIdentifierID - withdraw (emitter)
        Checks: Revert when failed to send Ether
        Restrictions:
            - _emitter.emitterId can't be empty
            - _receiver can't be zero address
        Flow: withdraw function called with the correct params
        Mocks:
            - receiver.call should revert
        Expects:
            - reverts with the 'Failed to send Ether' error
    */
    function test_WithdrawEmitter_RevertIf_FailedToSendEther(
        Emitter memory _emitter,
        address payable _receiver,
        uint256 _amount
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.emitterId != bytes32(0));
        vm.assume(_receiver != address(0));
        assumePayable(_receiver);

        /// Preparing environment
        singleId.helper_setEmitter(_emitter);
        singleId.helper_setEmitterBalance(_emitter.emitterId, _amount);

        vm.deal(address(singleId), _amount);

        bytes memory callData = "";
        bytes memory revertData = "";
        vm.mockCallRevert(_receiver, callData, revertData);

        vm.expectRevert("Failed to send Ether");
        vm.prank(_emitter.owner);
        // Executing function
        singleId.withdraw(
            _emitter.emitterId,
            payable(_receiver)
        );
    }

    /**
        Target: SingleIdentifierID - withdraw (protocol)
        Checks: Correct execution
        Restrictions:
            - _receiver can't be zero address
        Flow: withdraw function called with the correct params
        Expects:
            - protocolBalance variable set to 0
            - balance of the receiver increased by the emitter balance
            - call to _receiver should be sent with the correct value
            - Withdrawal event was emitted with the correct data
    */
    function test_WithdrawProtocol_Ok(
        address payable _receiver,
        address _admin,
        uint256 _amount
    ) public {
        /// Validating restrictions
        vm.assume(_receiver != address(0));
        assumePayable(_receiver);

        /// Preparing environment
        singleId.helper_grantRole(DEFAULT_ADMIN_ROLE, _admin);

        singleId.helper_setProtocolBalance(_amount);

        vm.deal(address(singleId), _amount);

        uint256 balanceSingleIdBefore = address(singleId).balance;
        uint256 balanceReceiverBefore = _receiver.balance;

        vm.expectCall(
            _receiver,
            _amount,
            ""
        );

        vm.expectEmit();
        emit SingleIdentifierID.Withdrawal(_receiver, _amount);
        vm.prank(_admin);
        // Executing function
        singleId.withdraw(
            payable(_receiver)
        );

        /// Asserting expectations
        uint256 balanceSingleIdProtocolAfter = singleId.protocolBalance();
        uint256 balanceSingleIdAfter = address(singleId).balance;
        uint256 balanceReceiverAfter = _receiver.balance;

        assertEq(balanceSingleIdProtocolAfter, 0, "Protocol balance was not set to 0");
        assertEq(balanceSingleIdAfter, balanceSingleIdBefore - _amount, "SingleId balance was changed incorrectly");
        assertEq(balanceReceiverAfter, balanceReceiverBefore + _amount, "Receiver balance was changed incorrectly");
    }

    /**
        Target: SingleIdentifierID - withdraw (protocol)
        Checks: Revert when caller is not an admin
        Restrictions:
            - _receiver can't be zero
        Flow: withdraw function called from a non-admin address with the correct params
        Expects:
            - reverts with the 'AccessControl: account 0x... is missing role 0x...' error
    */
    function test_WithdrawProtocol_RevertIf_SenderIsNotAnAdmin(
        address payable _receiver,
        address _sender,
        uint256 _amount
    ) public {
        /// Validating restrictions
        vm.assume(_receiver != address(0));

        /// Preparing environment
        singleId.helper_setProtocolBalance(_amount);

        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                StringsUpgradeable.toHexString(_sender),
                " is missing role ",
                StringsUpgradeable.toHexString(uint256(DEFAULT_ADMIN_ROLE), 32)
            )
        );
        vm.prank(_sender);
        // Executing function
        singleId.withdraw(
            payable(_receiver)
        );
    }

    /**
        Target: SingleIdentifierID - withdraw (protocol)
        Checks: Revert when receiver is zero address
        Flow: withdraw function called passing zero address as a receiver
        Expects:
            - execution reverts with the 'AddressIsZero()' error
    */
    function test_WithdrawProtocol_RevertIf_ReceiverIsZero(
        address _admin
    ) public {
        /// Preparing environment
        singleId.helper_grantRole(DEFAULT_ADMIN_ROLE, _admin);

        vm.expectRevert(abi.encodeWithSignature("AddressIsZero()"));
        vm.prank(_admin);
        // Executing function
        singleId.withdraw(
            payable(address(0))
        );
    }

    /**
        Target: SingleIdentifierID - withdraw (protocol)
        Checks: Revert when failed to send Ether
        Restrictions:
            - _receiver can't be zero address
        Flow: withdraw function called with the correct params
        Mocks:
            - receiver.call should revert
        Expects:
            - execution reverts with the 'Failed to send Ether' error
    */
    function test_WithdrawProtocol_RevertIf_FailedToSendEther(
        address payable _receiver,
        address _admin,
        uint256 _amount
    ) public {
        /// Validating restrictions
        vm.assume(_receiver != address(0));
        assumePayable(_receiver);
        assumeNotPrecompile(_receiver);

        /// Preparing environment
        singleId.helper_grantRole(DEFAULT_ADMIN_ROLE, _admin);

        singleId.helper_setProtocolBalance(_amount);

        vm.deal(address(singleId), _amount);

        bytes memory callData = "";
        bytes memory revertData = "";
        vm.mockCallRevert(_receiver, callData, revertData);

        vm.expectRevert("Failed to send Ether");
        vm.prank(_admin);
        // Executing function
        singleId.withdraw(
            payable(_receiver)
        );
    }

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
        Emitter memory _emitter,
        uint32 _operatorPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.schemaId != bytes32(0));
        vm.assume(_emitter.expirationDate > block.timestamp);
        vm.assume(_emitter.owner != address(0));
        vm.assume(_emitter.registryChainId != uint256(0));

        /// Preparing environment
        uint256 operatorPrivateKey = vm.deriveKey(_testMnemonic, _operatorPrivateKeyIndex);

        address operator = vm.addr(operatorPrivateKey);

        vm.label(operator, "operator");

        singleId.helper_grantRole(OPERATOR_ROLE, operator);

        _emitter.emitterId = singleId.workaround_generateEmitterId(_emitter.schemaId, _emitter.registryChainId);

        /// Preparing signatures
        bytes32 registerEmitterDigest = singleId.workaround_hashTypedDataV4WithoutDomain(
            keccak256(
                abi.encode(
                    keccak256("RegistryEmitterParams(bytes32 schemaId,address emitterAddress,uint256 registryChainId,uint256 fee,uint64 expirationDate)"),
                    _emitter.schemaId,
                    _emitter.owner,
                    _emitter.registryChainId,
                    _emitter.fee,
                    _emitter.expirationDate
                )
            )
        );

        bytes memory signature = helper_sign(operatorPrivateKey, registerEmitterDigest);

        vm.expectEmit();
        emit SingleIdentifierID.EmitterRegistered(_emitter.emitterId, _emitter.owner, _emitter.registryChainId);
        // Executing function
        bytes32 result = singleId.registerEmitter(
            _emitter.schemaId,
            _emitter.registryChainId,
            _emitter.owner,
            _emitter.expirationDate,
            _emitter.fee,
            signature
        );

        (
            bytes32 addedEmitterId,
            bytes32 addedSchemaId,
            uint64 addedExpirationDate,
            uint256 addedFee,
            uint256 addedRegistryChainId,
            address addedOwner
        ) = singleId.emitters(_emitter.emitterId);

        /// Asserting expectations
        assertEq(result, _emitter.emitterId, "Returned emitter id is not correct");
        assertEq(addedEmitterId, _emitter.emitterId, "Created emitter has invalid emitterId");
        assertEq(addedSchemaId, _emitter.schemaId, "Created emitter has invalid schemaId");
        assertEq(addedExpirationDate, _emitter.expirationDate, "Created emitter has invalid expirationDate");
        assertEq(addedFee, _emitter.fee, "Created emitter has invalid fee");
        assertEq(addedRegistryChainId, _emitter.registryChainId, "Created emitter has invalid registryChainId");
        assertEq(addedOwner, _emitter.owner, "Created emitter has invalid owner");
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
        Emitter memory _emitter,
        uint32 _operatorPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.expirationDate > block.timestamp);
        vm.assume(_emitter.owner != address(0));
        vm.assume(_emitter.registryChainId != uint256(0));

        /// Preparing environment
        uint256 operatorPrivateKey = vm.deriveKey(_testMnemonic, _operatorPrivateKeyIndex);

        address operator = vm.addr(operatorPrivateKey);

        vm.label(operator, "operator");

        singleId.helper_grantRole(OPERATOR_ROLE, operator);

        _emitter.emitterId = singleId.workaround_generateEmitterId(_emitter.schemaId, _emitter.registryChainId);

        /// Preparing signatures
        bytes32 registerEmitterDigest = singleId.workaround_hashTypedDataV4WithoutDomain(
            keccak256(
                abi.encode(
                    keccak256("RegistryEmitterParams(bytes32 schemaId,address emitterAddress,uint256 registryChainId,uint256 fee,uint64 expirationDate)"),
                    _emitter.schemaId,
                    _emitter.owner,
                    _emitter.registryChainId,
                    _emitter.fee,
                    _emitter.expirationDate
                )
            )
        );

        bytes memory signature = helper_sign(operatorPrivateKey, registerEmitterDigest);

        vm.expectRevert(abi.encodeWithSignature("SchemaIdInvalid()"));
        // Executing function
        singleId.registerEmitter(
            0,
            _emitter.registryChainId,
            _emitter.owner,
            _emitter.expirationDate,
            _emitter.fee,
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
        Emitter memory _emitter,
        uint32 _operatorPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.schemaId != bytes32(0));
        vm.assume(_emitter.expirationDate <= block.timestamp);
        vm.assume(_emitter.owner != address(0));
        vm.assume(_emitter.registryChainId != uint256(0));

        /// Preparing environment
        uint256 operatorPrivateKey = vm.deriveKey(_testMnemonic, _operatorPrivateKeyIndex);

        address operator = vm.addr(operatorPrivateKey);

        vm.label(operator, "operator");

        singleId.helper_grantRole(OPERATOR_ROLE, operator);

        _emitter.emitterId = singleId.workaround_generateEmitterId(_emitter.schemaId, _emitter.registryChainId);

        /// Preparing signatures
        bytes32 registerEmitterDigest = singleId.workaround_hashTypedDataV4WithoutDomain(
            keccak256(
                abi.encode(
                    keccak256("RegistryEmitterParams(bytes32 schemaId,address emitterAddress,uint256 registryChainId,uint256 fee,uint64 expirationDate)"),
                    _emitter.schemaId,
                    _emitter.owner,
                    _emitter.registryChainId,
                    _emitter.fee,
                    _emitter.expirationDate
                )
            )
        );

        bytes memory signature = helper_sign(operatorPrivateKey, registerEmitterDigest);

        vm.expectRevert(abi.encodeWithSignature("ExpirationDateInvalid()"));
        // Executing function
        singleId.registerEmitter(
            _emitter.schemaId,
            _emitter.registryChainId,
            _emitter.owner,
            _emitter.expirationDate,
            _emitter.fee,
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
        Emitter memory _emitter,
        uint32 _operatorPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.schemaId != bytes32(0));
        vm.assume(_emitter.expirationDate > block.timestamp);
        vm.assume(_emitter.owner != address(0));

        /// Preparing environment
        uint256 operatorPrivateKey = vm.deriveKey(_testMnemonic, _operatorPrivateKeyIndex);

        address operator = vm.addr(operatorPrivateKey);

        vm.label(operator, "operator");

        singleId.helper_grantRole(OPERATOR_ROLE, operator);

        _emitter.emitterId = singleId.workaround_generateEmitterId(_emitter.schemaId, _emitter.registryChainId);

        /// Preparing signatures
        bytes32 registerEmitterDigest = singleId.workaround_hashTypedDataV4WithoutDomain(
            keccak256(
                abi.encode(
                    keccak256("RegistryEmitterParams(bytes32 schemaId,address emitterAddress,uint256 registryChainId,uint256 fee,uint64 expirationDate)"),
                    _emitter.schemaId,
                    _emitter.owner,
                    _emitter.registryChainId,
                    _emitter.fee,
                    _emitter.expirationDate
                )
            )
        );

        bytes memory signature = helper_sign(operatorPrivateKey, registerEmitterDigest);

        vm.expectRevert(abi.encodeWithSignature("ChainIdInvalid()"));
        // Executing function
        singleId.registerEmitter(
            _emitter.schemaId,
            0,
            _emitter.owner,
            _emitter.expirationDate,
            _emitter.fee,
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
        Emitter memory _emitter,
        uint32 _operatorPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.schemaId != bytes32(0));
        vm.assume(_emitter.expirationDate > block.timestamp);
        vm.assume(_emitter.registryChainId != uint256(0));

        /// Preparing environment
        uint256 operatorPrivateKey = vm.deriveKey(_testMnemonic, _operatorPrivateKeyIndex);

        address operator = vm.addr(operatorPrivateKey);

        vm.label(operator, "operator");

        singleId.helper_grantRole(OPERATOR_ROLE, operator);

        _emitter.emitterId = singleId.workaround_generateEmitterId(_emitter.schemaId, _emitter.registryChainId);

        /// Preparing signatures
        bytes32 registerEmitterDigest = singleId.workaround_hashTypedDataV4WithoutDomain(
            keccak256(
                abi.encode(
                    keccak256("RegistryEmitterParams(bytes32 schemaId,address emitterAddress,uint256 registryChainId,uint256 fee,uint64 expirationDate)"),
                    _emitter.schemaId,
                    _emitter.owner,
                    _emitter.registryChainId,
                    _emitter.fee,
                    _emitter.expirationDate
                )
            )
        );

        bytes memory signature = helper_sign(operatorPrivateKey, registerEmitterDigest);

        vm.expectRevert(abi.encodeWithSignature("AddressIsZero()"));
        // Executing function
        singleId.registerEmitter(
            _emitter.schemaId,
            _emitter.registryChainId,
            address(0),
            _emitter.expirationDate,
            _emitter.fee,
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
        Emitter memory _emitter
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.schemaId != bytes32(0));
        vm.assume(_emitter.expirationDate > block.timestamp);
        vm.assume(_emitter.owner != address(0));
        vm.assume(_emitter.registryChainId != uint256(0));

        /// Preparing environment
        _emitter.emitterId = singleId.workaround_generateEmitterId(_emitter.schemaId, _emitter.registryChainId);

        vm.expectRevert(abi.encodeWithSignature("SignatureInvalid()"));
        // Executing function
        singleId.registerEmitter(
            _emitter.schemaId,
            _emitter.registryChainId,
            _emitter.owner,
            _emitter.expirationDate,
            _emitter.fee,
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
        Emitter memory _emitter,
        uint32 _operatorPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.schemaId != bytes32(0));
        vm.assume(_emitter.expirationDate > block.timestamp);
        vm.assume(_emitter.owner != address(0));
        vm.assume(_emitter.registryChainId != uint256(0));

        /// Preparing environment
        uint256 operatorPrivateKey = vm.deriveKey(_testMnemonic, _operatorPrivateKeyIndex);

        address operator = vm.addr(operatorPrivateKey);

        vm.label(operator, "operator");

        singleId.helper_grantRole(OPERATOR_ROLE, operator);

        _emitter.emitterId = singleId.workaround_generateEmitterId(_emitter.schemaId, _emitter.registryChainId);

        singleId.helper_setEmitter(_emitter);

        /// Preparing signatures
        bytes32 registerEmitterDigest = singleId.workaround_hashTypedDataV4WithoutDomain(
            keccak256(
                abi.encode(
                    keccak256("RegistryEmitterParams(bytes32 schemaId,address emitterAddress,uint256 registryChainId,uint256 fee,uint64 expirationDate)"),
                    _emitter.schemaId,
                    _emitter.owner,
                    _emitter.registryChainId,
                    _emitter.fee,
                    _emitter.expirationDate
                )
            )
        );

        bytes memory signature = helper_sign(operatorPrivateKey, registerEmitterDigest);

        vm.expectRevert(abi.encodeWithSignature("EmitterAlreadyExists()"));
        // Executing function
        singleId.registerEmitter(
            _emitter.schemaId,
            _emitter.registryChainId,
            _emitter.owner,
            _emitter.expirationDate,
            _emitter.fee,
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
        Emitter memory _emitter,
        uint32 _operatorPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.schemaId != bytes32(0));
        vm.assume(_emitter.expirationDate > block.timestamp);
        vm.assume(_emitter.owner != address(0));
        vm.assume(_emitter.registryChainId != uint256(0));

        /// Preparing environment
        uint256 operatorPrivateKey = vm.deriveKey(_testMnemonic, _operatorPrivateKeyIndex);

        address operator = vm.addr(operatorPrivateKey);

        vm.label(operator, "operator");

        _emitter.emitterId = singleId.workaround_generateEmitterId(_emitter.schemaId, _emitter.registryChainId);

        /// Preparing signatures
        bytes32 registerEmitterDigest = singleId.workaround_hashTypedDataV4WithoutDomain(
            keccak256(
                abi.encode(
                    keccak256("RegistryEmitterParams(bytes32 schemaId,address emitterAddress,uint256 registryChainId,uint256 fee,uint64 expirationDate)"),
                    _emitter.schemaId,
                    _emitter.owner,
                    _emitter.registryChainId,
                    _emitter.fee,
                    _emitter.expirationDate
                )
            )
        );

        bytes memory signature = helper_sign(operatorPrivateKey, registerEmitterDigest);

        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                StringsUpgradeable.toHexString(operator),
                " is missing role ",
                StringsUpgradeable.toHexString(uint256(OPERATOR_ROLE), 32)
            )
        );
        // Executing function
        singleId.registerEmitter(
            _emitter.schemaId,
            _emitter.registryChainId,
            _emitter.owner,
            _emitter.expirationDate,
            _emitter.fee,
            signature
        );
    }

    /**
        Target: SingleIdentifierID - updateFee
        Checks: Correct execution
        Restrictions:
            - _emitter.emitterId can't be empty
        Flow: registerEmitter function called with the correct params
        Expects:
            - new fee for emitter was set
    */
    function test_UpdateFee_Ok(
        Emitter memory _emitter,
        uint256 _fee
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.emitterId != bytes32(0));

        /// Preparing environment
        singleId.helper_setEmitter(_emitter);

        /// Executing function
        vm.prank(_emitter.owner);
        singleId.updateFee(
            _emitter.emitterId,
            _fee
        );

        (,,, uint256 updatedFee,,) = singleId.emitters(_emitter.emitterId);

        /// Asserting expectations
        assertEq(updatedFee, _fee, "Fee updated incorrectly");
    }

    /**
        Target: SingleIdentifierID - updateFee
        Checks: Revert when called with a non-existent emitter
        Restrictions:
        Flow: registerEmitter function called with non-existent emitter id while other params are correct
        Expects:
            - execution reverts with the 'EmitterNotExists()' error
    */
    function test_UpdateFee_RevertIf_EmitterNotExists(
        Emitter memory _emitter,
        uint256 _fee
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.emitterId != bytes32(0));

        vm.expectRevert(abi.encodeWithSignature("EmitterNotExists()"));
        /// Executing function
        vm.prank(_emitter.owner);
        singleId.updateFee(
            _emitter.emitterId,
            _fee
        );
    }

    /**
        Target: SingleIdentifierID - updateFee
        Checks: Revert if caller is not an emitters owner
        Restrictions:
            - _emitter.emitterId can't be empty
        Flow: registerEmitter function called with the correct params from the address that is not emitters owner
        Expects:
            - new fee for emitter was set
    */
    function test_UpdateFee_RevertIf_SenderIsNotAnEmitter(
        Emitter memory _emitter,
        address _sender,
        uint256 _fee
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.emitterId != bytes32(0));
        vm.assume(_sender != _emitter.owner);

        /// Preparing environment
        singleId.helper_setEmitter(_emitter);

        vm.expectRevert(abi.encodeWithSignature("SenderNotEmitter()"));
        /// Executing function
        vm.prank(_sender);
        singleId.updateFee(
            _emitter.emitterId,
            _fee
        );
    }
}
