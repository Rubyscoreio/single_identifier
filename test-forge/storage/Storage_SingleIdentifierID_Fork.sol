// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Storage_SingleIdentifierID} from "./Storage_SingleIdentifierID.sol";

import {IConnector} from "contracts/interfaces/IConnector.sol";
import {SingleIdentifierID} from "contracts/SingleIdentifierID.sol";
import {SingleIdentifierRegistry} from "contracts/SingleIdentifierRegistry.sol";
import {SingleRouter} from "contracts/SingleRouter.sol";

import {Harness_SingleIdentifierID} from "test-forge/harness/Harness_SingleIdentifierID.sol";

abstract contract Storage_SingleIdentifierID_Fork is Storage_SingleIdentifierID {
    address public admin = 0x0d0D5Ff3cFeF8B7B2b1cAC6B6C27Fd0846c09361;
    address public operator = 0x381c031bAA5995D0Cc52386508050Ac947780815;
}
