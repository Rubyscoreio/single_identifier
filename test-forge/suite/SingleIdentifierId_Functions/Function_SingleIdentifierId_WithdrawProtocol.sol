// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import {Base_SingleIdentifierId_Functions} from "./Base_SingleIdentifierId_Functions.sol";

import {SingleIdentifierID} from "contracts/SingleIdentifierID.sol";

abstract contract Function_SingleIdentifierId_WithdrawProtocol is Base_SingleIdentifierId_Functions {

    /**
        Target: SingleIdentifierID - withdraw (protocol)
        Checks: Correct execution
        Restrictions:
            - _receiver can't be zero address
        Flow: withdraw function called with the correct params
        Expects:
            - protocolBalance variable set to 0
            - balance of the receiver increased by the emitter balance
            - call to _receiver should be sent with the correct value
            - Withdrawal event was emitted with the correct data
    */
    function test_WithdrawProtocol_Ok(
        address payable _receiver,
        address _admin,
        uint256 _amount
    ) public {
        /// Validating restrictions
        vm.assume(_receiver != address(0));
        assumePayable(_receiver);

        /// Preparing environment
        singleId.helper_grantRole(DEFAULT_ADMIN_ROLE, _admin);

        singleId.helper_setProtocolBalance(_amount);

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
        vm.prank(_admin);
        // Executing function
        singleId.withdraw(
            payable(_receiver)
        );

        /// Asserting expectations
        uint256 balanceSingleIdProtocolAfter = singleId.protocolBalance();
        uint256 balanceSingleIdAfter = address(singleId).balance;
        uint256 balanceReceiverAfter = _receiver.balance;

        assertEq(balanceSingleIdProtocolAfter, 0, "Protocol balance was not set to 0");
        assertEq(balanceSingleIdAfter, balanceSingleIdBefore - _amount, "SingleId balance was changed incorrectly");
        assertEq(balanceReceiverAfter, balanceReceiverBefore + _amount, "Receiver balance was changed incorrectly");
    }

    /**
        Target: SingleIdentifierID - withdraw (protocol)
        Checks: Revert when caller is not an admin
        Restrictions:
            - _receiver can't be zero
        Flow: withdraw function called from a non-admin address with the correct params
        Expects:
            - reverts with the 'AccessControl: account 0x... is missing role 0x...' error
    */
    function test_WithdrawProtocol_RevertIf_SenderIsNotAnAdmin(
        address payable _receiver,
        address _sender,
        uint256 _amount
    ) public {
        /// Validating restrictions
        vm.assume(_receiver != address(0));

        /// Preparing environment
        singleId.helper_setProtocolBalance(_amount);

        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                StringsUpgradeable.toHexString(_sender),
                " is missing role ",
                StringsUpgradeable.toHexString(uint256(DEFAULT_ADMIN_ROLE), 32)
            )
        );
        vm.prank(_sender);
        // Executing function
        singleId.withdraw(
            payable(_receiver)
        );
    }

    /**
        Target: SingleIdentifierID - withdraw (protocol)
        Checks: Revert when receiver is zero address
        Flow: withdraw function called passing zero address as a receiver
        Expects:
            - execution reverts with the 'AddressIsZero()' error
    */
    function test_WithdrawProtocol_RevertIf_ReceiverIsZero(
        address _admin
    ) public {
        /// Preparing environment
        singleId.helper_grantRole(DEFAULT_ADMIN_ROLE, _admin);

        vm.expectRevert(abi.encodeWithSignature("AddressIsZero()"));
        vm.prank(_admin);
        // Executing function
        singleId.withdraw(
            payable(address(0))
        );
    }

    /**
        Target: SingleIdentifierID - withdraw (protocol)
        Checks: Revert when failed to send Ether
        Restrictions:
            - _receiver can't be zero address
        Flow: withdraw function called with the correct params
        Mocks:
            - receiver.call should revert
        Expects:
            - execution reverts with the 'Failed to send Ether' error
    */
    function test_WithdrawProtocol_RevertIf_FailedToSendEther(
        address payable _receiver,
        address _admin,
        uint256 _amount
    ) public {
        /// Validating restrictions
        vm.assume(_receiver != address(0));
        assumePayable(_receiver);
        assumeNotPrecompile(_receiver);

        /// Preparing environment
        singleId.helper_grantRole(DEFAULT_ADMIN_ROLE, _admin);

        singleId.helper_setProtocolBalance(_amount);

        vm.deal(address(singleId), _amount);

        bytes memory callData = "";
        bytes memory revertData = "";
        vm.mockCallRevert(_receiver, callData, revertData);

        vm.expectRevert("Failed to send Ether");
        vm.prank(_admin);
        // Executing function
        singleId.withdraw(
            payable(_receiver)
        );
    }

}
