// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import {Base_SingleIdentifierId_Functions} from "./Base_SingleIdentifierId_Functions.sol";
import {EmitterFull} from "test-forge/harness/Harness_SingleIdentifierID.sol";

import {SingleIdentifierID} from "contracts/SingleIdentifierID.sol";

abstract contract Function_SingleIdentifierId_SetProtocolFee is Base_SingleIdentifierId_Functions {
    /**
        Target: SingleIdentifierID - setProtocolFee
        Checks: Correct execution
        Flow: setProtocolFee function called from an operator address with the correct params
        Expects:
            - setProtocolFee executed successfully
            - protocolFee variable was set to _fee
            - SetProtocolFee event was emitted with the correct data
    */
    function testFuzz_SetProtocolFee_Ok(
        address _operator,
        uint256 _fee
    ) public {
        /// Preparing environment
        singleId.helper_grantRole(OPERATOR_ROLE, _operator);

        vm.expectEmit();
        emit SingleIdentifierID.SetProtocolFee(_fee);

        /// Executing function
        vm.prank(_operator);
        singleId.setProtocolFee(_fee);

        /// Asserting expectations
        assertEq(singleId.protocolFee(), _fee, "Protocol fee was set incorrectly");
    }

    /**
        Target: SingleIdentifierID - setProtocolFee
        Checks: Revert when called from non-operator address
        Flow: setProtocolFee function called from a non-operator address with the correct params
        Expects:
            - execution reverts with the 'AccessControl: account 0x... is missing role 0x...' error
    */
    function testFuzz_SetProtocolFee_RevertIf_SenderIsNotAnOperator(
        uint256 _fee
    ) public {
        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                StringsUpgradeable.toHexString(address(this)),
                " is missing role ",
                StringsUpgradeable.toHexString(uint256(OPERATOR_ROLE), 32)
            )
        );

        singleId.setProtocolFee(_fee);
    }
}
