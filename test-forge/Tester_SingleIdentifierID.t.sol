// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Environment_SingleIdentifierID} from "./environment/Environment_SingleIdentifierID.sol";
import {Environment_SingleIdentifierID_Upgraded} from "./environment/Environment_SingleIdentifierID_Upgraded.sol";

import {Suite_SingleIdentifierID_Upgradeable} from "./suite/Suite_SingleIdentifierID_Upgradeable.sol";
import {Suite_SingleIdentifierID_Functions} from "./suite/Suite_SingleIdentifierID_Functions.sol";
import {Suite_SingleIdentifierID_OnchainUpgrade} from "./suite/Suite_SingleIdentifierID_OnchainUpgrade.sol";


contract SingleIdentifierIDTest_ProtocolFlow is
    Environment_SingleIdentifierID,
    Suite_SingleIdentifierID_Functions
    {}

contract SingleIdentifierIDTest_ProtocolFlow_Upgraded is
    Environment_SingleIdentifierID_Upgraded,
    Suite_SingleIdentifierID_Functions
    {}

contract SingleIdentifierIDTest_Upgradeable is
    Environment_SingleIdentifierID,
    Suite_SingleIdentifierID_Upgradeable
    {}
