// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Emitter} from "contracts/types/Structs.sol";
import {IConnector} from "contracts/interfaces/IConnector.sol";
import {SingleIdentifierRegistry} from "contracts/SingleIdentifierRegistry.sol";
import {SingleRouter} from "contracts/SingleRouter.sol";

import {Environment_Base_L0} from "test-forge/environment/Environment_Base_L0.sol";
import {Harness_SingleIdentifierID} from "test-forge/harness/Harness_SingleIdentifierID.sol";

abstract contract Environment_SingleIdentifierID_SendingMessages_Linea_L0 is Environment_Base_L0 {
    function _prepareEnv() internal override {
        vm.createSelectFork("linea");

        Harness_SingleIdentifierID singleIdHarness = new Harness_SingleIdentifierID();

        singleId = Harness_SingleIdentifierID(0xFC353736BBA5642ab481b6b8392827B69A20cb17);
        registry = SingleIdentifierRegistry(0xDe981aB0cd819bF5D142B89fedA70119D3A958B9);
        router = SingleRouter(0x812DEC92e64Da2FCB773528CBC8B71aaDaA310e8);

        address implementation = address(uint160(uint256(vm.load(address(singleId), _IMPLEMENTATION_SLOT))));
        vm.store(address(singleId), _IMPLEMENTATION_SLOT, bytes32(uint256(uint160(address(singleIdHarness)))));

        vm.etch(implementation, address(singleIdHarness).code);

        reconfigureConnector(0x129Ee430Cb2Ff2708CCADDBDb408a88Fe4FFd480);

        router.getPeer(connectorId, targetChainId);
    }
}
