// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "lib/forge-std/src/Script.sol";

import {HyperlaneConnector} from "contracts/connectors/HyperlaneConnector.sol";
import {LayerZeroConnector} from "contracts/connectors/LayerZeroConnector.sol";
import {SameChainConnector} from "contracts/connectors/SameChainConnector.sol";
import {SingleIdentifierID} from "contracts/SingleIdentifierID.sol";
import {SingleIdentifierRegistry} from "contracts/SingleIdentifierRegistry.sol";
import {SingleRouter} from "contracts/SingleRouter.sol";


contract ScriptWithOnchainEnv is Script {
    struct ChainEnv {
        SingleIdentifierID singleId;
        SingleIdentifierRegistry registry;
        SingleRouter router;
        SameChainConnector sameChainConnector;
        HyperlaneConnector hyperlaneConnector;
        LayerZeroConnector l0Connector;
    }

    mapping(uint256 => ChainEnv) public chainIdToEnv;
    mapping(string => uint256) public chainNameToId;

    string[7] public deployedChains = [
        "arbitrum",
        "base",
        "linea",
        "optimism",
        "scroll",
        "taiko",
        "zkevm"
    ];

    function _setupChains() internal {
        _setUpChainEnv("arbitrum",
            0xc1b435E1cee1610aa1A19C5cBA20C832dA057146,
            0x4D1E2145082d0AB0fDa4a973dC4887C7295e21aB
        );

        _setUpChainEnv("base",
            0x09B18EFC623bf4a6247B23320920C3044a45cC2c,
            0x81f06f4b143a6eAD0e246DA04420F9d6d1fBEF59
        );

        _setUpChainEnv("linea",
            0xFC353736BBA5642ab481b6b8392827B69A20cb17,
            0xDe981aB0cd819bF5D142B89fedA70119D3A958B9
        );

        _setUpChainEnv("optimism",
            0xfa31AB150782F086Ba93b7902E73B05DCBDe716b,
            0x4E44211aFe692a4fea11344a2a5827a06aFa573f
        );

        _setUpChainEnv("scroll",
            0x25158191bab9BFF92EB7214b6c2dE79105D11593,
            0x4e5bAE495031fECd141c39D0ca231d56e178Fb05
        );

        _setUpChainEnv("taiko",
            0xAff9D3Af3495c54E0bb90e03Bc762681bF5a52Bf,
            0xB9cC0Bb020cF55197C4C3d826AC87CAdba51f272
        );

        _setUpChainEnv("zkevm",
            0x389452F3AA4B82C19bf8dFC2943Ca28E9f4EDA4A,
            0x9456E02Ef02C0F5256a559ecf7535356Aeab8647
        );
    }

    function _setUpChainEnv(string memory _chainName, address _singleId, address _registry) internal {
        vm.createSelectFork(_chainName);

        uint256 chainId = block.chainid;
        chainNameToId[_chainName] = chainId;

        console.log("chainId: ", chainId);

        SingleIdentifierID singleId = SingleIdentifierID(_singleId);
        SingleRouter router = singleId.router();

        chainIdToEnv[chainId] = ChainEnv(
            singleId,
            SingleIdentifierRegistry(_registry),
            router,
            SameChainConnector(address(router.connectors(0))),
            HyperlaneConnector(address(router.connectors(1))),
            LayerZeroConnector(address(router.connectors(2)))
        );
    }
}
