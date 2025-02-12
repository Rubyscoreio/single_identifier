// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Base_Environment_OnChain} from "./Base_Environment_OnChain.sol";
import {Storage_SingleIdentifierID_SendingMessages} from "test-forge/storage/Storage_SingleIdentifierID_SendingMessages.sol";
import {Harness_SingleIdentifierID} from "test-forge/harness/Harness_SingleIdentifierID.sol";

import {SingleIdentifierRegistry} from "contracts/SingleIdentifierRegistry.sol";

contract Environment_SingleIdentifierID_SendingMessages is Base_Environment_OnChain, Storage_SingleIdentifierID_SendingMessages {
    string public chainName;

    constructor(string memory _chainName) {
        chainName = _chainName;
    }

    function _prepareEnv() internal override {
        vm.createSelectFork(chainName);

        ChainEnv memory chainEnv = getChainEnv(chainName);

        Harness_SingleIdentifierID singleIdHarness = new Harness_SingleIdentifierID();

        singleId = Harness_SingleIdentifierID(address(chainEnv.singleId));
        registry = SingleIdentifierRegistry(address(chainEnv.registry));
        router = chainEnv.router;

        address implementationSingleId = address(uint160(uint256(vm.load(address(singleId), _IMPLEMENTATION_SLOT))));
        address implementationRegistry = address(uint160(uint256(vm.load(address(registry), _IMPLEMENTATION_SLOT))));
        address implementationRouter = address(uint160(uint256(vm.load(address(router), _IMPLEMENTATION_SLOT))));

        vm.label(address(implementationSingleId), "SingleIdentifierID");
        vm.label(address(implementationRegistry), "SingleIdentifierRegistry");
        vm.label(address(implementationRouter), "SingleRouter");

        vm.etch(implementationSingleId, address(singleIdHarness).code);

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
