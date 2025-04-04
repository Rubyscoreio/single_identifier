// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "./helpers/ScriptWithOnchainEnv.sol";
import "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";

import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {SingleIdentifierID} from "contracts/SingleIdentifierID.sol";
import {SingleIdentifierRegistry} from "contracts/SingleIdentifierRegistry.sol";
import {SingleIdentifierID} from "contracts/SingleIdentifierID.sol";
import {HyperlaneConnector} from "contracts/connectors/HyperlaneConnector.sol";
import {LayerZeroConnector} from "contracts/connectors/LayerZeroConnector.sol";
import {SameChainConnector} from "contracts/connectors/SameChainConnector.sol";

contract CheckProtocolCrossChainHealthScript is ScriptWithOnchainEnv {

    function run() external {
        _setupChains();

        _run();
    }

    function _addrToBytes32(address addr) internal pure returns(bytes32) {
        return bytes32(uint256(uint160(addr)));
    }

    function _run() internal {
        for(uint256 i = 0;i<deployedChains.length;i++) {
            vm.createSelectFork(deployedChains[i]);

            uint256 chainId = chainNameToId[deployedChains[i]];
            ChainEnv memory env = chainIdToEnv[chainId];

            console.log("=====");
            console.log("Checking:", env.chainName);

            _checkPeers(env);
            _checkChainIds(env);
            _checkContractsConnections(env);
        }
    }

    function _checkPeers(ChainEnv memory _baseEnv) internal {
        bool isHealthy = true;

        for(uint256 i=0;i<deployedChains.length;i++) {
            uint256 chainId = chainNameToId[deployedChains[i]];
            ChainEnv memory env = chainIdToEnv[chainId];

            if (_baseEnv.chainId == env.chainId) { continue; }

            bytes32 hyperlanePeer = _baseEnv.router.getPeer(1, env.chainId);
            bytes32 l0Peer = _baseEnv.router.getPeer(2, env.chainId);

            if (hyperlanePeer != _addrToBytes32(address(env.hyperlaneConnector))) {
                isHealthy = false;
                console.log("\tHyperlane peer invalid");
            }

            if (l0Peer != _addrToBytes32(address(env.l0Connector))) {
                isHealthy = false;
                console.log("\tLayerZero peer invalid");
            }
        }

        if(isHealthy) {
            console.log("Peers are OK");
        } else {
            console.log("Peers have problems");
        }
    }

    function _checkChainIds(ChainEnv memory _baseEnv) internal {
        bool isHealthy = true;

        for(uint256 i=0;i<deployedChains.length;i++) {
            uint256 chainId = chainNameToId[deployedChains[i]];
            ChainEnv memory env = chainIdToEnv[chainId];

            if (_baseEnv.chainId == env.chainId) { continue; }

            uint256 hyperlaneCustomChainId = _baseEnv.hyperlaneConnector.customChainIds(_baseEnv.chainId);
            uint256 hyperlaneNativeChainId = _baseEnv.hyperlaneConnector.nativeChainIds(hyperlaneCustomChainId);

            uint256 l0CustomChainId = _baseEnv.l0Connector.customChainIds(_baseEnv.chainId);
            uint256 l0NativeChainId = _baseEnv.l0Connector.nativeChainIds(l0CustomChainId);

            if (_baseEnv.chainId != hyperlaneNativeChainId) {
                isHealthy = false;
                console.log("\tHyperlane native chain id is invalid in chain", _baseEnv.chainName);
                console.log("\t\tExpected:", hyperlaneNativeChainId);
                console.log("\t\tActual: ", _baseEnv.chainId);
            }

            if (_baseEnv.hyperlaneCustomChainId != hyperlaneCustomChainId) {
                isHealthy = false;
                console.log("\tHyperlane custom chain id is invalid in chain", _baseEnv.chainName);
                console.log("\t\tExpected:", hyperlaneCustomChainId);
                console.log("\t\tActual: ", _baseEnv.hyperlaneCustomChainId);
            }

            if (_baseEnv.chainId != l0NativeChainId) {
                isHealthy = false;
                console.log("\tLayerZero native chain id is invalid in chain", _baseEnv.chainName);
                console.log("\t\tExpected:", l0NativeChainId);
                console.log("\t\tActual: ", _baseEnv.chainId);
            }

            if (_baseEnv.l0CustomChainId != l0CustomChainId) {
                isHealthy = false;
                console.log("\tLayerZero custom chain id is invalid in chain", _baseEnv.chainName);
                console.log("\t\tExpected:", l0CustomChainId);
                console.log("\t\tActual: ", _baseEnv.l0CustomChainId);
            }
        }

        if(isHealthy) {
            console.log("Chain ids are OK");
        } else {
            console.log("Chain ids have problems");
        }
    }

    function _checkContractsConnections(ChainEnv memory _baseEnv) internal {
        bool isHealthy = true;

        if (_baseEnv.sameChainConnector.router() != _baseEnv.router) {
            isHealthy = false;
            console.log("\tRouter address in SameChainConnector is invalid");
            console.log("\t\tExpected:", address(_baseEnv.router));
            console.log("\t\tActual: ", address(_baseEnv.sameChainConnector.router()));
        }

        if (_baseEnv.sameChainConnector.registry() != _baseEnv.registry) {
            isHealthy = false;
            console.log("\tRegistry address in SameChainConnector is invalid");
            console.log("\t\tExpected:", address(_baseEnv.registry));
            console.log("\t\tActual: ", address(_baseEnv.sameChainConnector.registry()));
        }

        if (_baseEnv.sameChainConnector.singleId() != _baseEnv.singleId) {
            isHealthy = false;
            console.log("\tSingleId address in SameChainConnector is invalid");
            console.log("\t\tExpected:", address(_baseEnv.singleId));
            console.log("\t\tActual: ", address(_baseEnv.sameChainConnector.singleId()));
        }


        if (_baseEnv.hyperlaneConnector.router() != _baseEnv.router) {
            isHealthy = false;
            console.log("\tRouter address in HyperlaneConnector is invalid");
            console.log("\t\tExpected:", address(_baseEnv.router));
            console.log("\t\tActual: ", address(_baseEnv.hyperlaneConnector.router()));
        }

        if (_baseEnv.hyperlaneConnector.registry() != _baseEnv.registry) {
            isHealthy = false;
            console.log("\tRegistry address in HyperlaneConnector is invalid");
            console.log("\t\tExpected:", address(_baseEnv.registry));
            console.log("\t\tActual: ", address(_baseEnv.hyperlaneConnector.registry()));
        }

        if (_baseEnv.hyperlaneConnector.singleId() != _baseEnv.singleId) {
            isHealthy = false;
            console.log("\tSingleId address in HyperlaneConnector is invalid");
            console.log("\t\tExpected:", address(_baseEnv.singleId));
            console.log("\t\tActual: ", address(_baseEnv.hyperlaneConnector.singleId()));
        }


        if (_baseEnv.l0Connector.router() != _baseEnv.router) {
            isHealthy = false;
            console.log("\tRouter address in LayerZeroConnector is invalid");
            console.log("\t\tExpected:", address(_baseEnv.router));
            console.log("\t\tActual: ", address(_baseEnv.l0Connector.router()));
        }

        if (_baseEnv.l0Connector.registry() != _baseEnv.registry) {
            isHealthy = false;
            console.log("\tRegistry address in LayerZeroConnector is invalid");
            console.log("\t\tExpected:", address(_baseEnv.registry));
            console.log("\t\tActual: ", address(_baseEnv.l0Connector.registry()));
        }

        if (_baseEnv.l0Connector.singleId() != _baseEnv.singleId) {
            isHealthy = false;
            console.log("\tSingleId address in LayerZeroConnector is invalid");
            console.log("\t\tExpected:", address(_baseEnv.singleId));
            console.log("\t\tActual: ", address(_baseEnv.l0Connector.singleId()));
        }


        if (_baseEnv.singleId.router() != _baseEnv.router) {
            isHealthy = false;
            console.log("\tRouter address in SingleId is invalid");
            console.log("\t\tExpected:", address(_baseEnv.router));
            console.log("\t\tActual: ", address(_baseEnv.singleId.router()));
        }

        if (_baseEnv.registry.router() != _baseEnv.router) {
            isHealthy = false;
            console.log("\tRouter address in Registry is invalid");
            console.log("\t\tExpected:", address(_baseEnv.router));
            console.log("\t\tActual: ", address(_baseEnv.registry.router()));
        }


        if(isHealthy) {
            console.log("Contract connections are OK");
        } else {
            console.log("Contract connections have problems");
        }
    }
}