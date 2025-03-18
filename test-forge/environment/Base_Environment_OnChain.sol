// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "lib/forge-std/src/Test.sol";

import {HyperlaneConnector} from "contracts/connectors/HyperlaneConnector.sol";
import {LayerZeroConnector} from "contracts/connectors/LayerZeroConnector.sol";
import {SameChainConnector} from "contracts/connectors/SameChainConnector.sol";
import {SingleIdentifierID} from "contracts/SingleIdentifierID.sol";
import {SingleIdentifierRegistry} from "contracts/SingleIdentifierRegistry.sol";
import {SingleRouter} from "contracts/SingleRouter.sol";

contract Base_Environment_OnChain is Test {
    bytes32 public constant ARBITRUM = keccak256(abi.encodePacked("arbitrum"));
    bytes32 public constant BASE = keccak256(abi.encodePacked("base"));
    bytes32 public constant LINEA = keccak256(abi.encodePacked("linea"));
    bytes32 public constant OPTIMISM = keccak256(abi.encodePacked("optimism"));
    bytes32 public constant SCROLL = keccak256(abi.encodePacked("scroll"));
    bytes32 public constant TAIKO = keccak256(abi.encodePacked("taiko"));
    bytes32 public constant ZKEVM = keccak256(abi.encodePacked("zkevm"));


    struct ChainEnv {
        SingleIdentifierID singleId;
        SingleIdentifierRegistry registry;
        SingleRouter router;
        SameChainConnector sameChainConnector;
        HyperlaneConnector hyperlaneConnector;
        LayerZeroConnector l0Connector;
    }

    function getChainEnv(string memory _chainName) internal returns(ChainEnv memory) {
        bytes32 chainName = keccak256(abi.encodePacked(_chainName));

        if (chainName == ARBITRUM) {
            return _getChainEnv(0xc1b435E1cee1610aa1A19C5cBA20C832dA057146);
        }

        if (chainName == BASE) {
            return _getChainEnv(0x09B18EFC623bf4a6247B23320920C3044a45cC2c);
        }

        if (chainName == LINEA) {
            return _getChainEnv(0xFC353736BBA5642ab481b6b8392827B69A20cb17);
        }

        if (chainName == OPTIMISM) {
            return _getChainEnv(0xfa31AB150782F086Ba93b7902E73B05DCBDe716b);
        }

        if (chainName == SCROLL) {
            return _getChainEnv(0x25158191bab9BFF92EB7214b6c2dE79105D11593);
        }

        if (chainName == TAIKO) {
            return _getChainEnv(0xAff9D3Af3495c54E0bb90e03Bc762681bF5a52Bf);
        }

        if (chainName == ZKEVM) {
            return _getChainEnv(0x389452F3AA4B82C19bf8dFC2943Ca28E9f4EDA4A);
        }

        revert("Unknown chain name");
    }

    function _getChainEnv(address _singleId) internal returns(ChainEnv memory)  {
        SingleIdentifierID singleId = SingleIdentifierID(_singleId);

        vm.label(address(singleId), "Proxy_SingleIdentifierID");

        SingleRouter router = singleId.router();

        vm.label(address(router), "Proxy_SingleRouter");

        SameChainConnector sameChainConnector = SameChainConnector(address(router.connectors(0)));
        HyperlaneConnector hyperlaneConnector = HyperlaneConnector(address(router.connectors(1)));
        LayerZeroConnector l0Connector = LayerZeroConnector(address(router.connectors(2)));

        require(
            address(sameChainConnector.registry()) == address(hyperlaneConnector.registry())
            && address(sameChainConnector.registry()) == address(l0Connector.registry()),
            "No Registry consensus between connectors"
        );

        SingleIdentifierRegistry registry = SingleIdentifierRegistry(address(sameChainConnector.registry()));

        vm.label(address(registry), "Proxy_SingleIdentifierRegistry");

        require(address(singleId.router()) == address(registry.router()), "No Router consensus between singleId and registry");

        return ChainEnv(
            singleId,
            registry,
            router,
            sameChainConnector,
            hyperlaneConnector,
            l0Connector
        );
    }
}
