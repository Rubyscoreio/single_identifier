import { DeployFunction } from "hardhat-deploy/types";
import { typedDeployments } from "@utils";
import { ethers, upgrades } from "hardhat";

const migrate: DeployFunction = async ({ deployments, getNamedAccounts }) => {
  const { deploy } = typedDeployments(deployments);
  const { deployer, operator } = await getNamedAccounts();
  const Router = await ethers.getContractFactory("SingleRouter");
  const contract = await upgrades.deployProxy(Router, [operator], {
    initializer: "initialize",
    kind: "uups",
  });
  await contract.waitForDeployment();
  console.log(contract.address, "Router Contract Address");
};

migrate.tags = ["srouter"];

export default migrate;
