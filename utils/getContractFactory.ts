import fs from "fs";
import path from "path";
import { FactoryOptions } from "hardhat/types";
import { ethers } from "hardhat";
import { Signer, ContractFactory } from "ethers";
import { getAbi, getBytecode } from "@uma/contracts-node";
import * as deployments_ from "../deployments/deployments.json";

function isFactoryOptions(
  signerOrFactoryOptions: Signer | FactoryOptions,
): signerOrFactoryOptions is FactoryOptions {
  return "signer" in signerOrFactoryOptions || "libraries" in signerOrFactoryOptions;
}

export function getAllFilesInPath(dirPath: string, arrayOfFiles: string[] = []): string[] {
  const files = fs.readdirSync(dirPath);

  files.forEach((file) => {
    if (fs.statSync(dirPath + "/" + file).isDirectory())
      arrayOfFiles = getAllFilesInPath(dirPath + "/" + file, arrayOfFiles);
    else arrayOfFiles.push(path.join(dirPath, "/", file));
  });

  return arrayOfFiles;
}

export function findArtifactFromPath(contractName: string, artifactsPath: string) {
  const allArtifactsPaths = getAllFilesInPath(artifactsPath);
  const desiredArtifactPaths = allArtifactsPaths.filter((a) => a.endsWith(`/${contractName}.json`));

  if (desiredArtifactPaths.length !== 1)
    throw new Error(`Couldn't find desired artifact or found too many for ${contractName}`);
  //@ts-ignore
  return JSON.parse(fs.readFileSync(desiredArtifactPaths[0], "utf-8"));
}

// Fetch the artifact from the publish package's artifacts directory.
function getLocalArtifact(contractName: string) {
  const artifactsPath = path.join(__dirname, "../../artifacts/contracts");
  //@ts-ignore
  return findArtifactFromPath(contractName, artifactsPath);
}

export async function getContractFactory(
  name: string,
  signerOrFactoryOptions: Signer | FactoryOptions,
): Promise<ContractFactory> {
  try {
    // First, try get the artifact from this repo.
    return await ethers.getContractFactory(name, signerOrFactoryOptions);
  } catch (_) {
    try {
      // If it does not exist then try find the contract in the UMA core package.
      if (isFactoryOptions(signerOrFactoryOptions))
        throw new Error("Cannot pass FactoryOptions to a contract imported from UMA");
      return new ContractFactory(getAbi(name as any), getBytecode(name as any), signerOrFactoryOptions);
    } catch (_) {
      try {
        const localArtifact = getLocalArtifact(name);
        return new ContractFactory(
          localArtifact.abi,
          localArtifact.bytecode,
          signerOrFactoryOptions as Signer,
        );
      } catch (_) {
        throw new Error(`Could not find the artifact for ${name}!`);
      }
    }
  }
}

export function getDeployedAddress(
  contractName: string,
  networkId: number,
  throwOnError = true,
): string | undefined {
  const address = deployments_[networkId.toString()]?.[contractName]?.address;
  if (!address && throwOnError) {
    throw new Error(`Contract ${contractName} not found on ${networkId} in deployments.json`);
  }

  //@ts-ignore
  return address;
}
