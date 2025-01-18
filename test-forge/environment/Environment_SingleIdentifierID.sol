// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {SingleIdentifierRegistry} from "contracts/SingleIdentifierRegistry.sol";
import {SingleRouter} from "contracts/SingleRouter.sol";

import {Storage_SingleIdentifierID} from "test-forge/storage/Storage_SingleIdentifierID.sol";
import {Harness_SingleIdentifierID} from "test-forge/harness/Harness_SingleIdentifierID.sol";

abstract contract Environment_SingleIdentifierID is Storage_SingleIdentifierID {
    function _prepareEnv() internal override {
        singleId = new Harness_SingleIdentifierID();
        registry = new SingleIdentifierRegistry();
        router = new SingleRouter();
    }
}
