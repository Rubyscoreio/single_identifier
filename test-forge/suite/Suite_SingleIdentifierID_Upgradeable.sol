// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

import {SingleIdentifierID} from "contracts/SingleIdentifierID.sol";

import {Storage_SingleIdentifierID} from "test-forge/storage/Storage_SingleIdentifierID.sol";

abstract contract Suite_SingleIdentifierID_Upgradeable is Storage_SingleIdentifierID {
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

    function test_Updating() public {
        vm.expectEmit();
        emit ERC1967Utils.Upgraded(address(singleId));
        ERC1967Proxy proxy = new ERC1967Proxy(address(singleId), "");
        SingleIdentifierID proxiedSingleId = SingleIdentifierID(address(proxy));

        proxiedSingleId.initialize(
            _defaultFee,
            _defaultAdmin,
            address(this),
            address(router)
        );

        address implementation = address(uint160(uint256(vm.load(address(proxy), _IMPLEMENTATION_SLOT))));

        assertEq(implementation, address(singleId));

        SingleIdentifierID newSingleId = new SingleIdentifierID();

        vm.expectEmit();
        emit ERC1967Utils.Upgraded(address(newSingleId));
        proxiedSingleId.upgradeTo(address(newSingleId));

        implementation = address(uint160(uint256(vm.load(address(proxy), _IMPLEMENTATION_SLOT))));

        assertEq(implementation, address(newSingleId));

        vm.expectRevert(bytes("Initializable: contract is already initialized"));
        proxiedSingleId.initialize(
            _defaultFee,
            _defaultAdmin,
            _defaultOperator,
            address(router)
        );
    }
}
