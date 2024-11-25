import { DeployFunction } from "hardhat-deploy/types";
import { typedDeployments } from "@utils";

const migrate: DeployFunction = async ({ deployments, getNamedAccounts }) => {
  const { deploy } = typedDeployments(deployments);
  const { deployer, admin, operator } = await getNamedAccounts();

  const protocolFee = 1000000000;
  const router = await deployments.get("SingleRouter");

  await deploy("SingleIdentifierID", {
    from: deployer,
    args: [protocolFee, admin, operator, router.address],
    log: true,
  });
};

migrate.tags = ["singleid"];

export default migrate;
