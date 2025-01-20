// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import {Emitter} from "contracts/types/Structs.sol";
import {SingleIdentifierID} from "contracts/SingleIdentifierID.sol";

import {Storage_SingleIdentifierID} from "test-forge/storage/Storage_SingleIdentifierID.sol";

abstract contract Suite_SingleIdentifierID_Administrative is Storage_SingleIdentifierID {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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

    /**
        Target: SingleIdentifierID - setRouter
        Checks: Correct execution
        Restrictions:
            - _newRouter can't be zero address
        Flow: setRouter function called from an operator address with the correct params
        Expects:
            - router variable was set to _newRouter
            - SetRouter event was emitted with the correct data
    */
    function testFuzz_SetRouter_Ok(
        address _operator,
        address _newRouter
    ) public {
        /// Validating restrictions
        vm.assume(_newRouter != address(0));

        /// Preparing environment
        singleId.helper_grantRole(OPERATOR_ROLE, _operator);

        vm.expectEmit();
        emit SingleIdentifierID.SetRouter(_newRouter);

        /// Executing function
        vm.prank(_operator);
        singleId.setRouter(_newRouter);

        /// Asserting expectations
        assertEq(address(singleId.router()), _newRouter, "Router was set incorrectly");
    }

    /**
        Target: SingleIdentifierID - setRouter
        Checks: Revert when called passing zero address as a new routers address
        Flow: setRouter function called from an operator address passing zero address as a _newRouter
        Expects:
            - execution reverts with the 'AddressIsZero()' error
    */
    function testFuzz_SetRouter_RevertIf_NewRouterAddressIsZero(
        address _operator
    ) public {
        /// Preparing environment
        singleId.helper_grantRole(OPERATOR_ROLE, _operator);

        /// Executing function
        vm.prank(_operator);
        vm.expectRevert(abi.encodeWithSignature("AddressIsZero()"));
        singleId.setRouter(address(0));
    }

    /**
        Target: SingleIdentifierID - setRouter
        Checks: Revert when called from non-operator address
        Flow: setRouter function called from a non-operator address with the correct params
        Expects:
            - execution reverts with the 'AccessControl: account 0x... is missing role 0x...' error
    */
    function testFuzz_SetRouter_RevertIf_SenderIsNotOperator(
        address _newRouter
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
        singleId.setRouter(_newRouter);
    }

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
        Emitter memory _emitter,
        uint256 _newBalance,
        address _admin
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.emitterId != bytes32(0));

        /// Preparing environment
        singleId.helper_grantRole(DEFAULT_ADMIN_ROLE, _admin);

        singleId.helper_setEmitter(_emitter);

        vm.expectEmit();
        emit SingleIdentifierID.SetEmitterBalance(_emitter.emitterId, _newBalance);
        vm.prank(_admin);
        /// Executing function
        singleId.setEmitterBalance(_emitter.emitterId, _newBalance);

        /// Asserting expectations
        assertEq(singleId.emittersBalances(_emitter.emitterId), _newBalance, "Router was set incorrectly");
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
        Emitter memory _emitter,
        uint256 _newBalance,
        address _sender
    ) public {
        /// Validating restrictions
        vm.assume(_emitter.emitterId != bytes32(0));

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
        singleId.setEmitterBalance(_emitter.emitterId, _newBalance);
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
        Emitter memory _emitter,
        uint256 _newBalance,
        address _admin
    ) public {
        /// Preparing environment
        singleId.helper_grantRole(DEFAULT_ADMIN_ROLE, _admin);

        vm.expectRevert(abi.encodeWithSignature("EmitterNotExists()"));
        vm.prank(_admin);
        /// Executing function
        singleId.setEmitterBalance(_emitter.emitterId, _newBalance);
    }
}
