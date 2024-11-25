import path from "path";
import dotenv from "dotenv";

dotenv.config({ path: path.resolve(__dirname, "./.env") });

interface ENV {
  DEPLOYER_KEY: string | undefined;
  INFURA_KEY: string | undefined;
  ETHERSCAN_API_KEY: string | undefined;
  POLYGONSCAN_API_KEY: string | undefined;
  BSCSCAN_API_KEY: string | undefined;
  LINEASCAN_API_KEY: string | undefined;
  BASESCAN_API_KEY: string | undefined;
  OPTIMIZM_API_KEY: string | undefined;
  POLYGONZKSCAN_API_KEY: string | undefined;
  SCROLLSCAN_API_KEY: string | undefined;
  ZORASCAN_API_KEY: string | undefined;
  MANTASCAN_API_KEY: string | undefined;
  MANTLESCAN_API_KEY: string | undefined;
  TAIKOSCAN_API_KEY: string | undefined;
  BERACHAINSCAN_API_KEY: string | undefined;
  ARBITRUM_API_KEY: string | undefined;
}
interface Config {
  DEPLOYER_KEY: string;
  INFURA_KEY: string;
  ETHERSCAN_API_KEY: string;
  POLYGONSCAN_API_KEY: string;
  BSCSCAN_API_KEY: string;
  LINEASCAN_API_KEY: string;
  BASESCAN_API_KEY: string;
  OPTIMIZM_API_KEY: string;
  POLYGONZKSCAN_API_KEY: string;
  SCROLLSCAN_API_KEY: string;
  ZORASCAN_API_KEY: string;
  MANTASCAN_API_KEY: string;
  MANTLESCAN_API_KEY: string;
  TAIKOSCAN_API_KEY: string;
  BERACHAINSCAN_API_KEY: string;
  ARBITRUM_API_KEY: string;
}

const getConfig = (): ENV => {
  return {
    DEPLOYER_KEY: process.env.DEPLOYER_KEY,
    INFURA_KEY: process.env.INFURA_KEY,
    ETHERSCAN_API_KEY: process.env.ETHERSCAN_API_KEY,
    POLYGONSCAN_API_KEY: process.env.POLYGONSCAN_API_KEY,
    BSCSCAN_API_KEY: process.env.BSCSCAN_API_KEY,
    LINEASCAN_API_KEY: process.env.LINEASCAN_API_KEY,
    BASESCAN_API_KEY: process.env.BASESCAN_API_KEY,
    OPTIMIZM_API_KEY: process.env.OPTIMIZM_API_KEY,
    POLYGONZKSCAN_API_KEY: process.env.POLYGONZKSCAN_API_KEY,
    SCROLLSCAN_API_KEY: process.env.SCROLLSCAN_API_KEY,
    ZORASCAN_API_KEY: process.env.ZORASCAN_API_KEY,
    MANTASCAN_API_KEY: process.env.MANTASCAN_API_KEY,
    MANTLESCAN_API_KEY: process.env.MANTLESCAN_API_KEY,
    TAIKOSCAN_API_KEY: process.env.TAIKOSCAN_API_KEY,
    BERACHAINSCAN_API_KEY: process.env.TAIKOSCAN_API_KEY,
    ARBITRUM_API_KEY: process.env.ARBITRUM_API_KEY,
  };
};

const getSanitzedConfig = (config: ENV): Config => {
  for (const [key, value] of Object.entries(config)) {
    if (value === undefined) {
      throw new Error(`Missing key ${key} in config.env`);
    }
  }
  return config as Config;
};

const config = getConfig();

const sanitizedConfig = getSanitzedConfig(config);

export default sanitizedConfig;
