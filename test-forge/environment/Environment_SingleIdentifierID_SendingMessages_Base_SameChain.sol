// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Emitter} from "contracts/types/Structs.sol";
import {IConnector} from "contracts/interfaces/IConnector.sol";
import {SingleIdentifierRegistry} from "contracts/SingleIdentifierRegistry.sol";
import {SingleRouter} from "contracts/SingleRouter.sol";

import {Storage_SingleIdentifierID_SendingMessages} from "test-forge/storage/Storage_SingleIdentifierID_SendingMessages.sol";
import {Harness_SingleIdentifierID} from "test-forge/harness/Harness_SingleIdentifierID.sol";

abstract contract Environment_SingleIdentifierID_SendingMessages_Base_SameChain is Storage_SingleIdentifierID_SendingMessages {
    function _prepareEnv() internal override {
        vm.createSelectFork("https://1rpc.io/base");

        connectorId = 0;

        Harness_SingleIdentifierID singleIdHarness = new Harness_SingleIdentifierID();

        singleId = Harness_SingleIdentifierID(0x09B18EFC623bf4a6247B23320920C3044a45cC2c);
        registry = SingleIdentifierRegistry(0x81f06f4b143a6eAD0e246DA04420F9d6d1fBEF59);
        router = SingleRouter(0xfcB1A34583980bc4565Eb8458B0F715f69e04bA8);

        vm.etch(address(singleId), address(singleIdHarness).code);

        singleId.protocolFee();

        router.getPeer(connectorId, targetChainId);

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
