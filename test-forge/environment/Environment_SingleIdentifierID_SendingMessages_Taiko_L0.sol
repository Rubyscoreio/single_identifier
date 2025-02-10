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

import {Environment_Base_L0} from "test-forge/environment/Environment_Base_L0.sol";
import {Harness_SingleIdentifierID} from "test-forge/harness/Harness_SingleIdentifierID.sol";

abstract contract Environment_SingleIdentifierID_SendingMessages_Taiko_L0 is Environment_Base_L0 {
    function _prepareEnv() internal override {
        vm.createSelectFork("taiko");

        Harness_SingleIdentifierID singleIdHarness = new Harness_SingleIdentifierID();

        singleId = Harness_SingleIdentifierID(0xAff9D3Af3495c54E0bb90e03Bc762681bF5a52Bf);
        registry = SingleIdentifierRegistry(0xB9cC0Bb020cF55197C4C3d826AC87CAdba51f272);
        router = SingleRouter(0x3fd85e4932fA418401E96737700bA62569c08dA2);

        address implementation = address(uint160(uint256(vm.load(address(singleId), _IMPLEMENTATION_SLOT))));
        vm.store(address(singleId), _IMPLEMENTATION_SLOT, bytes32(uint256(uint160(address(singleIdHarness)))));

        vm.etch(implementation, address(singleIdHarness).code);

        reconfigureConnector(0xc097ab8CD7b053326DFe9fB3E3a31a0CCe3B526f);

        router.getPeer(connectorId, targetChainId);
    }
}
