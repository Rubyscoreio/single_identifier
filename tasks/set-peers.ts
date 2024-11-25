import { task } from "hardhat/config";
import { readdir, readFile } from "fs/promises";
import { BytesLike } from "ethers/src.ts/utils/data";

task("set-peers", "Prints an account's balance").setAction(
  async ({}, { ethers, deployments, getNamedAccounts }) => {
    const { deployer } = await getNamedAccounts();
    const signer = await ethers.getSigner(deployer);

    const routerDeployment = await deployments.get("SingleRouter");
    const router = await ethers.getContractAt("SingleRouter", routerDeployment.address);

    const rawFolders = await readdir(`deployments`);
    const folders = rawFolders.filter((item) => item !== ".DS_Store" && item !== ".gitignore");

    const peers = {
      //sameChain
      "0": {},
      //hyperlane
      "1": {},
      //layerzero
      "2": {},
    };

    for (const file of folders) {
      const lzFileName = "LayerZeroConnector.json";
      const hyperlaneFileName = "HyperlaneConnector.json";
      const sameChainFileName = "SameChainConnector.json";
      const chainIdFileName = ".chainId";

      const rawFiles = await readdir(`deployments/${file}`);
      if (
        rawFiles.every((item) => item == lzFileName || item == hyperlaneFileName || item == sameChainFileName)
      ) {
        continue;
      }

      const chainId = await readFile(`deployments/${file}/${chainIdFileName}`, "utf8");
      const layerZeroConnectorJson = JSON.parse(
        await readFile(`deployments/${file}/LayerZeroConnector.json`, "utf8"),
      )?.address;
      //@ts-ignore
      peers["2"][chainId] = layerZeroConnectorJson;

      const hyperlaneConnectorJson = JSON.parse(
        await readFile(`deployments/${file}/HyperlaneConnector.json`, "utf8"),
      )?.address;
      //@ts-ignore
      peers["1"][chainId] = hyperlaneConnectorJson;

      const sameChainConnectorJson = JSON.parse(
        await readFile(`deployments/${file}/SameChainConnector.json`, "utf8"),
      )?.address;
      //@ts-ignore
      peers["0"][chainId] = sameChainConnectorJson;
      console.log(chainId);
    }

    console.log("Set peers to same chain...");
    let tx = await router.connect(signer).setPeers(
      0,
      Object.keys(peers["0"]).map((item) => Number(item)),
      Object.values(peers["0"]).map((item) => {
        const strippedAddress = (item as string).replace(/^0x/, "");
        // Добавляем нули в начало до 64 символов (32 байта в hex)
        const padded = strippedAddress.padStart(64, "0");
        // Возвращаем адрес с "0x"
        return `0x${padded}`;
      }),
    );
    await tx.wait();

    console.log("Set peers to hyperlane...");
    tx = await router.connect(signer).setPeers(
      1,
      Object.keys(peers["1"]).map((item) => Number(item)),
      Object.values(peers["1"]).map((item) => {
        const strippedAddress = (item as string).replace(/^0x/, "");
        // Добавляем нули в начало до 64 символов (32 байта в hex)
        const padded = strippedAddress.padStart(64, "0");
        // Возвращаем адрес с "0x"
        return `0x${padded}`;
      }),
    );
    await tx.wait();

    console.log("Set peers to layerzero...");
    tx = await router.connect(signer).setPeers(
      2,
      Object.keys(peers["2"]).map((item) => Number(item)),
      Object.values(peers["2"]).map((item) => {
        const strippedAddress = (item as string).replace(/^0x/, "");
        // Добавляем нули в начало до 64 символов (32 байта в hex)
        const padded = strippedAddress.padStart(64, "0");
        // Возвращаем адрес с "0x"
        return `0x${padded}`;
      }),
    );
    await tx.wait();
  },
);
