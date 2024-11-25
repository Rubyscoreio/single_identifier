import { DeployFunction } from "hardhat-deploy/types";
import { ethers } from "hardhat";

const migrate: DeployFunction = async ({ deployments, getNamedAccounts }) => {
  const { deployer } = await getNamedAccounts();
  const signer = await ethers.getSigner(deployer);

  //Settings Contract SingleIdentifierRegistry
  const registryDeployment = await deployments.get("SingleIdentifierRegistry");
  const registry = await ethers.getContractAt("SingleIdentifierRegistry", registryDeployment.address);

  const routerDeployment = await deployments.get("SingleRouter");
  const router = await ethers.getContractAt("SingleRouter", routerDeployment.address);

  //Settings setRouter
  let tx = await registry.connect(signer).setRouter(routerDeployment.address);
  await tx.wait();

  const hyperlaneConnectorDeployment = await deployments.get("HyperlaneConnector");
  const hyperlaneConnector = await ethers.getContractAt(
    "HyperlaneConnector",
    hyperlaneConnectorDeployment.address,
  );

  tx = await hyperlaneConnector.connect(signer).setRouter(routerDeployment.address);
  await tx.wait();

  const layerZeroConnectorDeployment = await deployments.get("LayerZeroConnector");
  const layerZeroConnector = await ethers.getContractAt(
    "LayerZeroConnector",
    layerZeroConnectorDeployment.address,
  );

  tx = await layerZeroConnector.connect(signer).setRouter(routerDeployment.address);
  await tx.wait();

  const sameChainConnectorDeployment = await deployments.get("SameChainConnector");
  const sameChainConnector = await ethers.getContractAt(
    "SameChainConnector",
    sameChainConnectorDeployment.address,
  );

  tx = await sameChainConnector.connect(signer).setRouter(routerDeployment.address);
  await tx.wait();

  const connectorAddresses = [
    sameChainConnectorDeployment.address,
    //hyperlaneConnectorDeployment.address,
    layerZeroConnectorDeployment.address,
  ];

  tx = await router.connect(signer).setConnectors([0, 2], connectorAddresses);
  await tx.wait();
};

migrate.tags = ["singleid"];

export default migrate;
