import { DeployFunction } from "hardhat-deploy/types";
import { typedDeployments } from "@utils";
import { ethers, upgrades } from "hardhat";

const migrate: DeployFunction = async ({ deployments, getNamedAccounts }) => {
  const { deploy } = typedDeployments(deployments);
  const { deployer, admin, operator } = await getNamedAccounts();

  const protocolFee = 1000000000;
  const router = await deployments.get("SingleRouter");

  const SingleID = await ethers.getContractFactory("SingleIdentifierID");
  const contract = await upgrades.deployProxy(SingleID, [protocolFee, admin, operator, router.address], {
    initializer: "initialize",
    kind: "uups",
  });
  await contract.waitForDeployment();
  console.log(contract.address, "Single ID Contract Address");
};

migrate.tags = ["singleid"];

export default migrate;
