// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {IConnector} from "contracts/interfaces/IConnector.sol";
import {SingleIdentifierRegistry} from "contracts/SingleIdentifierRegistry.sol";
import {SingleRouter} from "contracts/SingleRouter.sol";

import {Storage_SingleIdentifierID} from "test-forge/storage/Storage_SingleIdentifierID.sol";
import {Harness_SingleIdentifierID} from "test-forge/harness/Harness_SingleIdentifierID.sol";

abstract contract Environment_SingleIdentifierID is Storage_SingleIdentifierID {
    function _prepareEnv() internal override {
        singleId = new Harness_SingleIdentifierID();

        prepareMocks();
    }

    function prepareMocks() public {
        vm.mockCall(
            address(router),
            abi.encodeWithSelector(SingleRouter.getRoute.selector),
            abi.encode(connector)
        );

        vm.mockCall(
            address(connector),
            abi.encodeWithSelector(IConnector.quote.selector),
            abi.encode(_defaultQuote)
        );

        vm.mockCall(
            address(connector),
            abi.encodeWithSelector(IConnector.sendMessage.selector),
            abi.encode("")
        );
    }
}
