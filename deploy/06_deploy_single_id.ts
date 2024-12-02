import { DeployFunction, DeploymentSubmission } from "hardhat-deploy/types";
import { ethers, upgrades } from "hardhat";

const migrate: DeployFunction = async ({ deployments, getNamedAccounts, run }) => {
  const { admin, operator } = await getNamedAccounts();

  const protocolFee = 1000000000;
  const router = await deployments.get("SingleRouter");

  const SingleID = await ethers.getContractFactory("SingleIdentifierID");
  const proxyContract = await upgrades.deployProxy(SingleID, [protocolFee, admin, operator, router.address], {
    initializer: "initialize",
    kind: "uups",
  });

  const instance = await proxyContract.waitForDeployment();
  const instanceAddress = await instance.getAddress();
  console.log(`New SingleIdentifierID proxy deployed @ ${instanceAddress}`);

  const implementationAddress = await upgrades.erc1967.getImplementationAddress(instanceAddress);
  console.log(`SingleIdentifierID implementation deployed @ ${implementationAddress}`);

  const artifact = await deployments.getExtendedArtifact("SingleIdentifierID");
  const deployment: DeploymentSubmission = {
    address: instanceAddress,
    ...artifact,
  };
  await deployments.save("SingleIdentifierID", deployment);

  const contract = `contracts/SingleIdentifierID.sol:SingleIdentifierID`;
  await run("verify:verify", {
    address: implementationAddress,
    constructorArguments: [],
    contract,
  });
};

migrate.tags = ["singleid"];

export default migrate;
