// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Base_SingleIdentifierId_Functions} from "./Base_SingleIdentifierId_Functions.sol";
import {EmitterFull} from "test-forge/harness/Harness_SingleIdentifierID.sol";

import {SingleIdentifierID} from "contracts/SingleIdentifierID.sol";

abstract contract Function_SingleIdentifierId_WithdrawEmitter is Base_SingleIdentifierId_Functions {

    /**
        Target: SingleIdentifierID - withdraw (emitter)
        Checks: Correct execution
        Restrictions:
            - _emitter.emitterId can't be empty
            - _receiver can't be zero address
        Flow: withdraw function called with the correct params
        Expects:
            - emitter balance set to 0
            - balance of the receiver increased by the emitter balance
            - call to _receiver should be sent with the correct value
            - Withdrawal event was emitted with the correct data
    */
    function test_WithdrawEmitter_Ok(
        EmitterFull memory _emitter,
        address payable _receiver,
        uint256 _amount
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.basic.emitterId != bytes32(0));
        vm.assume(_receiver != address(0));
        assumePayable(_receiver);

        /// Preparing environment
        singleId.helper_setEmitter(_emitter);
        singleId.helper_setEmitterBalance(_emitter.basic.emitterId, _amount);

        vm.deal(address(singleId), _amount);

        uint256 balanceSingleIdBefore = address(singleId).balance;
        uint256 balanceReceiverBefore = _receiver.balance;

        vm.expectCall(
            _receiver,
            _amount,
            ""
        );

        vm.expectEmit();
        emit SingleIdentifierID.Withdrawal(_receiver, _amount);
        vm.prank(_emitter.basic.owner);
        // Executing function
        singleId.withdraw(
            _emitter.basic.emitterId,
            _receiver
        );

        /// Asserting expectations
        uint256 balanceSingleIdAfter = address(singleId).balance;
        uint256 balanceEmitterAfter = singleId.emittersBalances(_emitter.basic.emitterId);
        uint256 balanceReceiverAfter = _receiver.balance;

        assertEq(balanceEmitterAfter, 0, "Emitter balance was not set to 0");
        assertEq(balanceSingleIdAfter, balanceSingleIdBefore - _amount, "SingleId balance was changed incorrectly");
        assertEq(balanceReceiverAfter, balanceReceiverBefore + _amount, "Receiver balance was changed incorrectly");
    }

    /**
        Target: SingleIdentifierID - withdraw (emitter)
        Checks: Revert when called with a non-existent emitter
        Restrictions:
            - _receiver can't be zero address
        Flow: withdraw function called with the non-existent emitter id while other params are correct
        Expects:
            - execution reverts with the 'EmitterNotExists()' error
    */
    function test_WithdrawEmitter_RevertIf_EmitterNotExists(
        EmitterFull memory _emitter,
        address payable _receiver,
        uint256 _amount
    ) public {
        /// Validating restrictions
        vm.assume(_receiver != address(0));

        /// Preparing environment
        singleId.helper_setEmitterBalance(_emitter.basic.emitterId, _amount);

        vm.expectRevert(abi.encodeWithSignature("EmitterNotExists()"));
        vm.prank(_emitter.basic.owner);
        // Executing function
        singleId.withdraw(
            _emitter.basic.emitterId,
            payable(_receiver)
        );
    }

    /**
        Target: SingleIdentifierID - withdraw (emitter)
        Checks: Revert when passed receiver is zero address
        Restrictions:
            - _emitter.emitterId can't be empty
        Flow: withdraw function called passing zero address as a receiver while other params are correct
        Expects:
            - reverts with the 'AddressIsZero()' error
    */
    function test_WithdrawEmitter_RevertIf_ReceiverIsZero(
        EmitterFull memory _emitter,
        uint256 _amount
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.basic.emitterId != bytes32(0));

        /// Preparing environment
        singleId.helper_setEmitter(_emitter);
        singleId.helper_setEmitterBalance(_emitter.basic.emitterId, _amount);

        vm.expectRevert(abi.encodeWithSignature("AddressIsZero()"));
        vm.prank(_emitter.basic.owner);
        // Executing function
        singleId.withdraw(
            _emitter.basic.emitterId,
            payable(address(0))
        );
    }

    /**
        Target: SingleIdentifierID - withdraw (emitter)
        Checks: Revert when caller is not an emitter owner
        Restrictions:
            - _emitter.emitterId can't be empty
            - _receiver can't be zero address
        Flow: withdraw function called from a non-owner address with correct params
        Expects:
            - reverts with the 'AccessControl: account 0x... is missing role 0x...' error
    */
    function test_WithdrawEmitter_RevertIf_SenderIsNotAnEmitter(
        EmitterFull memory _emitter,
        address _sender,
        address payable _receiver,
        uint256 _amount
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.basic.emitterId != bytes32(0));
        vm.assume(_receiver != address(0));
        vm.assume(_sender != _emitter.basic.owner);

        /// Preparing environment
        singleId.helper_setEmitter(_emitter);
        singleId.helper_setEmitterBalance(_emitter.basic.emitterId, _amount);

        vm.expectRevert(abi.encodeWithSignature("SenderNotEmitter()"));
        vm.prank(_sender);
        // Executing function
        singleId.withdraw(
            _emitter.basic.emitterId,
            payable(_receiver)
        );
    }

    /**
        Target: SingleIdentifierID - withdraw (emitter)
        Checks: Revert when failed to send Ether
        Restrictions:
            - _emitter.emitterId can't be empty
            - _receiver can't be zero address
        Flow: withdraw function called with the correct params
        Mocks:
            - receiver.call should revert
        Expects:
            - reverts with the 'Failed to send Ether' error
    */
    function test_WithdrawEmitter_RevertIf_FailedToSendEther(
        EmitterFull memory _emitter,
        address payable _receiver,
        uint256 _amount
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.basic.emitterId != bytes32(0));
        vm.assume(_receiver != address(0));
        assumePayable(_receiver);

        /// Preparing environment
        singleId.helper_setEmitter(_emitter);
        singleId.helper_setEmitterBalance(_emitter.basic.emitterId, _amount);

        vm.deal(address(singleId), _amount);

        bytes memory callData = "";
        bytes memory revertData = "";
        vm.mockCallRevert(_receiver, callData, revertData);

        vm.expectRevert("Failed to send Ether");
        vm.prank(_emitter.basic.owner);
        // Executing function
        singleId.withdraw(
            _emitter.basic.emitterId,
            payable(_receiver)
        );
    }

}
