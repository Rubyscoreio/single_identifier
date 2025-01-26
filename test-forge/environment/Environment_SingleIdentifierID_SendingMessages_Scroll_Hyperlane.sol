// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Emitter} from "contracts/types/Structs.sol";
import {IConnector} from "contracts/interfaces/IConnector.sol";
import {SingleIdentifierRegistry} from "contracts/SingleIdentifierRegistry.sol";
import {SingleRouter} from "contracts/SingleRouter.sol";

import {Environment_Base_Hyperlane} from "test-forge/environment/Environment_Base_Hyperlane.sol";
import {Harness_SingleIdentifierID} from "test-forge/harness/Harness_SingleIdentifierID.sol";

abstract contract Environment_SingleIdentifierID_SendingMessages_Scroll_Hyperlane is Environment_Base_Hyperlane {
    function _prepareEnv() internal override {
        vm.createSelectFork("scroll");

        Harness_SingleIdentifierID singleIdHarness = new Harness_SingleIdentifierID();

        singleId = Harness_SingleIdentifierID(0x25158191bab9BFF92EB7214b6c2dE79105D11593);
        registry = SingleIdentifierRegistry(0x4e5bAE495031fECd141c39D0ca231d56e178Fb05);
        router = SingleRouter(0xfa31AB150782F086Ba93b7902E73B05DCBDe716b);

        address implementation = address(uint160(uint256(vm.load(address(singleId), _IMPLEMENTATION_SLOT))));
        vm.store(address(singleId), _IMPLEMENTATION_SLOT, bytes32(uint256(uint160(address(singleIdHarness)))));

        vm.etch(implementation, address(singleIdHarness).code);

        reconfigureConnector();
    }
}
