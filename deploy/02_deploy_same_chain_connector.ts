import { DeployFunction } from "hardhat-deploy/types";
import { typedDeployments } from "@utils";
import { protocolChainIds } from "../utils/constants";

const migrate: DeployFunction = async ({ deployments, getNamedAccounts }) => {
  const { deploy, execute } = typedDeployments(deployments);
  const { deployer, admin, operator } = await getNamedAccounts();

  const registry = await deployments.get("SingleIdentifierRegistry");

  await deploy("SameChainConnector", {
    from: deployer,
    args: [admin, operator, registry.address],
    log: true,
  });

  await execute(
    "SameChainConnector",
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
    Object.keys(
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

migrate.tags = ["registry"];

export default migrate;
