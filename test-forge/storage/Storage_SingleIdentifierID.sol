// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "lib/forge-std/src/Test.sol";

import {SingleIdentifierID} from "contracts/SingleIdentifierID.sol";
import {SingleIdentifierRegistry} from "contracts/SingleIdentifierRegistry.sol";
import {SingleRouter} from "contracts/SingleRouter.sol";
import {LayerZeroConnector} from "contracts/connectors/LayerZeroConnector.sol";
import {SameChainConnector} from "contracts/connectors/SameChainConnector.sol";

import {Harness_SingleIdentifierID} from "test-forge/harness/Harness_SingleIdentifierID.sol";

abstract contract Storage_SingleIdentifierID is Test {
    address public constant _defaultAdmin = address(0xA11CE);
    address public constant _defaultOperator = address(0xB0B);
    uint256 public constant _defaultFee = 1e9;

    SameChainConnector public sameChainConnector;
    LayerZeroConnector public lzConnector;

    Harness_SingleIdentifierID public singleId;
    SingleIdentifierRegistry public registry;
    SingleRouter public router;

    modifier initContracts(address _admin, address _operator, uint256 _fee) {
//        vm.assumeNoRevert();
        singleId.initialize(
            _fee,
            _admin,
            _operator,
            address(router)
        );

//        vm.assumeNoRevert();
        registry.initialize(
            _operator
        );

//        vm.assumeNoRevert();
        router.initialize(_operator);
        _;
    }

    function _prepareEnv() internal virtual;

    function setUp() public virtual {
        _prepareEnv();
    }
}
