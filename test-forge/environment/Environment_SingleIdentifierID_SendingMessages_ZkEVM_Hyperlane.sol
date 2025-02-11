// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {SetConfigParam} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import {UlnConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";

import {Emitter} from "contracts/types/Structs.sol";
import {IConnector} from "contracts/interfaces/IConnector.sol";
import {LayerZeroConnector} from "contracts/connectors/LayerZeroConnector.sol";
import {SingleIdentifierRegistry} from "contracts/SingleIdentifierRegistry.sol";
import {SingleRouter} from "contracts/SingleRouter.sol";

import {Environment_Base_Hyperlane} from "test-forge/environment/Environment_Base_Hyperlane.sol";
import {Harness_SingleIdentifierID} from "test-forge/harness/Harness_SingleIdentifierID.sol";

abstract contract Environment_SingleIdentifierID_SendingMessages_ZkEVM_Hyperlane is Environment_Base_Hyperlane {
    function _prepareEnv() internal override {
        vm.createSelectFork("zkevm");

        Harness_SingleIdentifierID singleIdHarness = new Harness_SingleIdentifierID();

        singleId = Harness_SingleIdentifierID(0x389452F3AA4B82C19bf8dFC2943Ca28E9f4EDA4A);
        registry = SingleIdentifierRegistry(0x9456E02Ef02C0F5256a559ecf7535356Aeab8647);
        router = SingleRouter(0x09B18EFC623bf4a6247B23320920C3044a45cC2c);

        address implementation = address(uint160(uint256(vm.load(address(singleId), _IMPLEMENTATION_SLOT))));
        vm.store(address(singleId), _IMPLEMENTATION_SLOT, bytes32(uint256(uint160(address(singleIdHarness)))));

        vm.etch(implementation, address(singleIdHarness).code);

        reconfigureConnector();
    }
}
