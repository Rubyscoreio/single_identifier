// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Environment_SingleIdentifierID} from "./environment/Environment_SingleIdentifierID.sol";

import {Suite_SingleIdentifierID_Administrative} from "./suite/Suite_SingleIdentifierID_Administrative.sol";
import {Suite_SingleIdentifierID_ProtocolFlow} from "./suite/Suite_SingleIdentifierID_ProtocolFlow.sol";

contract SingleIdentifierIDTest_Administrative is
    Environment_SingleIdentifierID,
    Suite_SingleIdentifierID_Administrative
    {}

contract SingleIdentifierIDTest_ProtocolFlow is
    Environment_SingleIdentifierID,
    Suite_SingleIdentifierID_ProtocolFlow
    {}
