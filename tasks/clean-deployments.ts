import { task } from "hardhat/config";

task("clean-deployments", "Clean deployments for one network").setAction(
  async ({}, { deployments, network }) => {
    const allDeployments = await deployments.all();

    for await (const item of Object.keys(allDeployments)) {
      console.log(item);
      await deployments.delete(item);
    }

    console.log("\x1b[36m%s\x1b[0m", `Network ${network.name} cleaned`);
  },
);
