// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Environment_SingleIdentifierID} from "./environment/Environment_SingleIdentifierID.sol";
import {Environment_SingleIdentifierID_Upgraded} from "./environment/Environment_SingleIdentifierID_Upgraded.sol";
import {Environment_SingleIdentifierID_SendingMessages_Local} from "./environment/Environment_SingleIdentifierID_SendingMessages_Local.sol";
import {Environment_SingleIdentifierID_SendingMessages_Optimism_L0} from "./environment/Environment_SingleIdentifierID_SendingMessages_Optimism_L0.sol";
import {Environment_SingleIdentifierID_SendingMessages_Optimism_SameChain} from "./environment/Environment_SingleIdentifierID_SendingMessages_Optimism_SameChain.sol";
import {Environment_SingleIdentifierID_SendingMessages_Linea_L0} from "./environment/Environment_SingleIdentifierID_SendingMessages_Linea_L0.sol";
import {Environment_SingleIdentifierID_SendingMessages_Linea_SameChain} from "./environment/Environment_SingleIdentifierID_SendingMessages_Linea_SameChain.sol";
import {Environment_SingleIdentifierID_SendingMessages_Arbitrum_L0} from "./environment/Environment_SingleIdentifierID_SendingMessages_Arbitrum_L0.sol";
import {Environment_SingleIdentifierID_SendingMessages_Arbitrum_SameChain} from "./environment/Environment_SingleIdentifierID_SendingMessages_Arbitrum_SameChain.sol";
import {Environment_SingleIdentifierID_SendingMessages_Base_L0} from "./environment/Environment_SingleIdentifierID_SendingMessages_Base_L0.sol";
import {Environment_SingleIdentifierID_SendingMessages_Base_SameChain} from "./environment/Environment_SingleIdentifierID_SendingMessages_Base_SameChain.sol";
import {Environment_SingleIdentifierID_SendingMessages_Scroll_L0} from "./environment/Environment_SingleIdentifierID_SendingMessages_Scroll_L0.sol";
import {Environment_SingleIdentifierID_SendingMessages_Scroll_SameChain} from "./environment/Environment_SingleIdentifierID_SendingMessages_Scroll_SameChain.sol";
import {Environment_SingleIdentifierID_SendingMessages_ZkEVM_L0} from "./environment/Environment_SingleIdentifierID_SendingMessages_ZkEVM_L0.sol";
import {Environment_SingleIdentifierID_SendingMessages_ZkEVM_SameChain} from "./environment/Environment_SingleIdentifierID_SendingMessages_ZkEVM_SameChain.sol";
import {Environment_SingleIdentifierID_SendingMessages_Taiko_L0} from "./environment/Environment_SingleIdentifierID_SendingMessages_Taiko_L0.sol";
import {Environment_SingleIdentifierID_SendingMessages_Taiko_SameChain} from "./environment/Environment_SingleIdentifierID_SendingMessages_Taiko_SameChain.sol";

import {Suite_SingleIdentifierID_Administrative} from "./suite/Suite_SingleIdentifierID_Administrative.sol";
import {Suite_SingleIdentifierID_Upgradeable} from "./suite/Suite_SingleIdentifierID_Upgradeable.sol";
import {Suite_SingleIdentifierID_SendingMessages} from "./suite/Suite_SingleIdentifierID_SendingMessages.sol";
import {Suite_SingleIdentifierID_ProtocolFlow} from "./suite/Suite_SingleIdentifierID_ProtocolFlow.sol";
import {Suite_SingleIdentifierID_OnchainUpgrade} from "./suite/Suite_SingleIdentifierID_OnchainUpgrade.sol";

contract SingleIdentifierIDTest_Administrative is
    Environment_SingleIdentifierID,
    Suite_SingleIdentifierID_Administrative
    {}

contract SingleIdentifierIDTest_Administrative_Upgraded is
    Environment_SingleIdentifierID_Upgraded,
    Suite_SingleIdentifierID_Administrative
    {}

contract SingleIdentifierIDTest_ProtocolFlow is
    Environment_SingleIdentifierID,
    Suite_SingleIdentifierID_ProtocolFlow
    {}

contract SingleIdentifierIDTest_ProtocolFlow_Upgraded is
    Environment_SingleIdentifierID_Upgraded,
    Suite_SingleIdentifierID_ProtocolFlow
    {}

