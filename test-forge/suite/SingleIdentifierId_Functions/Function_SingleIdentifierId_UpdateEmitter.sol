// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Base_SingleIdentifierId_Functions} from "./Base_SingleIdentifierId_Functions.sol";
import {EmitterFull} from "test-forge/harness/Harness_SingleIdentifierID.sol";

import {SingleIdentifierID} from "contracts/SingleIdentifierID.sol";

abstract contract Function_SingleIdentifierId_UpdateEmitter is Base_SingleIdentifierId_Functions {

    /**
        Target: SingleIdentifierID - updateEmitter
        Checks: Correct execution
        Restrictions:
            - _emitter.emitterId can't be empty
            - _newEmitter can't be zero
        Flow: updateEmitter function called with the correct params
        Expects:
            - new emitter owner was set
            - UpdateEmitter event was emitted with the correct data
    */
    function test_UpdateEmitter_Ok(
        EmitterFull memory _emitter,
        address _newEmitter,
        address _operator
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.basic.emitterId != bytes32(0));
        vm.assume(_newEmitter != address(0));

        /// Preparing environment
        singleId.helper_grantRole(OPERATOR_ROLE, _operator);

        vm.label(_operator, "operator");

        singleId.helper_setEmitter(_emitter);

        vm.expectEmit();
        emit SingleIdentifierID.UpdateEmitter(_emitter.basic.emitterId, _newEmitter);
        vm.prank(_operator);
        // Executing function
        singleId.updateEmitter(
            _emitter.basic.emitterId,
            _newEmitter
        );

        /// Asserting expectations
        (,,,,,address newOwner) = singleId.emitters(_emitter.basic.emitterId);
        assertEq(newOwner, _newEmitter, "New emitter owner was not set");
    }

    /**
        Target: SingleIdentifierID - updateEmitter
        Checks: Revert when called with a non-existent emitter
        Restrictions:
            - _newEmitter can't be zero
        Flow: updateEmitter function called with the non-existent emitter id while other params are correct
        Expects:
            - reverts with the 'EmitterNotExists()' error
    */
    function test_UpdateEmitter_RevertIf_EmitterNotExists(
        EmitterFull memory _emitter,
        address _newEmitter,
        address _operator
    ) public {
        /// Validating restrictions
        vm.assume(_newEmitter != address(0));

        /// Preparing environment
        singleId.helper_grantRole(OPERATOR_ROLE, _operator);

        vm.label(_operator, "operator");

        vm.prank(_operator);
        vm.expectRevert(abi.encodeWithSignature("EmitterNotExists()"));
        // Executing function
        singleId.updateEmitter(
            _emitter.basic.emitterId,
            _newEmitter
        );
    }

    /**
        Target: SingleIdentifierID - updateEmitter
        Checks: Revert when called from non-operator address
        Restrictions:
            - _emitter.emitterId can't be empty
            - _newEmitter can't be zero
        Flow: updateEmitter function called with the correct params from a non-operator address
        Expects:
            - execution reverts with the 'AccessControl: account 0x... is missing role 0x...' error
    */
    function test_UpdateEmitter_RevertIf_SenderIsNotAnOperator(
        EmitterFull memory _emitter,
        address _newEmitter
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.basic.emitterId != bytes32(0));
        vm.assume(_newEmitter != address(0));

        /// Preparing environment
        singleId.helper_setEmitter(_emitter);

        expectMissingRole(address(this), OPERATOR_ROLE);
        // Executing function
        singleId.updateEmitter(
            _emitter.basic.emitterId,
            _newEmitter
        );
    }

    /**
        Target: SingleIdentifierID - updateEmitter
        Checks: Revert when called new emitter owner is zero
        Restrictions:
            - _emitter.emitterId can't be empty
        Flow: updateEmitter function called with zero address as a new emitter owner while other params are correct
        Expects:
            - reverts with the 'AddressIsZero()' error
    */
    function test_UpdateEmitter_RevertIf_NewEmitterOwnerIsZero(
        EmitterFull memory _emitter,
        address _operator
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.basic.emitterId != bytes32(0));

        /// Preparing environment
        singleId.helper_grantRole(OPERATOR_ROLE, _operator);

        vm.label(_operator, "operator");

        singleId.helper_setEmitter(_emitter);

        vm.expectRevert(abi.encodeWithSignature("AddressIsZero()"));
        vm.prank(_operator);
        // Executing function
        singleId.updateEmitter(
            _emitter.basic.emitterId,
            address(0)
        );
    }
}
