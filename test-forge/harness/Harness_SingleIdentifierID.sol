// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";

import {Emitter} from "contracts/types/Structs.sol";
import {SingleIdentifierID} from "contracts/SingleIdentifierID.sol";
import {SingleRouter} from "contracts/SingleRouter.sol";

contract Harness_SingleIdentifierID is SingleIdentifierID {
    bytes32 public constant TYPE_HASH =
    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    function exposed_authorizeUpgrade(address newImplementation) public {
        _authorizeUpgrade(newImplementation);
    }

    function exposed_sendRegisterSIDMessage(
        bytes32 _emitterId,
        bytes32 _schemaId,
        uint32 _connectorId,
        uint256 _fee,
        uint256 _registryChainId,
        uint64 _expirationDate,
        bytes calldata _data,
        string calldata _metadata
    ) public payable {
        _sendRegisterSIDMessage(
            _emitterId,
            _schemaId,
            _connectorId,
            _fee,
            _registryChainId,
            _expirationDate,
            _data,
            _metadata
        );
    }

    function exposed_sendUpdateSIDMessage(
        bytes32 _emitterId,
        uint32 _connectorId,
        uint256 _fee,
        uint256 _registryChainId,
        bytes32 _sidId,
        uint64 _expirationDate,
        bytes calldata _data,
        string calldata _metadata
    ) public payable {
        _sendUpdateSIDMessage(
            _emitterId,
            _connectorId,
            _fee,
            _registryChainId,
            _sidId,
            _expirationDate,
            _data,
            _metadata
        );
    }

    function helper_setEmitter(Emitter memory _emitter) public {
        emitters[_emitter.emitterId] = _emitter;
    }

    function helper_setRouter(address _router) public {
        router = SingleRouter(_router);
    }

    function helper_setEmitterBalance(bytes32 _emitterId, uint256 _balance) public {
        emittersBalances[_emitterId] = _balance;
    }

    function helper_setProtocolBalance(uint256 _balance) public {
        protocolBalance = _balance;
    }

    function helper_grantRole(bytes32 _role, address _address) public {
        _grantRole(_role, _address);
    }

    function workaround_hashTypedDataV4(bytes32 structHash) public view returns (bytes32) {
        return _hashTypedDataV4(structHash);
    }

    function workaround_hashTypedDataV4WithoutDomain(bytes32 structHash) public pure returns (bytes32) {
        bytes32 hashedName = keccak256(bytes(NAME));
        bytes32 hashedVersion = keccak256(bytes(VERSION));

        bytes32 domainSeparator = keccak256(abi.encode(TYPE_HASH, hashedName, hashedVersion, uint256(0), address(0)));
        return MessageHashUtils.toTypedDataHash(domainSeparator, structHash);
    }

    function workaround_generateEmitterId(bytes32 _schemaId, uint256 _registryChainId) public pure returns (bytes32) {
        return _generateEmitterId(_schemaId, _registryChainId);
    }
}
