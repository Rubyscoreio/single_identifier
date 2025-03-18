// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "lib/forge-std/src/Test.sol";

abstract contract Base_Storage is Test {
    function _prepareEnv() internal virtual;

    function setUp() public virtual {
        _prepareEnv();
    }
}
