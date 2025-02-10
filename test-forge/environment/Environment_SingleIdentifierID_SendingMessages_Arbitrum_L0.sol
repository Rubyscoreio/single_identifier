// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Emitter} from "contracts/types/Structs.sol";
import {IConnector} from "contracts/interfaces/IConnector.sol";
import {SingleIdentifierRegistry} from "contracts/SingleIdentifierRegistry.sol";
import {SingleRouter} from "contracts/SingleRouter.sol";

import {Environment_Base_L0} from "test-forge/environment/Environment_Base_L0.sol";
import {Harness_SingleIdentifierID} from "test-forge/harness/Harness_SingleIdentifierID.sol";

abstract contract Environment_SingleIdentifierID_SendingMessages_Arbitrum_L0 is Environment_Base_L0 {
    function _prepareEnv() internal override {
        vm.createSelectFork("arbitrum");

        Harness_SingleIdentifierID singleIdHarness = new Harness_SingleIdentifierID();

        singleId = Harness_SingleIdentifierID(0xc1b435E1cee1610aa1A19C5cBA20C832dA057146);
        registry = SingleIdentifierRegistry(0x4D1E2145082d0AB0fDa4a973dC4887C7295e21aB);
        router = SingleRouter(0x9456E02Ef02C0F5256a559ecf7535356Aeab8647);

        address implementation = address(uint160(uint256(vm.load(address(singleId), _IMPLEMENTATION_SLOT))));
        vm.store(address(singleId), _IMPLEMENTATION_SLOT, bytes32(uint256(uint160(address(singleIdHarness)))));

        vm.etch(implementation, address(singleIdHarness).code);

        reconfigureConnector(0x2f55C492897526677C5B68fb199ea31E2c126416);

        router.getPeer(connectorId, targetChainId);
    }
}
