// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import {HyperlaneConnector} from "contracts/connectors/HyperlaneConnector.sol";
import {SingleRouter} from "contracts/SingleRouter.sol";
import {ScriptWithOnchainEnv} from "./helpers/ScriptWithOnchainEnv.sol";

contract SetUpHyperlaneConnectors is ScriptWithOnchainEnv {
    mapping(string => address) private hyperlaneConnectors;

    error ChainNotConfigured(string chain);
    error EmptyCustomId(string chain);
    error EmptyConnector(string chain);
    error EmptyEndpoint(string chain);
    error SetWrongDelegate(string chain, address delegate);

    constructor() {
        hyperlaneConnectors["arbitrum"] = 0x979Be3738f4D0e5f230065F6E4e25e0A3dB1D1AA;
        hyperlaneConnectors["base"] = 0x08d1Ab08766CdDc03979C1de5708CB0cb79ce4ea;
        hyperlaneConnectors["linea"] = 0xB0575B90c972D81A1Aa743b81DFFe86c36c0C48b;
        hyperlaneConnectors["optimism"] = 0x9215FB8E47cfCaE92200EDDA026488e4fA87cF4c;
        hyperlaneConnectors["scroll"] = 0x9215FB8E47cfCaE92200EDDA026488e4fA87cF4c;
        hyperlaneConnectors["taiko"] = 0x08d1Ab08766CdDc03979C1de5708CB0cb79ce4ea;
        hyperlaneConnectors["zkevm"] = 0xfa31AB150782F086Ba93b7902E73B05DCBDe716b;
    }

    function runMultichain(string[] calldata networks) external {
        _setupChains();

        uint256 operatorPrivateKey = vm.envUint("OPERATOR_KEY");

        uint256[] memory chainIds = new uint256[](deployedChains.length);
        for (uint256 i = 0; i < deployedChains.length; i++) chainIds[i] = chainNameToId[deployedChains[i]];

        bytes32[] memory peers = new bytes32[](deployedChains.length);
        for (uint256 i = 0; i < deployedChains.length; i++)
            peers[i] = bytes32(uint256(uint160(hyperlaneConnectors[deployedChains[i]])));

        for (uint256 i = 0; i < networks.length; i++) {
            _run(
                networks,
                i,
                chainIds,
                peers,
                operatorPrivateKey
            );
        }
    }

    function _run(
        string[] memory networks,
        uint256 id,
        uint256[] memory chainIds,
        bytes32[] memory peers,
        uint256 operatorPrivateKey
    ) internal {
        string memory network = networks[id];

        vm.createSelectFork(network);

        ChainEnv storage chain = chainIdToEnv[block.chainid];
        if (address(chain.sameChainConnector) == address(0)) revert ChainNotConfigured(network);

        HyperlaneConnector connector = HyperlaneConnector(hyperlaneConnectors[network]);

        vm.startBroadcast(operatorPrivateKey);

        connector.setChainIds(chainIds, chainIds);
        connector.setRouter(address(chain.router));
        connector.setSingleId(address(chain.singleId));

        chain.router.setPeers(1, chainIds, peers);

        chain.router.setConnector(1, hyperlaneConnectors[network]);

        vm.stopBroadcast();
    }
}