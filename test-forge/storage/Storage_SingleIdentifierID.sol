// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {Base_Storage} from "./Base_Storage.sol";

import {IConnector} from "contracts/interfaces/IConnector.sol";
import {SingleIdentifierID} from "contracts/SingleIdentifierID.sol";
import {SingleIdentifierRegistry} from "contracts/SingleIdentifierRegistry.sol";
import {SingleRouter} from "contracts/SingleRouter.sol";

import {Harness_SingleIdentifierID} from "test-forge/harness/Harness_SingleIdentifierID.sol";

abstract contract Storage_SingleIdentifierID is Base_Storage {
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    address public constant _defaultAdmin = address(0xA11CE);
    address public constant _defaultOperator = address(0xB0B);
    uint256 public constant _defaultFee = 1e9;
    uint256 public constant _defaultQuote = 50000e9;
    string public constant _testMnemonic = "test test test test test test test test test test test junk";

    IConnector public connector;

    Harness_SingleIdentifierID public singleId;
    SingleIdentifierRegistry public registry;
    SingleRouter public router;

}
