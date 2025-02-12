// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Environment_SingleIdentifierID_SendingMessages} from "./Environment_SingleIdentifierID_SendingMessages.sol";

abstract contract Environment_SingleIdentifierID_SendingMessages_Hyperlane is Environment_SingleIdentifierID_SendingMessages {

    constructor(string memory _chainName) Environment_SingleIdentifierID_SendingMessages(_chainName) {
        connectorId = 1;
    }
}
