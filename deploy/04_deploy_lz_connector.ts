import { DeployFunction } from "hardhat-deploy/types";
import { typedDeployments } from "@utils";
import { protocolChainIds } from "../utils/constants";

const migrate: DeployFunction = async ({ deployments, getNamedAccounts }) => {
  const { deploy, execute } = typedDeployments(deployments);
  const { deployer, admin, operator, lzEndpoint } = await getNamedAccounts();

  if (!lzEndpoint) return;

  const gasLimit = 50000;
  const registry = await deployments.get("SingleIdentifierRegistry");

  await deploy("LayerZeroConnector", {
    from: deployer,
    args: [lzEndpoint, admin, operator, registry.address, gasLimit],
    log: true,
  });

  await execute(
    "LayerZeroConnector",
    { from: deployer, log: true },
    //@ts-ignore
    "setChainIds",
    Object.keys(
      (
        protocolChainIds as unknown as {
          layerZero: {
            [key: string]: number;
          };
        }
      ).layerZero,
    ).map((item) => Number(item)),
    Object.values(
      (
        protocolChainIds as unknown as {
          layerZero: {
            [key: string]: number;
          };
        }
      ).layerZero,
    ).map((item) => Number(item)),
  );
};

migrate.tags = ["lzconnector"];

export default migrate;
