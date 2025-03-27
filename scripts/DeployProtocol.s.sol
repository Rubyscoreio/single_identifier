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

contract DeployProtocolScript is ScriptWithOnchainEnv {
    address constant public ADMIN = 0x0d0D5Ff3cFeF8B7B2b1cAC6B6C27Fd0846c09361;
    address constant public OPERATOR = 0x381c031bAA5995D0Cc52386508050Ac947780815;

    /// @notice constants below should be adjusted to the each chain

    /// @notice protocol fee
    uint256 constant public PROTOCOL_FEE = 1e18;
    /// @notice target chain id
    /// @dev block.chainid can't be used because because of issues with multichain scripts anf optimiser
    uint256 constant public NEW_CHAIN_ID = 137;

    /// @notice Hyperlane mailbox contract
    /// @dev check here: https://docs.hyperlane.xyz/docs/reference/addresses/mailbox-addresses
    address constant public HYPERLANE_MAILBOX = 0x5d934f4e2f797775e53561bB72aca21ba36B96BB;

    /// @notice Hyperlane mailbox contract
    /// @dev check here: https://docs.hyperlane.xyz/docs/reference/addresses/interchain-gas-paymaster
    address constant public HYPERLANE_IGP = 0x0071740Bf129b05C4684abfbBeD248D80971cce2;

    uint128 constant public HYPERLANE_GAS_LIMIT = 500000;

    /// @notice Hyperlane mailbox contract
    /// @dev check here: https://docs.hyperlane.xyz/docs/reference/addresses/mailbox-addresses
    uint256 constant public HYPERLANE_CUSTOM_CHAIN_ID = 137;

    /// @notice LayerZero endpoint mailbox contract
    /// @dev check here: https://docs.layerzero.network/v2/deployments/deployed-contracts
    address constant public L0_ENDPOINT = 0x1a44076050125825900e736c501f859c50fE728c;
    uint128 constant public L0_GAS_LIMIT = 50000;

    uint256 public deployerPK;

    uint256[] public chainIds;
    bytes32[] public sameChains;
    bytes32[] public hyperlanes;
    bytes32[] public l0s;

    function run(string calldata network) external {
        _setupChains();

        deployerPK = vm.envUint("DEPLOYER_KEY");

        require(chainNameToId[network] == 0, "Protocol already exist on this chain");

        _run(network);
    }

    function _run(string calldata network) internal {
        vm.createSelectFork(vm.rpcUrl(network));

        nativeChainIds.push(NEW_CHAIN_ID);
        hyperlaneChainIds.push(NEW_CHAIN_ID);
        l0ChainIds.push(ILayerZeroEndpointV2(L0_ENDPOINT).eid());

        SingleRouter router = _deployRouter();
        SingleIdentifierRegistry registry = _deployRegistry();
        SingleIdentifierID singleId = _deployIdentifierId(router);
        console.log("Router deployed:", address(router));
        console.log("Register deployed:", address(registry));
        console.log("SingleId deployed:", address(singleId));

        (
            SameChainConnector sameChain,
            HyperlaneConnector hyperlane,
            LayerZeroConnector l0
        ) = _deployConnectors(router, registry, singleId);
        console.log("SameChain connector deployed:", address(sameChain));
        console.log("Hyperlane connector deployed:", address(hyperlane));
        console.log("LayerZero connector deployed:", address(l0));

        _registerConnectorsOnThisChain(
            router,
            sameChain,
            hyperlane,
            l0
        );
        console.log("Connectors registered on base chain");

        _registerOtherChainPeersOnThisChain(router);
        console.log("Registered other chain connectors on base chain");

        _registerConnectorsOnOtherChains(
            network,
            sameChain,
            hyperlane,
            l0
        );
        console.log("Registered base chain connectors on other chains");
    }

    function _deployRouter() internal returns(SingleRouter) {
        vm.broadcast(deployerPK);
        SingleRouter router = new SingleRouter();

        bytes memory initializerPayload = abi.encodeWithSelector(SingleRouter.initialize.selector, OPERATOR);

        vm.broadcast(deployerPK);
        ERC1967Proxy proxy = new ERC1967Proxy(address(router), initializerPayload);

        vm.label(address(proxy), "P_SingleRouter");

        return(SingleRouter(address(proxy)));
    }

    function _deployRegistry(SingleRouter router) internal returns(SingleIdentifierRegistry) {
        vm.broadcast(deployerPK);
        SingleIdentifierRegistry registry = new SingleIdentifierRegistry();

        bytes memory initializerPayload = abi.encodeWithSelector(SingleIdentifierRegistry.initialize.selector, OPERATOR);

        vm.broadcast(deployerPK);
        ERC1967Proxy proxy = new ERC1967Proxy(address(registry), initializerPayload);

        vm.broadcast(deployerPK);
        SingleIdentifierRegistry(address(proxy)).setRouter(address(router));

        vm.label(address(proxy), "P_SingleIdentifierRegistry");

        return(SingleIdentifierRegistry(address(proxy)));
    }

    function _deployIdentifierId(SingleRouter router) internal returns(SingleIdentifierID) {
        vm.broadcast(deployerPK);
        SingleIdentifierID identifierId = new SingleIdentifierID();

        bytes memory initializerPayload = abi.encodeWithSelector(SingleIdentifierID.initialize.selector,
            PROTOCOL_FEE,
            ADMIN,
            OPERATOR,
            address(router)
        );

        vm.broadcast(deployerPK);
        ERC1967Proxy proxy = new ERC1967Proxy(address(identifierId), initializerPayload);

        vm.label(address(proxy), "P_SingleIdentifierID");

        return(SingleIdentifierID(address(proxy)));
    }

    function _deployConnectors(
        SingleRouter router,
        SingleIdentifierRegistry registry,
        SingleIdentifierID singleId
    ) internal returns(
        SameChainConnector sameChain,
        HyperlaneConnector hyperlane,
        LayerZeroConnector l0
    ) {
        vm.startBroadcast(deployerPK);
        sameChain = new SameChainConnector(
            ADMIN,
            OPERATOR,
            address(registry)
        );

        sameChain.setRouter(address(router));
        sameChain.setSingleId(address(singleId));

        hyperlane = new HyperlaneConnector(
            ADMIN,
            OPERATOR,
            HYPERLANE_MAILBOX,
            HYPERLANE_IGP,
            address(registry),
            HYPERLANE_GAS_LIMIT
        );

        hyperlane.setRouter(address(router));
        hyperlane.setSingleId(address(singleId));
        hyperlane.setChainIds(nativeChainIds, hyperlaneChainIds);

        l0 = new LayerZeroConnector(
            L0_ENDPOINT,
            ADMIN,
            OPERATOR,
            address(registry),
            L0_GAS_LIMIT
        );

        l0.setRouter(address(router));
        l0.setSingleId(address(singleId));
        l0.setChainIds(nativeChainIds, l0ChainIds);

        vm.stopBroadcast();
    }

    function _registerConnectorsOnThisChain(
        SingleRouter router,
        SameChainConnector sameChain,
        HyperlaneConnector hyperlane,
        LayerZeroConnector l0
    ) internal {
        uint32[] memory connectorIds = new uint32[](3);
        connectorIds[0] = 0;
        connectorIds[1] = 1;
        connectorIds[2] = 2;

        address[] memory connectors = new address[](3);
        connectors[0] = address(sameChain);
        connectors[1] = address(hyperlane);
        connectors[2] = address(l0);

        vm.broadcast(deployerPK);
        router.setConnectors(connectorIds, connectors);
    }

    function _registerConnectorsOnOtherChains(
        string memory baseNetwork,
        SameChainConnector sameChain,
        HyperlaneConnector hyperlane,
        LayerZeroConnector l0
    ) internal {
        uint256 l0ChainId = l0.endpoint().eid();

        for(uint256 i = 0; i<deployedChains.length; i++) {
            vm.createSelectFork(vm.rpcUrl(deployedChains[i]));

            assert(NEW_CHAIN_ID != block.chainid);

            ChainEnv memory env = chainIdToEnv[block.chainid];

            vm.startBroadcast(deployerPK);
            env.router.setPeer(NEW_CHAIN_ID, 0, _addrToBytes32(address(sameChain)));

            env.router.setPeer(NEW_CHAIN_ID, 1, _addrToBytes32(address(hyperlane)));

            env.router.setPeer(NEW_CHAIN_ID, 2, _addrToBytes32(address(l0)));

            env.l0Connector.setChainId(NEW_CHAIN_ID, l0ChainId);
            env.hyperlaneConnector.setChainId(NEW_CHAIN_ID, HYPERLANE_CUSTOM_CHAIN_ID);
            vm.stopBroadcast();
        }

        vm.createSelectFork(vm.rpcUrl(baseNetwork));
    }

    function _registerOtherChainPeersOnThisChain(SingleRouter router) internal {

        require(chainIds.length == 0, "Dirty chainIds");
        require(sameChains.length == 0, "Dirty sameChains");
        require(hyperlanes.length == 0, "Dirty hyperlanes");
        require(l0s.length == 0, "Dirty l0s");

        for(uint256 i = 0; i<deployedChains.length; i++) {
            uint256 chainId = chainNameToId[deployedChains[i]];
            ChainEnv memory env = chainIdToEnv[chainId];

            chainIds.push(chainId);
            sameChains.push(_addrToBytes32(address(env.sameChainConnector)));
            hyperlanes.push(_addrToBytes32(address(env.hyperlaneConnector)));
            l0s.push(_addrToBytes32(address(env.l0Connector)));
        }

        require(
            chainIds.length == sameChains.length
            && chainIds.length == hyperlanes.length
            && chainIds.length == l0s.length,
            "Different array length"
        );

        vm.startBroadcast(deployerPK);
        router.setPeers(0, chainIds, sameChains);

        router.setPeers(1, chainIds, hyperlanes);

        router.setPeers(2, chainIds, l0s);
        vm.stopBroadcast();
    }

    function _addrToBytes32(address addr) internal pure returns(bytes32) {
        return bytes32(uint256(uint160(addr)));
    }
}