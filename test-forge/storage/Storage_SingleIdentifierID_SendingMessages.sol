// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "lib/forge-std/src/Test.sol";

import {Emitter} from "contracts/types/Structs.sol";
import {IConnector} from "contracts/interfaces/IConnector.sol";
import {SingleIdentifierRegistry} from "contracts/SingleIdentifierRegistry.sol";
import {SingleRouter} from "contracts/SingleRouter.sol";

import {Harness_SingleIdentifierID} from "test-forge/harness/Harness_SingleIdentifierID.sol";

abstract contract Storage_SingleIdentifierID_SendingMessages is Test {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    Harness_SingleIdentifierID public singleId;
    SingleIdentifierRegistry public registry;
    SingleRouter public router;

    address public admin = 0x0d0D5Ff3cFeF8B7B2b1cAC6B6C27Fd0846c09361;
    address public operator = 0x381c031bAA5995D0Cc52386508050Ac947780815;
    uint256 public targetChainId = 8453;
    Emitter public emitter;
    uint32 public connectorId = 2;
    uint256 public fee = 2e15;
    bytes32 public schemaId = 0xe45274bdf4f35168aa5f09f55498946a069da81f136104113e316a949ae01b37;

    address public sender;

    function _prepareEnv() internal virtual;

    function setUp() public virtual {
        _prepareEnv();

        sender = makeAddr("sender");
        vm.label(sender, "Sender");

        emitter = Emitter(
            keccak256("emitterId"),
            schemaId,
            9999999999,
            fee,
            block.chainid,
            sender
        );
    }
}
