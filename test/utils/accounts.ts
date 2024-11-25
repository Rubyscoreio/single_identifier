import { ethers } from "hardhat";

export function randomAccount(): string {
  return ethers.Wallet.createRandom().address;
}

export function randomAccounts(amount: number): string[] {
  return [...Array(amount)].map(() => randomAccount());
}
