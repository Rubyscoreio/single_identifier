// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Emitter} from "contracts/types/Structs.sol";
import {IConnector} from "contracts/interfaces/IConnector.sol";
import {SingleIdentifierRegistry} from "contracts/SingleIdentifierRegistry.sol";
import {SingleRouter} from "contracts/SingleRouter.sol";

import {Storage_SingleIdentifierID_SendingMessages} from "test-forge/storage/Storage_SingleIdentifierID_SendingMessages.sol";
import {Harness_SingleIdentifierID} from "test-forge/harness/Harness_SingleIdentifierID.sol";

abstract contract Environment_SingleIdentifierID_SendingMessages_ZkEVM_SameChain is Storage_SingleIdentifierID_SendingMessages {
    function _prepareEnv() internal override {
        vm.createSelectFork("https://1rpc.io/polygon/zkevm");

        connectorId = 0;

        Harness_SingleIdentifierID singleIdHarness = new Harness_SingleIdentifierID();

        singleId = Harness_SingleIdentifierID(0x389452F3AA4B82C19bf8dFC2943Ca28E9f4EDA4A);
        registry = SingleIdentifierRegistry(0x9456E02Ef02C0F5256a559ecf7535356Aeab8647);
        router = SingleRouter(0x09B18EFC623bf4a6247B23320920C3044a45cC2c);

        address implementation = address(uint160(uint256(vm.load(address(singleId), _IMPLEMENTATION_SLOT))));
        vm.store(address(singleId), _IMPLEMENTATION_SLOT, bytes32(uint256(uint160(address(singleIdHarness)))));

        vm.etch(implementation, address(singleIdHarness).code);

        _prepareMocks();// FixMe: Rework env to exclude mocks
    }

    function _prepareMocks() internal {
        vm.mockCall(
            address(registry),
            abi.encodeWithSelector(SingleIdentifierRegistry.registrySID.selector),
            abi.encode("")
        );
        vm.mockCall(
            address(registry),
            abi.encodeWithSelector(SingleIdentifierRegistry.updateSID.selector),
            abi.encode("")
        );
    }
}
