import { DeployFunction } from "hardhat-deploy/types";
import { typedDeployments } from "@utils";
import { ethers, upgrades } from "hardhat";

const migrate: DeployFunction = async ({ deployments, getNamedAccounts }) => {
  const { deploy } = typedDeployments(deployments);
  const { deployer, operator } = await getNamedAccounts();

  const Registry = await ethers.getContractFactory("SingleIdentifierRegistry");
  const contract = await upgrades.deployProxy(Registry, [operator], {
    initializer: "initialize",
    kind: "uups",
  });

  await contract.waitForDeployment();
  console.log(contract.address, "Registry Contract Address");
};

migrate.tags = ["registry"];

export default migrate;
