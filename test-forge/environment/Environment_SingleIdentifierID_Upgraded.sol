// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import {IConnector} from "contracts/interfaces/IConnector.sol";
import {SingleIdentifierRegistry} from "contracts/SingleIdentifierRegistry.sol";
import {SingleRouter} from "contracts/SingleRouter.sol";

import {Storage_SingleIdentifierID} from "test-forge/storage/Storage_SingleIdentifierID.sol";
import {Harness_SingleIdentifierID} from "test-forge/harness/Harness_SingleIdentifierID.sol";

abstract contract Environment_SingleIdentifierID_Upgraded is Storage_SingleIdentifierID {
    function _prepareEnv() internal override {
        Harness_SingleIdentifierID singleId1 = new Harness_SingleIdentifierID();
        Harness_SingleIdentifierID singleId2 = new Harness_SingleIdentifierID();

        ERC1967Proxy proxy = new ERC1967Proxy(address(singleId1), "");

        singleId = Harness_SingleIdentifierID(address(proxy));
        router = new SingleRouter();

        singleId.initialize(
            _defaultFee,
            _defaultAdmin,
            _defaultOperator,
            address(router)
        );

        vm.prank(_defaultOperator);
        singleId.upgradeTo(address(singleId2));

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
