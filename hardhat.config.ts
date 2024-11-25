import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-deploy";
import "solidity-docgen";

import "tsconfig-paths/register";

import "./tasks/index";

import envConfig from "./config";

const {
  DEPLOYER_KEY,
  INFURA_KEY,
  ETHERSCAN_API_KEY,
  POLYGONSCAN_API_KEY,
  POLYGONZKSCAN_API_KEY,
  BSCSCAN_API_KEY,
  BASESCAN_API_KEY,
  LINEASCAN_API_KEY,
  ZORASCAN_API_KEY,
  OPTIMIZM_API_KEY,
  SCROLLSCAN_API_KEY,
  MANTASCAN_API_KEY,
  TAIKOSCAN_API_KEY,
  BERACHAINSCAN_API_KEY,
  ARBITRUM_API_KEY,
} = envConfig;

function typedNamedAccounts<T>(namedAccounts: { [key in string]: T }) {
  return namedAccounts;
}

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,
    },
  },
  typechain: {
    outDir: "types/typechain-types",
  },
  external: {
    contracts: [
      {
        artifacts: "node_modules/@layerzerolabs/test-devtools-evm-hardhat/artifacts",
        deploy: "node_modules/@layerzerolabs/test-devtools-evm-hardhat/deploy",
      },
    ],
    deployments: {
      hardhat: ["external"],
    },
  },
  networks: {
    hardhat: {
      gasPrice: "auto",
      loggingEnabled: false,
      forking: {
        url: `https://linea-mainnet.infura.io/v3/${INFURA_KEY}`,
        enabled: true,
      },
      allowUnlimitedContractSize: true,
      live: false,
      saveDeployments: true,
      tags: ["test", "local"],
    },
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    zkEVMMainnet: {
      url: `https://zkevm-rpc.com`,
      accounts: [DEPLOYER_KEY],
    },
    zkEVMTestnet: {
      url: `https://rpc.public.zkevm-test.net`,
      accounts: [DEPLOYER_KEY],
    },
    scrollSepolia: {
      url: "https://sepolia-rpc.scroll.io",
      accounts: [DEPLOYER_KEY],
    },
    scrollMainnet: {
      url: "https://rpc.scroll.io/",
      accounts: [DEPLOYER_KEY],
    },
    optimismMainnet: {
      url: "https://mainnet.optimism.io",
      accounts: [DEPLOYER_KEY],
    },
    optimismSepolia: {
      url: "https://sepolia.optimism.io",
      accounts: [DEPLOYER_KEY],
    },
    mainnet: {
      url: `https://mainnet.infura.io/v3/${INFURA_KEY}`,
      chainId: 1,
      accounts: [DEPLOYER_KEY],
    },
    baseMainnet: {
      url: "https://mainnet.base.org",
      accounts: [DEPLOYER_KEY],
    },
    baseSepolia: {
      url: "https://sepolia.base.org",
      accounts: [DEPLOYER_KEY],
      gasPrice: 1000000000,
    },
    baseLocal: {
      url: "http://localhost:8545",
      accounts: [DEPLOYER_KEY],
      gasPrice: 1000000000,
    },
    lineaTestnet: {
      url: `https://linea-sepolia.infura.io/v3/${INFURA_KEY}`,
      accounts: [DEPLOYER_KEY],
      chainId: 59141,
    },
    lineaMainnet: {
      url: `https://linea-mainnet.infura.io/v3/${INFURA_KEY}`,
      accounts: [DEPLOYER_KEY],
    },
    zoraGoerli: {
      url: "https://testnet.rpc.zora.energy/",
      accounts: [DEPLOYER_KEY],
      gasPrice: 2000000008,
    },
    zoraMainnet: {
      url: "https://zora.drpc.org",
      chainId: 7777777,
      accounts: [DEPLOYER_KEY],
    },
    goerli: {
      url: `https://goerli.infura.io/v3/${INFURA_KEY}`,
      chainId: 5,
      accounts: [DEPLOYER_KEY],
    },
    polygon: {
      url: `https://polygon-mainnet.infura.io/v3/${INFURA_KEY}`,
      chainId: 137,
      accounts: [DEPLOYER_KEY],
    },
    polygonMumbai: {
      url: `https://rpc-mumbai.maticvigil.com/`,
      chainId: 80001,
      accounts: [DEPLOYER_KEY],
    },
    bsc: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      accounts: [DEPLOYER_KEY],
    },
    bscTestnet: {
      url: "https://bsc-testnet.public.blastapi.io",
      chainId: 97,
      accounts: [DEPLOYER_KEY],
    },
    mantaMainnet: {
      url: "https://pacific-rpc.manta.network/http",
      chainId: 169,
      accounts: [DEPLOYER_KEY],
    },
    mantaTestnet: {
      url: "https://manta-testnet.calderachain.xyz/http",
      chainId: 3441005,
      accounts: [DEPLOYER_KEY],
    },
    mantleMainnet: {
      url: "https://rpc.mantle.xyz",
      chainId: 5000,
      accounts: [DEPLOYER_KEY],
    },
    mantleTestnet: {
      url: "https://rpc.sepolia.mantle.xyz",
      chainId: 5003,
      accounts: [DEPLOYER_KEY],
    },
    taikoTestnet: {
      url: "https://rpc.katla.taiko.xyz",
      chainId: 167008,
      accounts: [DEPLOYER_KEY],
    },
    taikoMainnet: {
      url: "https://rpc.mainnet.taiko.xyz",
      chainId: 167000,
      accounts: [DEPLOYER_KEY],
    },
    berachainTestnet: {
      url: "https://artio.rpc.berachain.com/",
      chainId: 80085,
      accounts: [DEPLOYER_KEY],
    },
    arbitrum: {
      url: "https://arb1.arbitrum.io/rpc",
      chainId: 42161,
      accounts: [DEPLOYER_KEY],
    },
  },
  etherscan: {
    apiKey: {
      mainnet: ETHERSCAN_API_KEY,
      goerli: ETHERSCAN_API_KEY,
      polygon: POLYGONSCAN_API_KEY,
      polygonMumbai: POLYGONSCAN_API_KEY,
      zkEVMMainnet: POLYGONZKSCAN_API_KEY,
      zkEVMTestnet: POLYGONZKSCAN_API_KEY,
      scrollSepolia: SCROLLSCAN_API_KEY,
      scrollMainnet: SCROLLSCAN_API_KEY,
      bsc: BSCSCAN_API_KEY,
      bscTestnet: BSCSCAN_API_KEY,
      baseSepolia: BASESCAN_API_KEY,
      baseMainnet: BASESCAN_API_KEY,
      lineaTestnet: LINEASCAN_API_KEY,
      lineaMainnet: LINEASCAN_API_KEY,
      optimismSepolia: OPTIMIZM_API_KEY,
      optimismMainnet: OPTIMIZM_API_KEY,
      zoraGoerli: ZORASCAN_API_KEY,
      zoraMainnet: ZORASCAN_API_KEY,
      mantaMainnet: MANTASCAN_API_KEY,
      mantaTestnet: MANTASCAN_API_KEY,
      taikoTestnet: TAIKOSCAN_API_KEY,
      taikoMainnet: TAIKOSCAN_API_KEY,
      berachainTestnet: BERACHAINSCAN_API_KEY,
      arbitrum: ARBITRUM_API_KEY,
    },
    customChains: [
      {
        network: "zkEVMMainnet",
        chainId: 1101,
        urls: {
          apiURL: "https://api-zkevm.polygonscan.com/api",
          browserURL: "https://explorer.mainnet.zkevm-test.net/",
        },
      },
      {
        network: "zkEVMTestnet",
        chainId: 1442,
        urls: {
          apiURL: "https://testnet-zkevm.polygonscan.com/api",
          browserURL: "https://testnet-zkevm.polygonscan.com",
        },
      },
      {
        network: "scrollSepolia",
        chainId: 534351,
        urls: {
          apiURL: "https://scroll-sepolia.drpc.org",
          browserURL: "https://sepolia.scrollscan.com/",
        },
      },
      {
        network: "scrollMainnet",
        chainId: 534352,
        urls: {
          apiURL: "https://api.scrollscan.com/api",
          browserURL: "https://scrollscan.com/",
        },
      },
      {
        network: "optimismMainnet",
        chainId: 10,
        urls: {
          apiURL: "https://api-optimistic.etherscan.io/api",
          browserURL: "https://explorer.optimism.io",
        },
      },
      {
        network: "optimismSepolia",
        chainId: 11155420,
        urls: {
          apiURL: "https://api-sepolia-optimistic.etherscan.io/api",
          browserURL: "https://sepolia-optimism.etherscan.io/",
        },
      },

      {
        network: "baseSepolia",
        chainId: 84532,
        urls: {
          apiURL: "https://api-sepolia.basescan.org/api",
          browserURL: "https://sepolia.basescan.org",
        },
      },
      {
        network: "baseMainnet",
        chainId: 8453,
        urls: {
          apiURL: "https://api.basescan.org/api",
          browserURL: "https://basescan.org",
        },
      },
      {
        network: "lineaMainnet",
        chainId: 59144,
        urls: {
          apiURL: "https://api.lineascan.build/api",
          browserURL: "https://lineascan.build/",
        },
      },
      {
        network: "lineaTestnet",
        chainId: 59141,
        urls: {
          apiURL: "https://api-sepolia.lineascan.build/api",
          browserURL: "https://sepolia.lineascan.build/address",
        },
      },
      {
        network: "zoraGoerli",
        chainId: 999,
        urls: {
          apiURL: "https://testnet.explorer.zora.energy/api",
          browserURL: "https://testnet.explorer.zora.energy",
        },
      },
      {
        network: "zoraMainnet",
        chainId: 7777777,
        urls: {
          apiURL: "https://explorer.zora.energy/api",
          browserURL: "https://explorer.zora.energy",
        },
      },
      {
        network: "mantaMainnet",
        urls: {
          apiURL: "https://pacific-explorer.manta.network/api",
          browserURL: "https://pacific-explorer.manta.network",
        },
        chainId: 169,
      },
      {
        network: "mantaTestnet",
        urls: {
          apiURL: "https://pacific-explorer.testnet.manta.network/api",
          browserURL: "https://pacific-explorer.testnet.manta.network",
        },
        chainId: 3441005,
      },
      {
        network: "taikoTestnet",
        urls: {
          apiURL: "https://blockscoutapi.katla.taiko.xyz/api",
          browserURL: "https://blockscoutapi.katla.taiko.xyz/",
        },
        chainId: 167008,
      },
      {
        network: "taikoMainnet",
        urls: {
          apiURL: "https://api.taikoscan.io/api",
          browserURL: "https://api.taikoscan.io/",
        },
        chainId: 167000,
      },
      {
        network: "berachainTestnet",
        urls: {
          apiURL: "https://api.routescan.io/v2/network/testnet/evm/80085/etherscan",
          browserURL: "https://artio.beratrail.io",
        },
        chainId: 80085,
      },
      {
        network: "arbitrum",
        urls: {
          apiURL: "https://api.arbiscan.io/api",
          browserURL: "https://arbiscan.io/",
        },
        chainId: 42161,
      },
    ],
  },
  //@ts-ignore
  namedAccounts: typedNamedAccounts({
    deployer: 0,
    admin: "0x0d0D5Ff3cFeF8B7B2b1cAC6B6C27Fd0846c09361",
    operator: "0x381c031baa5995d0cc52386508050ac947780815",
    lzEndpoint: {
      arbitrum: "0x1a44076050125825900e736c501f859c50fE728c",
      taikoMainnet: "0x1a44076050125825900e736c501f859c50fE728c",
      taikoTestnet: "0x6EDCE65403992e310A62460808c4b910D972f10f",
      mantaMainnet: "0x1a44076050125825900e736c501f859c50fE728c",
      mantaTestnet: "0x6EDCE65403992e310A62460808c4b910D972f10f",
      lineaMainnet: "0x1a44076050125825900e736c501f859c50fE728c",
      lineaTestnet: "0x6EDCE65403992e310A62460808c4b910D972f10f",
      baseMainnet: "0x1a44076050125825900e736c501f859c50fE728c",
      baseSepolia: "0x6EDCE65403992e310A62460808c4b910D972f10f",
      optimismMainnet: "0x1a44076050125825900e736c501f859c50fE728c",
      optimismSepolia: "0x6EDCE65403992e310A62460808c4b910D972f10f",
      scrollMainnet: "0x1a44076050125825900e736c501f859c50fE728c",
      scrollSepolia: "0x6EDCE65403992e310A62460808c4b910D972f10f",
      zoraMainnet: "0x1a44076050125825900e736c501f859c50fE728c",
      hardhat: "0x1a44076050125825900e736c501f859c50fE728c",
    },
    mailbox: {
      arbitrum: "0x979Ca5202784112f4738403dBec5D0F3B9daabB9",
      taikoMainnet: "0x28EFBCadA00A7ed6772b3666F3898d276e88CAe3",
      taikoTestnet: "",
      mantaMainnet: "0x3a464f746D23Ab22155710f44dB16dcA53e0775E",
      mantaTestnet: "",
      lineaMainnet: "0x02d16BC51af6BfD153d67CA61754cF912E82C4d9",
      lineaTestnet: "",
      baseMainnet: "0xeA87ae93Fa0019a82A727bfd3eBd1cFCa8f64f1D",
      baseSepolia: "0x6966b0E55883d49BFB24539356a2f8A673E02039",
      optimismMainnet: "0xd4C1905BB1D26BC93DAC913e13CaCC278CdCC80D",
      optimismSepolia: "0x6966b0E55883d49BFB24539356a2f8A673E02039",
      scrollMainnet: "0x2f2aFaE1139Ce54feFC03593FeE8AB2aDF4a85A7",
      scrollSepolia: "0x3C5154a193D6e2955650f9305c8d80c18C814A68",
      zoraMainnet: "0xF5da68b2577EF5C0A0D98aA2a58483a68C2f232a",
      hardhat: "0x02d16BC51af6BfD153d67CA61754cF912E82C4d9",
    },
    igp: {
      arbitrum: "0x3b6044acd6767f017e99318AA6Ef93b7B06A5a22",
      taikoMainnet: "0x273Bc6b01D9E88c064b6E5e409BdF998246AEF42",
      taikoTestnet: "",
      mantaMainnet: "0x0D63128D887159d63De29497dfa45AFc7C699AE4",
      mantaTestnet: "",
      lineaMainnet: "0x8105a095368f1a184CceA86cCe21318B5Ee5BE28",
      lineaTestnet: "",
      baseMainnet: "0xc3F23848Ed2e04C0c6d41bd7804fa8f89F940B94",
      baseSepolia: "0x28B02B97a850872C4D33C3E024fab6499ad96564",
      optimismMainnet: "0xD8A76C4D91fCbB7Cc8eA795DFDF870E48368995C",
      optimismSepolia: "0x28B02B97a850872C4D33C3E024fab6499ad96564",
      scrollMainnet: "0xBF12ef4B9f307463D3FB59c3604F294dDCe287E2",
      scrollSepolia: "0x86fb9F1c124fB20ff130C41a79a432F770f67AFD",
      zoraMainnet: "0x18B0688990720103dB63559a3563f7E8d0f63EDb",
      hardhat: "0x8105a095368f1a184CceA86cCe21318B5Ee5BE28",
    },
    protocolChainIds: {
      layerZero: {
        //arbitrum
        "30110": 42161,
        // taikoMainnet
        "30290": 167000,
        // taikoTestnet
        "40274": 167008,
        // mantaMainnet
        "30217": 169,
        // lineaMainnet
        "30183": 59144,
        // lineaTestnet
        "40287": 59141,
        // baseMainnet
        "30184": 8453,
        // baseSepolia
        "40245": 1000000000,
        // optimismMainnet
        "30111": 10,
        // optimismSepolia
        "40232": 11155420,
        // scrollMainnet
        "30214": 534352,
        // scrollSepolia
        "40170": 534351,
        // zoraMainnet
        "30195": 7777777,
      },
      hyperlane: {
        //arbitrum
        "42161": 42161,
        // taikoMainnet
        "167000": 167000,
        // mantaMainnet
        "169": 169,
        // mantaTestnet
        "40272": 3441005,
        // lineaMainnet
        "59144": 59144,
        // baseMainnet
        "8453": 8453,
        // baseSepolia
        "84532": 1000000000,
        // optimismMainnet
        "10": 10,
        // optimismSepolia
        "11155420": 11155420,
        // scrollMainnet
        "534352": 534352,
        // scrollSepolia
        "534351": 534351,
        // zoraMainnet
        "7777777": 7777777,
      },
    },
  }),
  docgen: {
    exclude: ["./mocks"],
    pages: "files",
  },
  watcher: {
    test: {
      tasks: [{ command: "test", params: { testFiles: ["{path}"] } }],
      files: ["./test/**/*"],
      verbose: true,
    },
  },
  gasReporter: {
    enabled: !!process.env.ENABLE_GAS_REPORT,
    coinmarketcap: "4a3ee5e9-0cc5-4b90-8329-ae0e7b943075",
    currency: "USD",
    //gasPrice: 0.2,
    token: "ETH",
  },
};

export default config;
