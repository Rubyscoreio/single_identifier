// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {SingleIdentifierID} from "contracts/SingleIdentifierID.sol";
import {Emitter} from "contracts/types/Structs.sol";

contract Harness_SingleIdentifierID is SingleIdentifierID {
    function exposed_authorizeUpgrade(address newImplementation) public {
        _authorizeUpgrade(newImplementation);
    }

    function exposed_generateEmitterId(bytes32 _schemaId, uint256 _registryChainId) public pure returns (bytes32) {
        return _generateEmitterId(_schemaId, _registryChainId);
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
    ) public {
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
    ) public {
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

    function helper_grantRole(bytes32 _role, address _address) public {
        _grantRole(_role, _address);
    }
}
