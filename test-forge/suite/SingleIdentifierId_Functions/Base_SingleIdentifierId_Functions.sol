// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {Storage_SingleIdentifierID} from "test-forge/storage/Storage_SingleIdentifierID.sol";

abstract contract Base_SingleIdentifierId_Functions is Storage_SingleIdentifierID {
    using ECDSA for bytes32;

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    function helper_sign(uint256 _privateKey, bytes32 _digest) public returns (bytes memory signature) {
        address signer = vm.addr(_privateKey);

        vm.startPrank(signer);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, _digest);

        signature = abi.encodePacked(r, s, v);
        vm.stopPrank();
    }
}
