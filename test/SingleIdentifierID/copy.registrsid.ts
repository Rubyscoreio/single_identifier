import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { MockMailbox__factory } from "@hyperlane-xyz/core";

describe("Method: registerSID", () => {
  const protocolFee = "50000";
  const gasLimit = "50000";
  const lzEidA = 1;
  const lzEidB = 2;

  const hylEidA = 10;
  const hylEidB = 20;

  async function deployRegisterContract() {
    const [deployer, admin, operator, endpointOwner] = await ethers.getSigners();

    const EndpointV2Mock = await ethers.getContractFactory("EndpointV2Mock");
    const mockLzEndpointA = await EndpointV2Mock.deploy(lzEidA);
    const mockLzEndpointB = await EndpointV2Mock.deploy(lzEidB);
    const mockMailboxA = await new MockMailbox__factory(endpointOwner.address).deploy(hylEidA);
    const mockMailboxB = await new MockMailbox__factory(endpointOwner.address).deploy(hylEidB);

    const RegistryInstance = await ethers.getContractFactory("SingleIdentifierRegistry");
    const registryContract = await RegistryInstance.connect(deployer).deploy(
      mockLzEndpointB.getAddress(),
      mockMailboxB.getAddress(),
      admin.address,
      operator.address,
    );

    const LayerZeroAdapterInstance = await ethers.getContractFactory("LayerZeroAdapter");
    const layerZeroAdapter = await LayerZeroAdapterInstance.deploy(
      gasLimit,
      mockLzEndpointA.getAddress(),
      admin.address,
    );
    const HyperlaneAdapterInstance = await ethers.getContractFactory("HyperlaneAdapter");
    const hyperlaneAdapter = await HyperlaneAdapterInstance.deploy(
      gasLimit,
      // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
      mockMailboxA.getAddress(),
      // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
      mockMailboxA.getAddress(), // TODO: Здесь должен быть IGP конртакт, пока не понял, где найти mock
      admin.address,
    );
    const SameChainAdapterInstance = await ethers.getContractFactory("SameChainAdapter");
    const sameChainAdapter = await SameChainAdapterInstance.deploy(
      operator.address,
      registryContract.getAddress(),
    );

    const protocolIds = [0, 1, 2];

    const protocolAddresses = await Promise.all([
      sameChainAdapter.getAddress(),
      hyperlaneAdapter.getAddress(),
      layerZeroAdapter.getAddress(),
    ]);

    console.log(protocolIds, protocolAddresses);

    const SingleRouterInstance = await ethers.getContractFactory("SingleRouter");
    const singleRouter = await SingleRouterInstance.deploy(operator.address, protocolIds, protocolAddresses);

    const SignleIDInstance = await ethers.getContractFactory("SingleIdentifierID");
    const SingleID = await SignleIDInstance.deploy(
      protocolFee,
      admin.address,
      operator.address,
      singleRouter.getAddress(),
    );
  }

  describe("Should deloy contracts", () => {
    it("Test deploy contracts", async () => {
      //const hyperlaneCore = await import("@hyperlane-xyz/core").then((hl) => hl.default).catch(console.error);
      // eslint-disable-next-line @typescript-eslint/no-implied-eval
      const dynamicImport = new Function("specifier", "return import(specifier)");
      const dynamicallyLoadedEsmModule = await dynamicImport("@hyperlane-xyz/core");
      await loadFixture(deployRegisterContract);
    });
  });
});
