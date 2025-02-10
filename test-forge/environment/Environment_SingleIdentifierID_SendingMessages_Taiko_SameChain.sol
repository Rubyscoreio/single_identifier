// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Emitter} from "contracts/types/Structs.sol";
import {IConnector} from "contracts/interfaces/IConnector.sol";
import {SingleIdentifierRegistry} from "contracts/SingleIdentifierRegistry.sol";
import {SingleRouter} from "contracts/SingleRouter.sol";

import {Storage_SingleIdentifierID_SendingMessages} from "test-forge/storage/Storage_SingleIdentifierID_SendingMessages.sol";
import {Harness_SingleIdentifierID} from "test-forge/harness/Harness_SingleIdentifierID.sol";

abstract contract Environment_SingleIdentifierID_SendingMessages_Taiko_SameChain is Storage_SingleIdentifierID_SendingMessages {
    function _prepareEnv() internal override {
        vm.createSelectFork("taiko");

        connectorId = 0;

        Harness_SingleIdentifierID singleIdHarness = new Harness_SingleIdentifierID();

        singleId = Harness_SingleIdentifierID(0xAff9D3Af3495c54E0bb90e03Bc762681bF5a52Bf);
        registry = SingleIdentifierRegistry(0xB9cC0Bb020cF55197C4C3d826AC87CAdba51f272);
        router = SingleRouter(0x3fd85e4932fA418401E96737700bA62569c08dA2);

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
