// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Emitter} from "contracts/types/Structs.sol";
import {IConnector} from "contracts/interfaces/IConnector.sol";
import {SingleIdentifierRegistry} from "contracts/SingleIdentifierRegistry.sol";
import {SingleRouter} from "contracts/SingleRouter.sol";

import {Storage_SingleIdentifierID_SendingMessages} from "test-forge/storage/Storage_SingleIdentifierID_SendingMessages.sol";
import {Harness_SingleIdentifierID} from "test-forge/harness/Harness_SingleIdentifierID.sol";

abstract contract Environment_SingleIdentifierID_SendingMessages_Scroll_SameChain is Storage_SingleIdentifierID_SendingMessages {
    function _prepareEnv() internal override {
        vm.createSelectFork("https://1rpc.io/scroll");

        connectorId = 0;

        Harness_SingleIdentifierID singleIdHarness = new Harness_SingleIdentifierID();

        singleId = Harness_SingleIdentifierID(0x25158191bab9BFF92EB7214b6c2dE79105D11593);
        registry = SingleIdentifierRegistry(0x4e5bAE495031fECd141c39D0ca231d56e178Fb05);
        router = SingleRouter(0xfa31AB150782F086Ba93b7902E73B05DCBDe716b);

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
