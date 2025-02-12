// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Function_SingleIdentifierId_RegisterEmitter} from "./SingleIdentifierId_Functions/Function_SingleIdentifierId_RegisterEmitter.sol";
import {Function_SingleIdentifierId_RegisterSID} from "./SingleIdentifierId_Functions/Function_SingleIdentifierId_RegisterSID.sol";
import {Function_SingleIdentifierId_RegisterSIDWithEmitter} from "./SingleIdentifierId_Functions/Function_SingleIdentifierId_RegisterSIDWithEmitter.sol";
import {Function_SingleIdentifierId_UpdateEmitter} from "./SingleIdentifierId_Functions/Function_SingleIdentifierId_UpdateEmitter.sol";
import {Function_SingleIdentifierId_UpdateFee} from "./SingleIdentifierId_Functions/Function_SingleIdentifierId_UpdateFee.sol";
import {Function_SingleIdentifierId_UpdateSID} from "./SingleIdentifierId_Functions/Function_SingleIdentifierId_UpdateSID.sol";
import {Function_SingleIdentifierId_WithdrawEmitter} from "./SingleIdentifierId_Functions/Function_SingleIdentifierId_WithdrawEmitter.sol";
import {Function_SingleIdentifierId_WithdrawProtocol} from "./SingleIdentifierId_Functions/Function_SingleIdentifierId_WithdrawProtocol.sol";


abstract contract Suite_SingleIdentifierID_Functions is
    Function_SingleIdentifierId_RegisterEmitter,
    Function_SingleIdentifierId_RegisterSID,
    Function_SingleIdentifierId_RegisterSIDWithEmitter,
    Function_SingleIdentifierId_UpdateEmitter,
    Function_SingleIdentifierId_UpdateFee,
    Function_SingleIdentifierId_UpdateSID,
    Function_SingleIdentifierId_WithdrawEmitter,
    Function_SingleIdentifierId_WithdrawProtocol
    {}