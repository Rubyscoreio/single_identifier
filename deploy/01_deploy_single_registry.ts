import { DeployFunction, DeploymentSubmission } from "hardhat-deploy/types";
import hre from "hardhat";
import { getContractFactory } from "../utils/getContractFactory";

const migrate: DeployFunction = async ({ getNamedAccounts, run }) => {
  const { deployments, upgrades } = hre;
  const { operator } = await getNamedAccounts();

  const Registry = await getContractFactory("SingleIdentifierRegistry", {});

  const proxyContract = await upgrades.deployProxy(Registry, [operator], {
    initializer: "initialize",
    kind: "uups",
  });

  const instance = await proxyContract.waitForDeployment();
  const instanceAddress = await instance.getAddress();
  console.log(`New SingleIdentifierRegistry proxy deployed @ ${instanceAddress}`);

  const implementationAddress = await upgrades.erc1967.getImplementationAddress(instanceAddress);
  console.log(`SingleIdentifierRegistry implementation deployed @ ${implementationAddress}`);

  const artifact = await deployments.getExtendedArtifact("SingleIdentifierRegistry");
  const deployment: DeploymentSubmission = {
    address: instanceAddress,
    ...artifact,
  };
  await deployments.save("SingleIdentifierRegistry", deployment);

  const contract = `contracts/SingleIdentifierRegistry.sol:SingleIdentifierRegistry`;
  await run("verify:verify", {
    address: implementationAddress,
    constructorArguments: [],
    contract,
  });
};

migrate.tags = ["registry"];

export default migrate;
