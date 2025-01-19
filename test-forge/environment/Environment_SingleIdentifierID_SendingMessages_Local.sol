// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Emitter} from "contracts/types/Structs.sol";
import {IConnector} from "contracts/interfaces/IConnector.sol";
import {SingleIdentifierRegistry} from "contracts/SingleIdentifierRegistry.sol";
import {SingleRouter} from "contracts/SingleRouter.sol";

import {Storage_SingleIdentifierID_SendingMessages} from "test-forge/storage/Storage_SingleIdentifierID_SendingMessages.sol";
import {Harness_SingleIdentifierID} from "test-forge/harness/Harness_SingleIdentifierID.sol";

abstract contract Environment_SingleIdentifierID_SendingMessages_Local is Storage_SingleIdentifierID_SendingMessages {
    function _prepareEnv() internal override {
        singleId = new Harness_SingleIdentifierID();

        prepareMocks();
    }

    function prepareMocks() public {
        address connector = makeAddr("connector");

        vm.label(connector, "Connector");

        vm.mockCall(
            address(router),
            abi.encodeWithSelector(SingleRouter.getRoute.selector),
            abi.encode(connector)
        );

        vm.mockCall(
            connector,
            abi.encodeWithSelector(IConnector.quote.selector),
            abi.encode(50000e9)
        );

        vm.mockCall(
            connector,
            abi.encodeWithSelector(IConnector.sendMessage.selector),
            abi.encode("")
        );
    }
}
