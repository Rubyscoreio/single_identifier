// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Base_SingleIdentifierId_Functions} from "./Base_SingleIdentifierId_Functions.sol";
import {EmitterFull} from "test-forge/harness/Harness_SingleIdentifierID.sol";

abstract contract Function_SingleIdentifierId_UpdateFee is Base_SingleIdentifierId_Functions {

    /**
        Target: SingleIdentifierID - updateFee
        Checks: Correct execution
        Restrictions:
            - _emitter.emitterId can't be empty
        Flow: registerEmitter function called with the correct params
        Expects:
            - new fee for emitter was set
    */
    function test_UpdateFee_Ok(
        EmitterFull memory _emitter,
        uint256 _registeringFee,
        uint256 _updatingFee
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.basic.emitterId != bytes32(0));

        /// Preparing environment
        singleId.helper_setEmitter(_emitter);

        /// Executing function
        vm.prank(_emitter.basic.owner);
        singleId.updateFee(
            _emitter.basic.emitterId,
            _registeringFee,
            _updatingFee
        );

        (,,, uint256 newRegisteringFee, uint256 newUpdatingFee,,) = singleId.getEmitter(_emitter.basic.emitterId);

        /// Asserting expectations
        assertEq(newRegisteringFee, _registeringFee, "Registering fee updated incorrectly");
        assertEq(newUpdatingFee, _updatingFee, "Updating fee updated incorrectly");
    }

    /**
        Target: SingleIdentifierID - updateFee
        Checks: Revert when called with a non-existent emitter
        Restrictions:
        Flow: registerEmitter function called with non-existent emitter id while other params are correct
        Expects:
            - execution reverts with the 'EmitterNotExists()' error
    */
    function test_UpdateFee_RevertIf_EmitterNotExists(
        EmitterFull memory _emitter,
        uint256 _registeringFee,
        uint256 _updatingFee
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.basic.emitterId != bytes32(0));

        vm.expectRevert(abi.encodeWithSignature("EmitterNotExists()"));
        /// Executing function
        vm.prank(_emitter.basic.owner);
        singleId.updateFee(
            _emitter.basic.emitterId,
            _registeringFee,
            _updatingFee
        );
    }

    /**
        Target: SingleIdentifierID - updateFee
        Checks: Revert if caller is not an emitters owner
        Restrictions:
            - _emitter.emitterId can't be empty
        Flow: registerEmitter function called with the correct params from the address that is not emitters owner
        Expects:
            - execution reverts with the "SenderNotEmitter" error
    */
    function test_UpdateFee_RevertIf_SenderIsNotAnEmitter(
        EmitterFull memory _emitter,
        address _sender,
        uint256 _registeringFee,
        uint256 _updatingFee
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.basic.emitterId != bytes32(0));
        vm.assume(_sender != _emitter.basic.owner);

        /// Preparing environment
        singleId.helper_setEmitter(_emitter);

        vm.expectRevert(abi.encodeWithSignature("SenderNotEmitter()"));
        /// Executing function
        vm.prank(_sender);
        singleId.updateFee(
            _emitter.basic.emitterId,
            _registeringFee,
            _updatingFee
        );
    }
}
