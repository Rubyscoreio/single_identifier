// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import {Base_SingleIdentifierId_Functions} from "./Base_SingleIdentifierId_Functions.sol";
import {EmitterFull} from "test-forge/harness/Harness_SingleIdentifierID.sol";

import {SingleIdentifierID} from "contracts/SingleIdentifierID.sol";

abstract contract Function_SingleIdentifierId_SetEmitterBalance is Base_SingleIdentifierId_Functions {

    /**
        Target: SingleIdentifierID - setEmitterBalance
        Checks: Correct execution
        Restrictions:
            - _emitter.emitterId can't be empty
        Flow: setEmitterBalance function called from an admin address with the correct params
        Expects:
            - router variable was set to _newBalance
            - SetRouter event was emitted with the correct data
    */
    function testFuzz_SetEmitterBalance_Ok(
        EmitterFull memory _emitter,
        uint256 _newBalance,
        address _admin
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.basic.emitterId != bytes32(0));

        /// Preparing environment
        singleId.helper_grantRole(DEFAULT_ADMIN_ROLE, _admin);

        singleId.helper_setEmitter(_emitter);

        vm.expectEmit();
        emit SingleIdentifierID.SetEmitterBalance(_emitter.basic.emitterId, _newBalance);
        vm.prank(_admin);
        /// Executing function
        singleId.setEmitterBalance(_emitter.basic.emitterId, _newBalance);

        /// Asserting expectations
        assertEq(singleId.emittersBalances(_emitter.basic.emitterId), _newBalance, "Router was set incorrectly");
    }

    /**
        Target: SingleIdentifierID - setEmitterBalance
        Checks: Revert when called from non-admin address
        Restrictions:
            - _emitter.emitterId can't be empty
        Flow: setEmitterBalance function called from a non-admin address with the correct params
        Expects:
            - execution reverts with the 'AccessControl: account 0x... is missing role 0x...' error
    */
    function testFuzz_SetEmitterBalance_RevertIf_SenderIsNotAnAdmin(
        EmitterFull memory _emitter,
        uint256 _newBalance,
        address _sender
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.basic.emitterId != bytes32(0));

        /// Preparing environment
        singleId.helper_setEmitter(_emitter);

        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                StringsUpgradeable.toHexString(_sender),
                " is missing role ",
                StringsUpgradeable.toHexString(uint256(DEFAULT_ADMIN_ROLE), 32)
            )
        );
        vm.prank(_sender);
        /// Executing function
        singleId.setEmitterBalance(_emitter.basic.emitterId, _newBalance);
    }

    /**
        Target: SingleIdentifierID - setEmitterBalance
        Checks: Revert when called with a non-existent emitter
        Restrictions:
        Flow: setEmitterBalance function called from an admin address with the non-existent emitter id while other params are correct
        Expects:
            - execution reverts with the 'EmitterNotExists()' error
    */
    function testFuzz_SetEmitterBalance_RevertIf_EmitterNotExists(
        EmitterFull memory _emitter,
        uint256 _newBalance,
        address _admin
    ) public {
        /// Preparing environment
        singleId.helper_grantRole(DEFAULT_ADMIN_ROLE, _admin);

        vm.expectRevert(abi.encodeWithSignature("EmitterNotExists()"));
        vm.prank(_admin);
        /// Executing function
        singleId.setEmitterBalance(_emitter.basic.emitterId, _newBalance);
    }
}
