// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "lib/forge-std/src/Script.sol";

import {ILayerZeroEndpointV2} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/ILayerZeroEndpointV2.sol";
import {SetConfigParam} from "@layerzerolabs/lz-evm-protocol-v2/contracts/interfaces/IMessageLibManager.sol";
import {UlnConfig} from "@layerzerolabs/lz-evm-messagelib-v2/contracts/uln/UlnBase.sol";



import {LayerZeroConnector} from "contracts/connectors/LayerZeroConnector.sol";
import {SingleRouter} from "contracts/SingleRouter.sol";

struct L0Data {
    address dvn;
    ILayerZeroEndpointV2E endpoint;
    address sendLib;
    address receiveLib;
}

struct ChainConnectorsData {
    uint256 chainId;
    uint32 customId;
    address router;
    LayerZeroConnector connector;
    L0Data l0;
}

interface ILayerZeroEndpointV2E is ILayerZeroEndpointV2 {
    function delegates(address) external view returns (address);
}

contract ConfigureL0ConnectorsScript is Script {
    UlnConfig public defaultUlnConfig;

    uint32 public connectorId = 2;
    mapping(uint256 => ChainConnectorsData) private chains;
    mapping(string => uint256) private chainIds;

    error ChainNotConfigured(string chain);
    error EmptyCustomId(string chain);
    error EmptyConnector(string chain);
    error EmptyEndpoint(string chain);
    error SetWrongDelegate(string chain, address delegate);

    constructor() {
        defaultUlnConfig = UlnConfig(
            0,
            0,
            0,
            0,
            new address[](0),
            new address[](0)
        );

        // Scroll mainnet
        _setDefaultChainData(
            534352,
            0xfa31AB150782F086Ba93b7902E73B05DCBDe716b,
            0xbe0d08a85EeBFCC6eDA0A843521f7CBB1180D2e2
        );
        // ZkEVM mainnet
        _setDefaultChainData(
            1101,
            0x09B18EFC623bf4a6247B23320920C3044a45cC2c,
            0x488863D609F3A673875a914fBeE7508a1DE45eC6
        );
        // Taiko mainnet
        _setDefaultChainData(
            167000,
            0x3fd85e4932fA418401E96737700bA62569c08dA2,
            0xc097ab8CD7b053326DFe9fB3E3a31a0CCe3B526f
        );
        // Arbitrum mainnet
        _setDefaultChainData(
            42161,
            0x9456E02Ef02C0F5256a559ecf7535356Aeab8647,
            0x2f55C492897526677C5B68fb199ea31E2c126416
        );
        // Base mainnet
        _setDefaultChainData(
            8453,
            0xfcB1A34583980bc4565Eb8458B0F715f69e04bA8,
            0x9e059a54699a285714207b43B055483E78FAac25
        );
        // Optimism mainnet
        _setDefaultChainData(
            10,
            0x483aC3C8F6C48737a3E524a086A32581Ad433D53,
            0x6A02D83e8d433304bba74EF1c427913958187142
        );
        // Linea mainnet
        _setDefaultChainData(
            59144,
            0x812DEC92e64Da2FCB773528CBC8B71aaDaA310e8,
            0x129Ee430Cb2Ff2708CCADDBDb408a88Fe4FFd480
        );
    }

    function runMultichain(string[] calldata networks) external {
        uint256 operatorPrivateKey = vm.envUint("OPERATOR_KEY");

        for (uint256 i = 0; i < networks.length; i++) {
            _collectChainData(networks[i]);
        }

        for (uint256 i = 0; i < networks.length; i++) {
            _run(networks, i, operatorPrivateKey);
        }
    }

    function _collectChainData(string calldata network) internal {
        vm.createSelectFork(network);
        chainIds[network] = block.chainid;

        ChainConnectorsData storage chain = chains[block.chainid];
        if (chain.l0.dvn == address(0)) revert ChainNotConfigured(network);

        LayerZeroConnector connector = LayerZeroConnector(address(SingleRouter(chain.router).connectors(connectorId)));
        ILayerZeroEndpointV2E endpoint = ILayerZeroEndpointV2E(address(connector.endpoint()));

        chain.connector = connector;
        chain.customId = uint32(connector.customChainIds(block.chainid));
        chain.l0.endpoint = endpoint;
        chain.l0.sendLib = endpoint.defaultSendLibrary(30195);
        chain.l0.receiveLib = endpoint.defaultReceiveLibrary(30195);
    }

    function _run(string[] memory networks, uint256 id, uint256 operatorPrivateKey) internal {
        string memory network = networks[id];

        vm.createSelectFork(network);

        ChainConnectorsData storage chain = chains[block.chainid];
        if (chain.l0.dvn == address(0)) revert ChainNotConfigured(network);
        if (chain.customId == 0) revert EmptyCustomId(network);


        LayerZeroConnector connector = chain.connector;
        ILayerZeroEndpointV2E endpoint = chain.l0.endpoint;

        if (address(connector) == address(0)) revert EmptyConnector(network);
        if (address(endpoint) == address(0)) revert EmptyEndpoint(network);

        address[] memory DVNs = new address[](1);
        DVNs[0] = address(chain.l0.dvn);

        UlnConfig memory ulnConfig = UlnConfig(
            1,
            1,
            1,
            1,
            DVNs,
            DVNs
        );

        SetConfigParam[] memory setConfigParams = new SetConfigParam[](networks.length - 1);

        uint256 skipped = 0;

        for (uint256 i = 0; i < networks.length; i++) {
            if (keccak256(abi.encodePacked(networks[i])) == keccak256(abi.encodePacked(network))){
                skipped++;
                continue;
            }
            uint256 chainId = chainIds[networks[i]];

            setConfigParams[i - skipped] = SetConfigParam(
                chains[chainId].customId,
                2,
                abi.encode(ulnConfig)
            );
        }

        address operator = vm.addr(operatorPrivateKey);
        address sendLib = chain.l0.sendLib;
        address receiveLib = chain.l0.receiveLib;

        address delegate = endpoint.delegates(address(connector));

        if (delegate != address(0)) {
            if (delegate != operator) revert SetWrongDelegate(network, delegate);
        } else {
            vm.broadcast(operatorPrivateKey);
            connector.setDelegate(operator);
        }

        if (keccak256(abi.encodePacked("scroll")) == keccak256(abi.encodePacked(network))) {
            vm.startBroadcast(operatorPrivateKey);
            endpoint.setConfig(address(connector), sendLib, setConfigParams);
            endpoint.setConfig(address(connector), receiveLib, setConfigParams);
            vm.stopBroadcast();
        }
    }

    function _setDefaultChainData(uint32 chainId, address router, address dvn) internal {
        chains[chainId] = ChainConnectorsData(
            chainId,
            0,
            router,
            LayerZeroConnector(address(0)),
            L0Data (
                dvn,
                ILayerZeroEndpointV2E(address(0)),
                address(0),
                address(0)
            )
        );
    }
}