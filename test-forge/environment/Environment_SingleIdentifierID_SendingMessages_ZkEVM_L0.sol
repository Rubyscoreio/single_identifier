// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Emitter} from "contracts/types/Structs.sol";
import {IConnector} from "contracts/interfaces/IConnector.sol";
import {SingleIdentifierRegistry} from "contracts/SingleIdentifierRegistry.sol";
import {SingleRouter} from "contracts/SingleRouter.sol";

import {Storage_SingleIdentifierID_SendingMessages} from "test-forge/storage/Storage_SingleIdentifierID_SendingMessages.sol";
import {Harness_SingleIdentifierID} from "test-forge/harness/Harness_SingleIdentifierID.sol";

abstract contract Environment_SingleIdentifierID_SendingMessages_ZkEVM_L0 is Storage_SingleIdentifierID_SendingMessages {
    function _prepareEnv() internal override {
        vm.createSelectFork("https://1rpc.io/polygon/zkevm");

        Harness_SingleIdentifierID singleIdHarness = new Harness_SingleIdentifierID();

        singleId = Harness_SingleIdentifierID(0x389452F3AA4B82C19bf8dFC2943Ca28E9f4EDA4A);
        registry = SingleIdentifierRegistry(0x9456E02Ef02C0F5256a559ecf7535356Aeab8647);
        router = SingleRouter(0x09B18EFC623bf4a6247B23320920C3044a45cC2c);

        vm.etch(address(singleId), address(singleIdHarness).code);

        singleId.protocolFee();

        router.getPeer(connectorId, targetChainId);
    }
}
