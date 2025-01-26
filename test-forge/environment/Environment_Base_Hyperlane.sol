// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Storage_SingleIdentifierID_SendingMessages} from "test-forge/storage/Storage_SingleIdentifierID_SendingMessages.sol";

abstract contract Environment_Base_Hyperlane is Storage_SingleIdentifierID_SendingMessages {

    function reconfigureConnector() internal {
        connectorId = 1;
    }
}
