// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Environment_SingleIdentifierID_Fork} from "./environment/Environment_SingleIdentifierID_Fork.sol";

import {Suite_SingleIdentifierId_StorageLayout} from "./suite/Suite_SingleIdentifierId_StorageLayout.sol";


contract Tester_SingleIdentifierID_UpgradedStorageLayout_Arbitrum is
    Environment_SingleIdentifierID_Fork,
    Suite_SingleIdentifierId_StorageLayout
    {
    constructor() Environment_SingleIdentifierID_Fork("arbitrum") {}
}

contract Tester_SingleIdentifierID_UpgradedStorageLayout_Base is
    Environment_SingleIdentifierID_Fork,
    Suite_SingleIdentifierId_StorageLayout
    {
    constructor() Environment_SingleIdentifierID_Fork("base") {}
}

contract Tester_SingleIdentifierID_UpgradedStorageLayout_Linea is
    Environment_SingleIdentifierID_Fork,
    Suite_SingleIdentifierId_StorageLayout
    {
    constructor() Environment_SingleIdentifierID_Fork("linea") {}
}

contract Tester_SingleIdentifierID_UpgradedStorageLayout_Optimism is
    Environment_SingleIdentifierID_Fork,
    Suite_SingleIdentifierId_StorageLayout
    {
    constructor() Environment_SingleIdentifierID_Fork("optimism") {}
}

contract Tester_SingleIdentifierID_UpgradedStorageLayout_Scroll is
    Environment_SingleIdentifierID_Fork,
    Suite_SingleIdentifierId_StorageLayout
    {
    constructor() Environment_SingleIdentifierID_Fork("scroll") {}
}

contract Tester_SingleIdentifierID_UpgradedStorageLayout_Taiko is
    Environment_SingleIdentifierID_Fork,
    Suite_SingleIdentifierId_StorageLayout
    {
    constructor() Environment_SingleIdentifierID_Fork("taiko") {}
}

contract Tester_SingleIdentifierID_UpgradedStorageLayout_ZkEVM is
    Environment_SingleIdentifierID_Fork,
    Suite_SingleIdentifierId_StorageLayout
    {
    constructor() Environment_SingleIdentifierID_Fork("zkevm") {}
}
