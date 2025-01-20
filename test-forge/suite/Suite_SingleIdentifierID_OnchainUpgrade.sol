// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ERC1967Utils} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";

import {SingleIdentifierID} from "contracts/SingleIdentifierID.sol";

import {Storage_SingleIdentifierID_SendingMessages} from "test-forge/storage/Storage_SingleIdentifierID_SendingMessages.sol";

abstract contract Suite_SingleIdentifierID_OnchainUpgrade is Storage_SingleIdentifierID_SendingMessages {

    function test_Upgrade_OnChain() public {
        SingleIdentifierID newSingleId = new SingleIdentifierID();
        address oldImplementation = address(uint160(uint256(vm.load(address(singleId), _IMPLEMENTATION_SLOT))));

        uint256 protocolBalanceBeforeUpgrade = singleId.protocolBalance();

        address operator = makeAddr("operator");

        singleId.helper_grantRole(OPERATOR_ROLE, operator);

        vm.expectEmit();
        emit ERC1967Utils.Upgraded(address(newSingleId));
        vm.prank(operator);
        singleId.upgradeTo(address(newSingleId));

        address newImplementation = address(uint160(uint256(vm.load(address(singleId), _IMPLEMENTATION_SLOT))));
        assertEq(newImplementation, address(newSingleId));

        vm.expectCall(
            address(singleId),
            abi.encodeCall(singleId.protocolBalance, ())
        );
        uint256 protocolBalanceAfterUpgrade = singleId.protocolBalance();

        assertEq(protocolBalanceBeforeUpgrade, protocolBalanceAfterUpgrade);
    }
}
