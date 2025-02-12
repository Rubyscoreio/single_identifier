// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import {Base_SingleIdentifierId_Functions} from "./Base_SingleIdentifierId_Functions.sol";
import {EmitterFull} from "test-forge/harness/Harness_SingleIdentifierID.sol";

import {SingleIdentifierID} from "contracts/SingleIdentifierID.sol";

abstract contract Function_SingleIdentifierId_AuthorizeUpgrade is Base_SingleIdentifierId_Functions {

    /**
        Target: SingleIdentifierID - _authorizeUpgrade
        Checks: Correct execution
        Flow: _authorizeUpgrade function called from an operator address with the correct params
        Expects:
            - _authorizeUpgrade executes successfully
    */
    function testFuzz_AuthorizeUpgrade_Ok(
        address _operator,
        address _newImplementation
    ) public {
        /// Preparing environment
        singleId.helper_grantRole(OPERATOR_ROLE, _operator);

        /// Executing function
        vm.prank(_operator);
        singleId.exposed_authorizeUpgrade(_newImplementation);
    }

    /**
        Target: SingleIdentifierID - _authorizeUpgrade
        Checks: Revert when called from non-operator address
        Flow: _authorizeUpgrade function called from a non-operator address with the correct params
        Expects:
            - execution reverts with the 'AccessControl: account 0x... is missing role 0x...' error
    */
    function testFuzz_AuthorizeUpgrade_RevertIf_SenderIsNotAnOperator(
        address _newImplementation
    ) public {
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                StringsUpgradeable.toHexString(address(this)),
                " is missing role ",
                StringsUpgradeable.toHexString(uint256(OPERATOR_ROLE), 32)
            )
        );

        /// Executing function
        singleId.exposed_authorizeUpgrade(_newImplementation);
    }

}
