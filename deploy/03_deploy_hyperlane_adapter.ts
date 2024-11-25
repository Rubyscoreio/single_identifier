import { DeployFunction } from "hardhat-deploy/types";
import { typedDeployments } from "@utils";
import { protocolChainIds } from "../utils/constants";

const migrate: DeployFunction = async ({ deployments, getNamedAccounts }) => {
  const { deploy, execute } = typedDeployments(deployments);
  const { deployer, admin, operator, mailbox, igp } = await getNamedAccounts();

  if (!mailbox || !igp) return;

  const gasLimit = 50000;
  const registry = await deployments.get("SingleIdentifierRegistry");

  await deploy("HyperlaneConnector", {
    from: deployer,
    args: [admin, operator, mailbox, igp, registry.address, gasLimit],
    log: true,
  });

  await execute(
    "HyperlaneConnector",
    { from: deployer, log: true },
    //@ts-ignore
    "setChainIds",
    Object.keys(
      (
        protocolChainIds as unknown as {
          hyperlane: {
            [key: string]: number;
          };
        }
      ).hyperlane,
    ).map((item) => Number(item)),
    Object.values(
      (
        protocolChainIds as unknown as {
          hyperlane: {
            [key: string]: number;
          };
        }
      ).hyperlane,
    ).map((item) => Number(item)),
  );
};

migrate.tags = ["hadapter"];

export default migrate;