contract SingleIdentifierIDTest_Upgradeable is
    Environment_SingleIdentifierID,
    Suite_SingleIdentifierID_Upgradeable
    {}

contract SingleIdentifierIDTest_SendingMessages is
    Environment_SingleIdentifierID_SendingMessages_Local,
    Suite_SingleIdentifierID_SendingMessages
    {}

contract SingleIdentifierIDTest_SendingMessages_Optimism_L0 is
    Environment_SingleIdentifierID_SendingMessages_Optimism_L0,
    Suite_SingleIdentifierID_SendingMessages,
    Suite_SingleIdentifierID_OnchainUpgrade
    {}

contract SingleIdentifierIDTest_SendingMessages_Optimism_Same is
    Environment_SingleIdentifierID_SendingMessages_Optimism_SameChain,
    Suite_SingleIdentifierID_SendingMessages,
    Suite_SingleIdentifierID_OnchainUpgrade
    {}

contract SingleIdentifierIDTest_SendingMessages_Linea_L0 is
    Environment_SingleIdentifierID_SendingMessages_Linea_L0,
    Suite_SingleIdentifierID_SendingMessages,
    Suite_SingleIdentifierID_OnchainUpgrade
    {}

contract SingleIdentifierIDTest_SendingMessages_Linea_Same is
    Environment_SingleIdentifierID_SendingMessages_Linea_SameChain,
    Suite_SingleIdentifierID_SendingMessages,
    Suite_SingleIdentifierID_OnchainUpgrade
    {}

contract SingleIdentifierIDTest_SendingMessages_Arbitrum_L0 is
    Environment_SingleIdentifierID_SendingMessages_Arbitrum_L0,
    Suite_SingleIdentifierID_SendingMessages,
    Suite_SingleIdentifierID_OnchainUpgrade
    {}

contract SingleIdentifierIDTest_SendingMessages_Arbitrum_Same is
    Environment_SingleIdentifierID_SendingMessages_Arbitrum_SameChain,
    Suite_SingleIdentifierID_SendingMessages,
    Suite_SingleIdentifierID_OnchainUpgrade
    {}

contract SingleIdentifierIDTest_SendingMessages_Base_L0 is
    Environment_SingleIdentifierID_SendingMessages_Base_L0,
    Suite_SingleIdentifierID_SendingMessages,
    Suite_SingleIdentifierID_OnchainUpgrade
    {}

contract SingleIdentifierIDTest_SendingMessages_Base_Same is
    Environment_SingleIdentifierID_SendingMessages_Base_SameChain,
    Suite_SingleIdentifierID_SendingMessages,
    Suite_SingleIdentifierID_OnchainUpgrade
    {}

contract SingleIdentifierIDTest_SendingMessages_Scroll_L0 is
    Environment_SingleIdentifierID_SendingMessages_Scroll_L0,
    Suite_SingleIdentifierID_SendingMessages,
    Suite_SingleIdentifierID_OnchainUpgrade
    {}

contract SingleIdentifierIDTest_SendingMessages_Scroll_Same is
    Environment_SingleIdentifierID_SendingMessages_Scroll_SameChain,
    Suite_SingleIdentifierID_SendingMessages,
    Suite_SingleIdentifierID_OnchainUpgrade
    {}

contract SingleIdentifierIDTest_SendingMessages_ZkEVM_L0 is
    Environment_SingleIdentifierID_SendingMessages_ZkEVM_L0,
    Suite_SingleIdentifierID_SendingMessages,
    Suite_SingleIdentifierID_OnchainUpgrade
{}

contract SingleIdentifierIDTest_SendingMessages_ZkEVM_Same is
    Environment_SingleIdentifierID_SendingMessages_ZkEVM_SameChain,
    Suite_SingleIdentifierID_SendingMessages,
    Suite_SingleIdentifierID_OnchainUpgrade
{}

contract SingleIdentifierIDTest_SendingMessages_Taiko_L0 is
    Environment_SingleIdentifierID_SendingMessages_Taiko_L0,
    Suite_SingleIdentifierID_SendingMessages,
    Suite_SingleIdentifierID_OnchainUpgrade
{}

contract SingleIdentifierIDTest_SendingMessages_Taiko_Same is
    Environment_SingleIdentifierID_SendingMessages_Taiko_SameChain,
    Suite_SingleIdentifierID_SendingMessages,
    Suite_SingleIdentifierID_OnchainUpgrade
{}
