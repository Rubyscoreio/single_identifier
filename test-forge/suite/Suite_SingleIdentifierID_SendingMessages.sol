// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import {Emitter} from "contracts/types/Structs.sol";
import {IConnector} from "contracts/interfaces/IConnector.sol";
import {MessageLib} from "contracts/lib/MessageLib.sol";
import {SingleIdentifierID} from "contracts/SingleIdentifierID.sol";
import {SingleRouter} from "contracts/SingleRouter.sol";

import {Storage_SingleIdentifierID_SendingMessages} from "test-forge/storage/Storage_SingleIdentifierID_SendingMessages.sol";

abstract contract Suite_SingleIdentifierID_SendingMessages is Storage_SingleIdentifierID_SendingMessages {
    function test_SendRegisterIDMessage_SendingMessage() public {
        bytes memory data = bytes("Data");
        string memory metadata = "Metadata";

        bytes memory payload = MessageLib.encodeMessage(
            MessageLib.SendMessage(
                emitter.schemaId,
                sender,
                emitter.expirationDate,
                data,
                metadata
            )
        );

        uint256 protocolFee = singleId.protocolFee();

        IConnector connector = router.getRoute(connectorId, targetChainId);
        uint256 quote = connector.quote(targetChainId, payload);

        uint256 totalAmount = emitter.fee + protocolFee + quote;

        vm.deal(sender, totalAmount);

        vm.expectCall(
            address(router),
            abi.encodeWithSelector(
                SingleRouter.getRoute.selector,
                connectorId,
                targetChainId
            )
        );

        vm.expectCall(
            address(connector),
            abi.encodeWithSelector(
                IConnector.quote.selector,
                targetChainId,
                payload
            )
        );

        vm.expectCall(
            address(connector),
            quote,
            abi.encodeWithSelector(
                IConnector.sendMessage.selector,
                targetChainId,
                payload
            )
        );

        vm.expectEmit();
        emit SingleIdentifierID.SentRegisterSIDMessage(emitter.schemaId, connectorId, sender, targetChainId);
        vm.prank(sender);
        singleId.exposed_sendRegisterSIDMessage{value: totalAmount}(
            emitter.emitterId,
            emitter.schemaId,
            connectorId,
            emitter.fee,
            targetChainId,
            emitter.expirationDate,
            data,
            metadata
        );
    }

    function test_SendUpdateSIDMessage_SendingMessage() public {
        bytes memory data = bytes("Data");
        string memory metadata = "Metadata";
        bytes32 sidId = bytes32("sidId");

        bytes memory payload = MessageLib.encodeMessage(
            MessageLib.UpdateMessage(
                sidId,
                emitter.expirationDate,
                data,
                metadata
            )
        );

        uint256 protocolFee = singleId.protocolFee();

        IConnector connector = router.getRoute(connectorId, targetChainId);
        uint256 quote = connector.quote(targetChainId, payload);

        uint256 totalAmount = emitter.fee + protocolFee + quote;

        vm.deal(sender, totalAmount);

        vm.expectCall(
            address(router),
            abi.encodeWithSelector(
                SingleRouter.getRoute.selector,
                connectorId,
                targetChainId
            )
        );

        vm.expectCall(
            address(connector),
            abi.encodeWithSelector(
                IConnector.quote.selector,
                targetChainId,
                payload
            )
        );

        vm.expectCall(
            address(connector),
            quote,
            abi.encodeWithSelector(
                IConnector.sendMessage.selector,
                targetChainId,
                payload
            )
        );

        vm.expectEmit();
        emit SingleIdentifierID.SentUpdateSIDMessage(sidId, connectorId, sender, targetChainId);
        vm.prank(sender);
        singleId.exposed_sendUpdateSIDMessage{value: totalAmount}(
            emitter.emitterId,
            connectorId,
            emitter.fee,
            targetChainId,
            sidId,
            emitter.expirationDate,
            data,
            metadata
        );
    }
}
