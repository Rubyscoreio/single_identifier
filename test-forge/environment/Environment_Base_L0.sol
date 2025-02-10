// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {SetConfigParam} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import {UlnConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";

import {LayerZeroConnector} from "contracts/connectors/LayerZeroConnector.sol";
import {Storage_SingleIdentifierID_SendingMessages} from "test-forge/storage/Storage_SingleIdentifierID_SendingMessages.sol";

abstract contract Environment_Base_L0 is Storage_SingleIdentifierID_SendingMessages {

    function reconfigureConnector(address l0Dvn) internal {

    }
}
