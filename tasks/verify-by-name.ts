import { string } from "hardhat/internal/core/params/argumentTypes";
import { task } from "hardhat/config";

task("verify-by-name", "Verification of contracts whose names have been transferred")
  .addParam("contracts", "List of contracts names example 'Lock,YourContractName'", "", string)
  .setAction(async ({ contracts }, { run, deployments }) => {
    const { typedDeployments } = await import("@utils");
    const { get } = typedDeployments(deployments);

    const names = contracts.split(",");
    console.log("\x1b[36m%s\x1b[0m", `\nStart verify contracts: ${names}`);

    const success = [];
    const fail = [];

    for await (const item of names) {
      const { address, args, storageLayout } = await get(item);

      console.log(`\n\u250F Contract: ${item} \n\u2517`);
      console.log(`  \u2523 Storage: ${storageLayout?.storage[0]?.contract}`);
      console.log(`  \u2523 Address: ${address}`);
      console.log(`  \u2517 Params: ${args} \n`);

      try {
        await run("verify:verify", {
          address,
          constructorArguments: args,
          contract: storageLayout?.storage[0]?.contract,
        });

        success.push(item);
        console.info("\x1b[32m%s\x1b[0m", `${item} - OK`);
      } catch (e) {
        fail.push(item);

        console.error("\x1b[31m%s\x1b[0m", e);
        console.error("\x1b[31m%s\x1b[0m", `${item} - ERROR`);

        continue;
      }
    }

    console.info("\x1b[36m%s\x1b[0m", `\nTotal contracts for verification: [${names.length}]`);
    console.info("\x1b[32m%s\x1b[0m", `Success verify: [${success.length}]`);

    for (const item of success) {
      console.log("\x1b[32m%s\x1b[0m", `✔ - ${item}`);
    }

    if (fail.length > 0) {
      console.log("\x1b[31m%s\x1b[0m", `Fail verify: [${fail.length}]`);

      for (const item of fail) {
        console.log("\x1b[31m%s\x1b[0m", `x - ${item}`);
      }
    }
  });
