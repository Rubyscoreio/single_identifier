// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "lib/forge-std/src/Script.sol";

import {HyperlaneConnector} from "../contracts/connectors/HyperlaneConnector.sol";
import {SingleRouter} from "contracts/SingleRouter.sol";

struct ChainHyperlaneData {
    address mailbox;
    address igp;
    address registry;
    uint128 gasLimit;
}

contract DeployHyperlaneConnectorScript is Script {
    mapping(uint256 => ChainHyperlaneData) private chains;

    constructor() {
        // Base sepolia
        _setDefaultChainData(
            84532,
            0x6966b0E55883d49BFB24539356a2f8A673E02039,
            0x28B02B97a850872C4D33C3E024fab6499ad96564,
            0x0896fd6E41a494F7651de341964048b2B851133E,
            50000
        );
        // Optimism sepolia
        _setDefaultChainData(
            11155420,
            0x6966b0E55883d49BFB24539356a2f8A673E02039,
            0x28B02B97a850872C4D33C3E024fab6499ad96564,
            0x979Be3738f4D0e5f230065F6E4e25e0A3dB1D1AA,
            50000
        );

        // Scroll mainnet
        _setDefaultChainData(
            534352,
            0x2f2aFaE1139Ce54feFC03593FeE8AB2aDF4a85A7,
            0xBF12ef4B9f307463D3FB59c3604F294dDCe287E2,
            0x4e5bAE495031fECd141c39D0ca231d56e178Fb05,
            50000
        );
        // ZkEVM mainnet
        _setDefaultChainData(
            1101,
            0x3a464f746D23Ab22155710f44dB16dcA53e0775E,
            0x0D63128D887159d63De29497dfa45AFc7C699AE4,
            0x9456E02Ef02C0F5256a559ecf7535356Aeab8647,
            50000
        );
        // Taiko mainnet
        _setDefaultChainData(
            167000,
            0x28EFBCadA00A7ed6772b3666F3898d276e88CAe3,
            0x273Bc6b01D9E88c064b6E5e409BdF998246AEF42,
            0xB9cC0Bb020cF55197C4C3d826AC87CAdba51f272,
            50000
        );
        // Arbitrum mainnet
        _setDefaultChainData(
            42161,
            0x979Ca5202784112f4738403dBec5D0F3B9daabB9,
            0x3b6044acd6767f017e99318AA6Ef93b7B06A5a22,
            0x4D1E2145082d0AB0fDa4a973dC4887C7295e21aB,
            50000
        );
        // Base mainnet
        _setDefaultChainData(
            8453,
            0xeA87ae93Fa0019a82A727bfd3eBd1cFCa8f64f1D,
            0xc3F23848Ed2e04C0c6d41bd7804fa8f89F940B94,
            0x81f06f4b143a6eAD0e246DA04420F9d6d1fBEF59,
            50000
        );
        // Optimism mainnet
        _setDefaultChainData(
            10,
            0xd4C1905BB1D26BC93DAC913e13CaCC278CdCC80D,
            0xD8A76C4D91fCbB7Cc8eA795DFDF870E48368995C,
            0x4E44211aFe692a4fea11344a2a5827a06aFa573f,
            50000
        );
        // Linea mainnet
        _setDefaultChainData(
            59144,
            0x02d16BC51af6BfD153d67CA61754cF912E82C4d9,
            0x8105a095368f1a184CceA86cCe21318B5Ee5BE28,
            0xDe981aB0cd819bF5D142B89fedA70119D3A958B9,
            50000
        );
    }

    function run(string calldata network) external {
        uint256 deployerPrivateKey = vm.envUint("DEPLOYER_KEY");

        _run(network, deployerPrivateKey);
    }

    function _run(string calldata network, uint256 deployerPrivateKey) internal {
        vm.createSelectFork(network);

        ChainHyperlaneData storage chain = chains[block.chainid];

        address deployer = vm.addr(deployerPrivateKey);

        vm.broadcast(deployerPrivateKey);
        HyperlaneConnector connector = new HyperlaneConnector(
            0x381c031bAA5995D0Cc52386508050Ac947780815,
            0x381c031bAA5995D0Cc52386508050Ac947780815,
            chain.mailbox,
            chain.igp,
            chain.registry,
            chain.gasLimit
        );

        console.log("Connector deployed at: ", address(connector));
    }

    function _setDefaultChainData(uint256 _chainId, address _mailbox, address _igp, address _registry, uint128 _gasLimit) internal {
        chains[_chainId] = ChainHyperlaneData(
            _mailbox,
            _igp,
            _registry,
            _gasLimit
        );
    }
}