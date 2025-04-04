// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

import {Storage_SingleIdentifierID_Fork} from "test-forge/storage/Storage_SingleIdentifierID_Fork.sol";
import {EmitterFull} from "test-forge/harness/Harness_SingleIdentifierID.sol";

import {SingleIdentifierID} from "contracts/SingleIdentifierID.sol";


abstract contract Suite_SingleIdentifierId_StorageLayout is Storage_SingleIdentifierID_Fork {
    using ECDSA for bytes32;

    function helper_sign(uint256 _privateKey, bytes32 _digest) public returns (bytes memory signature) {
        address signer = vm.addr(_privateKey);

        vm.startPrank(signer);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, _digest);

        signature = abi.encodePacked(r, s, v);
        vm.stopPrank();
    }

    function helper_hashTypedDataV4WithoutDomain(bytes32 structHash) public returns (bytes32) {
        bytes32 hashedName = keccak256(bytes(singleId.NAME()));
        bytes32 hashedVersion = keccak256(bytes(singleId.VERSION()));

        bytes32 typeHash = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

        bytes32 domainSeparator = keccak256(abi.encode(typeHash, hashedName, hashedVersion, uint256(0), address(0)));
        return MessageHashUtils.toTypedDataHash(domainSeparator, structHash);
    }

    function test_StorageLayout(
        EmitterFull memory _emitter,
        uint256 _emitterBalance,
        uint32 _fakeOperatorPrivateKeyIndex
    ) public {
        vm.assume(_emitter.basic.emitterId != bytes32(0));
        vm.assume(_emitter.basic.schemaId != bytes32(0));
        vm.assume(_emitter.basic.expirationDate > block.timestamp);
        vm.assume(_emitter.basic.registryChainId != uint256(0));
        vm.assume(_emitter.basic.owner != address(0));

        uint256 fakeOperatorPrivateKey = vm.deriveKey(_testMnemonic, _fakeOperatorPrivateKeyIndex);

        address fakeOperator = vm.addr(fakeOperatorPrivateKey);

        vm.label(fakeOperator, "fakeOperator");

        vm.prank(admin);
        singleId.grantRole(OPERATOR_ROLE, fakeOperator);

        assertTrue(singleId.hasRole(OPERATOR_ROLE, fakeOperator), "Operator role was not granted to the fakeOperator");

        bytes32 emitterId = keccak256(
            abi.encodePacked(
                _emitter.basic.schemaId,
                _emitter.basic.registryChainId
            )
        );

        _emitter.basic.emitterId = emitterId;

        bytes32 payloadHash = keccak256(
            abi.encode(
                keccak256("RegistryEmitterParams(bytes32 schemaId,address emitterAddress,uint256 registryChainId,uint256 fee,uint64 expirationDate)"),
                _emitter.basic.schemaId,
                _emitter.basic.owner,
                _emitter.basic.registryChainId,
                _emitter.basic.fee,
                _emitter.basic.expirationDate
            )
        );

        emit log_bytes32(payloadHash);

        bytes32 registerEmitterDigest = helper_hashTypedDataV4WithoutDomain(payloadHash);

        bytes memory signature = helper_sign(fakeOperatorPrivateKey, registerEmitterDigest);

        vm.expectEmit();
        emit SingleIdentifierID.EmitterRegistered(emitterId, _emitter.basic.owner, _emitter.basic.registryChainId);
        address(singleId).call(
            abi.encodeWithSelector(
                bytes4(keccak256("registerEmitter(bytes32,uint256,address,uint64,uint256,bytes)")),
                _emitter.basic.schemaId,
                _emitter.basic.registryChainId,
                _emitter.basic.owner,
                _emitter.basic.expirationDate,
                _emitter.basic.fee,
                signature
            )
        );

        (
            bytes32 emitterIdBefore,
            bytes32 schemaIdBefore,
            uint64 expirationDateBefore,
            uint256 registeringFeeBefore,
            uint256 registryChainIdBefore,
            address ownerBefore
        ) = singleId.emitters(_emitter.basic.emitterId);

        vm.prank(admin);
        singleId.setEmitterBalance(emitterId, _emitterBalance);

        uint256 protocolBalanceBefore = singleId.protocolBalance();
        uint256 emitterBalanceBefore = singleId.emittersBalances(emitterId);
        address routerAddressBefore = address(singleId.router());

        assertEq(emitterIdBefore, emitterId, "Emitter id was not set correctly");
        assertEq(schemaIdBefore, _emitter.basic.schemaId, "Schema id was not set correctly");
        assertEq(expirationDateBefore, _emitter.basic.expirationDate, "Expiration date was not set correctly");
        assertEq(registeringFeeBefore, _emitter.basic.fee, "Registering fee was not set correctly");
        assertEq(registryChainIdBefore, _emitter.basic.registryChainId, "Registry chain id was not set correctly");
        assertEq(ownerBefore, _emitter.basic.owner, "Owner was not set correctly");

        SingleIdentifierID update = new SingleIdentifierID();

        vm.prank(operator);
        singleId.upgradeTo(address(update));

        (
            bytes32 emitterIdAfter,
            bytes32 schemaIdAfter,
            uint64 expirationDateAfter,
            uint256 registeringFeeAfter,
            uint256 updatingFeeAfter,
            uint256 registryChainIdAfter,
            address ownerAfter
        ) = singleId.getEmitter(_emitter.basic.emitterId);

        uint256 protocolBalanceAfter = singleId.protocolBalance();
        uint256 emitterBalanceAfter = singleId.emittersBalances(emitterId);
        address routerAddressAfter = address(singleId.router());

        assertEq(emitterIdBefore, emitterIdAfter, "Emitter id corrupted after upgrade");
        assertEq(schemaIdBefore, schemaIdAfter, "Schema id corrupted after upgrade");
        assertEq(expirationDateBefore, expirationDateAfter, "Expiration date corrupted after upgrade");
        assertEq(registeringFeeBefore, registeringFeeAfter, "Registering fee corrupted after upgrade");
        // While updating fee is a new variable it is expected to be zero
        assertEq(0, updatingFeeAfter, "Updating fee corrupted after upgrade");
        assertEq(registryChainIdBefore, registryChainIdAfter, "Registry chain id corrupted after upgrade");
        assertEq(ownerBefore, ownerAfter, "Owner corrupted after upgrade");
        assertEq(protocolBalanceBefore, protocolBalanceAfter, "Protocol balance corrupted after upgrade");
        assertEq(emitterBalanceBefore, emitterBalanceAfter, "Emitter balance corrupted after upgrade");
        assertEq(routerAddressBefore, routerAddressAfter, "Router address corrupted after upgrade");
    }
}
