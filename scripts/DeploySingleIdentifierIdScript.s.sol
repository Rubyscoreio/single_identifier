// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {SingleIdentifierID} from "contracts/SingleIdentifierID.sol";

import "lib/forge-std/src/Script.sol";

contract DeploySingleIdentifierIdScript is Script {
    function run(string calldata network) external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");

        _run(network, deployerPrivateKey);
    }

    function runMultichain(string[] calldata networks) external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");

        for (uint256 i = 0; i < networks.length; i++) {
            _run(networks[i], deployerPrivateKey);
        }
    }

    function _run(string calldata network, uint256 deployerPrivateKey) internal {
        vm.createSelectFork(vm.rpcUrl(network));

        vm.broadcast(deployerPrivateKey);
        address singleIdentifierId = address(new SingleIdentifierID());

        console.log("SingleIdentifierId deployed on", network, "at", singleIdentifierId);
    }
}