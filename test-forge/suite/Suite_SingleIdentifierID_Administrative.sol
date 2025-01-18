// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import {SingleIdentifierID} from "contracts/SingleIdentifierID.sol";

import {Storage_SingleIdentifierID} from "test-forge/storage/Storage_SingleIdentifierID.sol";

abstract contract Suite_SingleIdentifierID_Administrative is Storage_SingleIdentifierID {
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    /**
        Target: SingleIdentifierID - initialize
        Checks: Correct execution
        Restrictions:
            - _admin can't be zero address
            - _operator can't be zero address
        Flow: initialize function called with the correct params
        Expects:
            - initialized executes successfully
            - DEFAULT_ADMIN_ROLE role was assigned to _admin address
            - OPERATOR_ROLE role was assigned to _operator address
            - protocolFee variable was set to _fee
    */
    function testFuzz_Initialize_Ok(
        address _admin,
        address _operator,
        uint256 _fee
    ) public {
        /// Validating restrictions
        vm.assume(_admin != address(0));
        vm.assume(_operator != address(0));

        /// Executing target function
        singleId.initialize(
            _fee,
            _admin,
            _operator,
            address(router)
        );

        /// Asserting expectations
        assertTrue(singleId.hasRole(bytes32(0), _admin), "Admin do not have DEFAULT_ADMIN_ROLE");
        assertTrue(singleId.hasRole(OPERATOR_ROLE, _operator), "Operator do not have OPERATOR_ROLE");
        assertEq(singleId.protocolFee(), _fee, "Protocol fee is not correct");
    }

    /**
        Target: SingleIdentifierID - initialize
        Checks: Revert when contract was already initialised before
        Restrictions:
            - _admin can't be zero address
            - _operator can't be zero address
        Flow: initialize function called with the correct params twice
        Expects:
            - first execution ends up successfully
            - second execution reverts with the 'Initializable: contract is already initialized' error
    */
    function testFuzz_Initialize_RevertIf_AlreadyInitialized(
        address _admin,
        address _operator,
        uint256 _fee
    ) public {
        /// Validating restrictions
        vm.assume(_admin != address(0));
        vm.assume(_operator != address(0));

        /// Executing for the first time
        singleId.initialize(
            _fee,
            _admin,
            _operator,
            address(router)
        );

        /// Executing for the second time
        vm.expectRevert(bytes("Initializable: contract is already initialized"));
        singleId.initialize(
            _fee,
            _admin,
            _operator,
            address(router)
        );
    }

    /**
        Target: SingleIdentifierID - initialize
        Checks: Revert when called passing zero address as an admin address
        Restrictions:
            - _operator can't be zero address
        Flow: initialize function called passing zero address as an _admin while the other params are correct
        Expects:
            - execution reverts with the 'AddressIsZero()' error
    */
    function testFuzz_Initialize_RevertIf_AdminAddressIsZero(
        address _operator,
        uint256 _fee
    ) public {
        /// Validating restrictions
        vm.assume(_operator != address(0));

        /// Executing function
        vm.expectRevert(abi.encodeWithSignature("AddressIsZero()"));
        singleId.initialize(
            _fee,
            address(0),
            _operator,
            address(router)
        );
    }

    /**
        Target: SingleIdentifierID - initialize
        Checks: Revert when called passing zero address as an operator address
        Restrictions:
            - _admin can't be zero address
        Flow: initialize function called passing zero address as an _operator while the other params are correct
        Expects:
            - execution reverts with the 'AddressIsZero()' error
    */
    function testFuzz_Initialize_RevertIf_OperatorAddressIsZero(
        address _admin,
        uint256 _fee
    ) public {
        /// Validating restrictions
        vm.assume(_admin != address(0));

        /// Executing function
        vm.expectRevert(abi.encodeWithSignature("AddressIsZero()"));
        singleId.initialize(
            _fee,
            _admin,
            address(0),
            address(router)
        );
    }

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
}
