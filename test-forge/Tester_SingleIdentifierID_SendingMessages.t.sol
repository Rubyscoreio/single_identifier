// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Environment_SingleIdentifierID_SendingMessages} from "./environment/Environment_SingleIdentifierID_SendingMessages.sol";
import {Environment_SingleIdentifierID_SendingMessages_Hyperlane} from "./environment/Environment_SingleIdentifierID_SendingMessages_Hyperlane.sol";
import {Environment_SingleIdentifierID_SendingMessages_LayerZero} from "./environment/Environment_SingleIdentifierID_SendingMessages_LayerZero.sol";

import {Suite_SingleIdentifierID_SendingMessages} from "./suite/Suite_SingleIdentifierID_SendingMessages.sol";
import {Suite_SingleIdentifierID_OnchainUpgrade} from "./suite/Suite_SingleIdentifierID_OnchainUpgrade.sol";


contract SingleIdentifierIDTest_SendingMessages_Optimism_Same is
    Environment_SingleIdentifierID_SendingMessages,
    Suite_SingleIdentifierID_SendingMessages
{
    constructor() Environment_SingleIdentifierID_SendingMessages("optimism") {}
}

contract SingleIdentifierIDTest_SendingMessages_Optimism_Hyperlane is
    Environment_SingleIdentifierID_SendingMessages_Hyperlane,
    Suite_SingleIdentifierID_SendingMessages
{
    constructor() Environment_SingleIdentifierID_SendingMessages_Hyperlane("optimism") {}
}

contract SingleIdentifierIDTest_SendingMessages_Optimism_L0 is
    Environment_SingleIdentifierID_SendingMessages_LayerZero,
    Suite_SingleIdentifierID_SendingMessages
{
    constructor() Environment_SingleIdentifierID_SendingMessages_LayerZero("optimism") {}
}


contract SingleIdentifierIDTest_SendingMessages_Linea_Same is
Environment_SingleIdentifierID_SendingMessages,
Suite_SingleIdentifierID_SendingMessages
{
    constructor() Environment_SingleIdentifierID_SendingMessages("linea") {}
}

contract SingleIdentifierIDTest_SendingMessages_Linea_Hyperlane is
    Environment_SingleIdentifierID_SendingMessages_Hyperlane,
    Suite_SingleIdentifierID_SendingMessages
{
    constructor() Environment_SingleIdentifierID_SendingMessages_Hyperlane("linea") {}
}

contract SingleIdentifierIDTest_SendingMessages_Linea_L0 is
    Environment_SingleIdentifierID_SendingMessages_LayerZero,
    Suite_SingleIdentifierID_SendingMessages
{
    constructor() Environment_SingleIdentifierID_SendingMessages_LayerZero("linea") {}
}


contract SingleIdentifierIDTest_SendingMessages_Arbitrum_Same is
Environment_SingleIdentifierID_SendingMessages,
Suite_SingleIdentifierID_SendingMessages
{
    constructor() Environment_SingleIdentifierID_SendingMessages("arbitrum") {}
}

contract SingleIdentifierIDTest_SendingMessages_Arbitrum_Hyperlane is
    Environment_SingleIdentifierID_SendingMessages_Hyperlane,
    Suite_SingleIdentifierID_SendingMessages
{
    constructor() Environment_SingleIdentifierID_SendingMessages_Hyperlane("arbitrum") {}
}

contract SingleIdentifierIDTest_SendingMessages_Arbitrum_L0 is
    Environment_SingleIdentifierID_SendingMessages_LayerZero,
    Suite_SingleIdentifierID_SendingMessages
{
    constructor() Environment_SingleIdentifierID_SendingMessages_LayerZero("arbitrum") {}
}


contract SingleIdentifierIDTest_SendingMessages_Base_Same is
Environment_SingleIdentifierID_SendingMessages,
Suite_SingleIdentifierID_SendingMessages
{
    constructor() Environment_SingleIdentifierID_SendingMessages("base") {}
}

contract SingleIdentifierIDTest_SendingMessages_Base_Hyperlane is
    Environment_SingleIdentifierID_SendingMessages_Hyperlane,
    Suite_SingleIdentifierID_SendingMessages
{
    constructor() Environment_SingleIdentifierID_SendingMessages_Hyperlane("base") {}
}

contract SingleIdentifierIDTest_SendingMessages_Base_L0 is
    Environment_SingleIdentifierID_SendingMessages_LayerZero,
    Suite_SingleIdentifierID_SendingMessages
{
    constructor() Environment_SingleIdentifierID_SendingMessages_LayerZero("base") {}
}


contract SingleIdentifierIDTest_SendingMessages_Scroll_Same is
    Environment_SingleIdentifierID_SendingMessages,
    Suite_SingleIdentifierID_SendingMessages
{
    constructor() Environment_SingleIdentifierID_SendingMessages("scroll") {}
}

contract SingleIdentifierIDTest_SendingMessages_Scroll_Hyperlane is
    Environment_SingleIdentifierID_SendingMessages_Hyperlane,
    Suite_SingleIdentifierID_SendingMessages
{
    constructor() Environment_SingleIdentifierID_SendingMessages_Hyperlane("scroll") {}
}

contract SingleIdentifierIDTest_SendingMessages_Scroll_L0 is
    Environment_SingleIdentifierID_SendingMessages_LayerZero,
    Suite_SingleIdentifierID_SendingMessages
{
    constructor() Environment_SingleIdentifierID_SendingMessages_LayerZero("scroll") {}
}


contract SingleIdentifierIDTest_SendingMessages_ZkEVM_Same is
    Environment_SingleIdentifierID_SendingMessages,
    Suite_SingleIdentifierID_SendingMessages
{
    constructor() Environment_SingleIdentifierID_SendingMessages("zkevm") {}
}

contract SingleIdentifierIDTest_SendingMessages_ZkEVM_Hyperlane is
    Environment_SingleIdentifierID_SendingMessages_Hyperlane,
    Suite_SingleIdentifierID_SendingMessages
{
    constructor() Environment_SingleIdentifierID_SendingMessages_Hyperlane("zkevm") {}
}

contract SingleIdentifierIDTest_SendingMessages_ZkEVM_L0 is
    Environment_SingleIdentifierID_SendingMessages_LayerZero,
    Suite_SingleIdentifierID_SendingMessages
{
    constructor() Environment_SingleIdentifierID_SendingMessages_LayerZero("zkevm") {}
}


contract SingleIdentifierIDTest_SendingMessages_Taiko_Same is
Environment_SingleIdentifierID_SendingMessages,
Suite_SingleIdentifierID_SendingMessages
{
    constructor() Environment_SingleIdentifierID_SendingMessages("taiko") {}
}

contract SingleIdentifierIDTest_SendingMessages_Taiko_Hyperlane is
    Environment_SingleIdentifierID_SendingMessages_Hyperlane,
    Suite_SingleIdentifierID_SendingMessages
{
    constructor() Environment_SingleIdentifierID_SendingMessages_Hyperlane("taiko") {}
}

contract SingleIdentifierIDTest_SendingMessages_Taiko_L0 is
    Environment_SingleIdentifierID_SendingMessages_LayerZero,
    Suite_SingleIdentifierID_SendingMessages
{
    constructor() Environment_SingleIdentifierID_SendingMessages_LayerZero("taiko") {}
}
