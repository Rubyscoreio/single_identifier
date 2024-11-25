import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { ethers } from "hardhat";

async function getSigner(account: string): Promise<HardhatEthersSigner | undefined> {
  const signers = await ethers.getSigners();

  return signers.find((signer) => {
    return account === signer.address;
  });
}

export { getSigner, HardhatEthersSigner };
