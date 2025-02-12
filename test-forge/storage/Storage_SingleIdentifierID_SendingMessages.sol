// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Storage_SingleIdentifierID_Fork} from "./Storage_SingleIdentifierID_Fork.sol";

import {Emitter} from "contracts/types/Structs.sol";
import {EmitterFull} from "test-forge/harness/Harness_SingleIdentifierID.sol";
import {IConnector} from "contracts/interfaces/IConnector.sol";
import {SingleIdentifierRegistry} from "contracts/SingleIdentifierRegistry.sol";
import {SingleRouter} from "contracts/SingleRouter.sol";

import {Harness_SingleIdentifierID} from "test-forge/harness/Harness_SingleIdentifierID.sol";

abstract contract Storage_SingleIdentifierID_SendingMessages is Storage_SingleIdentifierID_Fork {
    uint256 public targetChainId = 8453;
    Emitter public emitter;
    uint32 public connectorId;
    uint256 public fee = 2e15;
    bytes32 public schemaId = 0xe45274bdf4f35168aa5f09f55498946a069da81f136104113e316a949ae01b37;

    address public sender;

    function setUp() public override {
        super.setUp();

        sender = makeAddr("sender");
        vm.label(sender, "Sender");

        emitter = Emitter(
            keccak256("emitterId"),
            schemaId,
            9999999999,
            fee,
            targetChainId,
            sender
        );

        singleId.helper_setEmitter(EmitterFull(emitter, 0));
    }
}
