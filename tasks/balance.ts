import { task } from "hardhat/config";

task("balance", "Prints an account's balance")
  .addParam("account", "The account's address")
  .setAction(async (taskArgs: { account: string }, { ethers }) => {
    const balance = await ethers.provider.getBalance(taskArgs.account);
    //@ts-ignore
    console.log(ethers.utils.formatEther(balance), "ETH");
  });
