import { DeployFunction } from "hardhat-deploy/types";
import { typedDeployments } from "@utils";

const migrate: DeployFunction = async ({ deployments, getNamedAccounts }) => {
  const { deploy } = typedDeployments(deployments);
  const { deployer, operator } = await getNamedAccounts();

  await deploy("SingleRouter", {
    from: deployer,
    args: [operator],
    log: true,
  });
};

migrate.tags = ["srouter"];

export default migrate;
