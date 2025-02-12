// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {Base_SingleIdentifierId_Functions} from "./Base_SingleIdentifierId_Functions.sol";
import {EmitterFull} from "test-forge/harness/Harness_SingleIdentifierID.sol";

import {IConnector} from "contracts/interfaces/IConnector.sol";
import {SingleIdentifierID} from "contracts/SingleIdentifierID.sol";
import {SingleRouter} from "contracts/SingleRouter.sol";
import {MessageLib} from "contracts/lib/MessageLib.sol";

abstract contract Function_SingleIdentifierId_UpdateSID is Base_SingleIdentifierId_Functions {

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
        EmitterFull memory _emitter,
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
        vm.assume(_emitter.basic.emitterId != bytes32(0));
        vm.assume(_sidId != bytes32(0));
        vm.assume(_defaultFee + _defaultQuote < type(uint256).max - _emitter.updatingFee);

        /// Preparing environment
        uint256 protocolBalanceBefore = singleId.protocolBalance();
        uint256 emitterBalanceBefore = singleId.emittersBalances(_emitter.basic.emitterId);

        uint256 protocolFee = singleId.protocolFee();

        uint256 emitterPrivateKey = vm.deriveKey(_testMnemonic, _emitterPrivateKeyIndex);

        address emitter = vm.addr(emitterPrivateKey);

        vm.label(emitter, "emitter");

        _emitter.basic.owner = emitter;

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

        uint256 quote = connector.quote(_emitter.basic.registryChainId, messagePayload);

        vm.deal(address(this), _emitter.updatingFee + quote + protocolFee);

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
        emit SingleIdentifierID.SentUpdateSIDMessage(_sidId, _connectorId, address(this), _emitter.basic.registryChainId);
        // Executing function
        singleId.updateSID{value: _emitter.updatingFee + protocolFee + _defaultQuote}(
            _emitter.basic.emitterId,
            _connectorId,
            _sidId,
            _expirationDate,
            _data,
            _metadata,
            signature
        );

        /// Asserting expectations
        assertEq(protocolBalanceBefore + protocolFee, singleId.protocolBalance(), "Protocol balance was not increased");
        assertEq(emitterBalanceBefore + _emitter.updatingFee, singleId.emittersBalances(_emitter.basic.emitterId), "Emitter balance was not increased");
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
        EmitterFull memory _emitter,
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
        vm.assume(_emitter.basic.emitterId != bytes32(0));
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
            _emitter.basic.emitterId,
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
        EmitterFull memory _emitter,
        uint32 _connectorId,
        bytes32 _sidId,
        uint64 _expirationDate,
        bytes calldata _data,
        string calldata _metadata,
        uint32 _emitterPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_expirationDate > block.timestamp);
        vm.assume(_emitter.basic.emitterId != bytes32(0));
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
            _emitter.basic.emitterId,
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
        Checks: Revert when called with a signature with invalid length
        Restrictions:
            - _emitter.emitterId can't be empty
            - _expirationDate greater than current timestamp
            - _sidId can't be empty
            - _signature length must not be 65
            - _data can't be empty
        Flow: updateSID function called with a signature with invalid length while other params are correct
        Expects:
            - execution reverts with the 'SignatureInvalid()' error
    */
    function test_UpdateSID_RevertIf_SignatureIsEmpty(
        EmitterFull memory _emitter,
        uint32 _connectorId,
        bytes32 _sidId,
        uint64 _expirationDate,
        bytes calldata _data,
        string calldata _metadata,
        bytes memory _invalidSignature,
        uint32 _emitterPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_expirationDate > block.timestamp);
        vm.assume(_data.length != 0);
        vm.assume(_invalidSignature.length != 65);
        vm.assume(_emitter.basic.emitterId != bytes32(0));
        vm.assume(_sidId != bytes32(0));

        /// Preparing environment
        uint256 emitterPrivateKey = vm.deriveKey(_testMnemonic, _emitterPrivateKeyIndex);

        address emitter = vm.addr(emitterPrivateKey);

        vm.label(emitter, "emitter");

        singleId.helper_setEmitter(_emitter);

        vm.expectRevert(abi.encodeWithSignature("SignatureInvalid()"));
        // Executing function
        singleId.updateSID(
            _emitter.basic.emitterId,
            _connectorId,
            _sidId,
            _expirationDate,
            _data,
            _metadata,
            _invalidSignature
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
        EmitterFull memory _emitter,
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
        vm.assume(_emitter.basic.emitterId != bytes32(0));

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
            _emitter.basic.emitterId,
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
        EmitterFull memory _emitter,
        uint32 _connectorId,
        bytes32 _sidId,
        uint64 _expirationDate,
        bytes calldata _data,
        string calldata _metadata,
        uint32 _signerPrivateKeyIndex
    ) public {
        /// Validating restrictions
        vm.assume(_expirationDate > block.timestamp);
        vm.assume(_data.length != 0);
        vm.assume(_emitter.basic.emitterId != bytes32(0));
        vm.assume(_sidId != bytes32(0));
        vm.assume(_defaultFee + _defaultQuote < type(uint256).max - _emitter.basic.fee);

        /// Preparing environment
        uint256 signerPrivateKey = vm.deriveKey(_testMnemonic, _signerPrivateKeyIndex);

        address signer = vm.addr(signerPrivateKey);

        vm.label(signer, "signer");

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

        bytes memory invalidSignature = helper_sign(signerPrivateKey, updateSIDDigest);

        emit log_address(ECDSA.recover(updateSIDDigest, invalidSignature));

        vm.expectRevert(abi.encodeWithSignature("SignatureInvalid()"));
        // Executing function
        singleId.updateSID(
            _emitter.basic.emitterId,
            _connectorId,
            _sidId,
            _expirationDate,
            _data,
            _metadata,
            invalidSignature
        );
    }

}
