import { DeployFunction, DeploymentSubmission } from "hardhat-deploy/types";
import { upgrades } from "hardhat";
import { getContractFactory } from "../utils/getContractFactory";

const migrate: DeployFunction = async ({ deployments, getNamedAccounts, run }) => {
  const { operator } = await getNamedAccounts();
  const Router = await getContractFactory("SingleRouter", {});
  const proxyContract = await upgrades.deployProxy(Router, [operator], {
    initializer: "initialize",
    kind: "uups",
  });

  const instance = await proxyContract.waitForDeployment();
  const instanceAddress = await instance.getAddress();
  console.log(`New SingleRouter proxy deployed @ ${instanceAddress}`);

  const implementationAddress = await upgrades.erc1967.getImplementationAddress(instanceAddress);
  console.log(`SingleRouter implementation deployed @ ${implementationAddress}`);

  const artifact = await deployments.getExtendedArtifact("SingleRouter");
  const deployment: DeploymentSubmission = {
    address: instanceAddress,
    ...artifact,
  };
  await deployments.save("SingleRouter", deployment);

  const contract = `contracts/SingleRouter.sol:SingleRouter`;
  await run("verify:verify", {
    address: implementationAddress,
    constructorArguments: [],
    contract,
  });
};

migrate.tags = ["srouter"];

export default migrate;
