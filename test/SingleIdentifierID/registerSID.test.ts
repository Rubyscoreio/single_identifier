import { deployments, ethers, getChainId } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { AbiCoder, ContractFactory, ZeroAddress } from "ethers";
import { sign, HardhatEthersSigner } from "@test-utils";
import { expect } from "chai";
import { SingleIdentifierID, SingleIdentifierRegistry } from "@contracts";
import { SIDSchemaParamsStruct } from "@contracts/SingleIdentifierRegistry";
import { delay } from "../../utils/utils";

describe("Method: registerSID", () => {
  const protocolFee = "50000";
  const gasLimit = "300000";
  const lzEidB = 2;

  async function deployRegisterContract() {
    const [deployer, admin, operator, endpointOwner] = await ethers.getSigners();

    //const EndpointV2Mock = await ethers.getContractFactory("EndpointV2Mock");
    const EndpointV2MockArtifact = await deployments.getArtifact("EndpointV2Mock");
    const EndpointV2Mock = new ContractFactory(
      EndpointV2MockArtifact.abi,
      EndpointV2MockArtifact.bytecode,
      endpointOwner,
    );
    const currentChainId2 = await getChainId();
    const mockLzEndpointA = await EndpointV2Mock.deploy(currentChainId2);
    const mockLzEndpointB = await EndpointV2Mock.deploy(lzEidB);

    const RegistryInstance = await ethers.getContractFactory("SingleIdentifierRegistry");
    const registryContractA = await RegistryInstance.connect(deployer).deploy(operator.address);
    const registryContractB = await RegistryInstance.connect(deployer).deploy(operator.address);

    const SameChainConnectorInstance = await ethers.getContractFactory("SameChainConnector");
    const sameChainConnectorA = await SameChainConnectorInstance.deploy(
      admin.address,
      operator.address,
      registryContractA.getAddress(),
    );
    const sameChainConnectorB = await SameChainConnectorInstance.deploy(
      admin.address,
      operator.address,
      registryContractB.getAddress(),
    );

    const LayerZeroConnectorInstance = await ethers.getContractFactory("LayerZeroConnector");
    const layerZeroConnectorA = await LayerZeroConnectorInstance.deploy(
      mockLzEndpointA.getAddress(),
      admin.address,
      operator.address,
      registryContractA.getAddress(),
      gasLimit,
    );
    const layerZeroConnectorB = await LayerZeroConnectorInstance.deploy(
      mockLzEndpointB.getAddress(),
      admin.address,
      operator.address,
      registryContractB.getAddress(),
      gasLimit,
    );

    await mockLzEndpointA
      .connect(deployer)
      //@ts-ignore
      .setDestLzEndpoint(layerZeroConnectorB.getAddress(), mockLzEndpointB.getAddress());

    await mockLzEndpointB
      .connect(deployer)
      //@ts-ignore
      .setDestLzEndpoint(layerZeroConnectorA.getAddress(), mockLzEndpointA.getAddress());

    const SingleRouterInstance = await ethers.getContractFactory("SingleRouter");
    const singleRouterA = await SingleRouterInstance.deploy(operator.address);
    const singleRouterB = await SingleRouterInstance.deploy(operator.address);

    const SignleIDInstance = await ethers.getContractFactory("SingleIdentifierID");
    const singleIDA = await SignleIDInstance.deploy(
      protocolFee,
      admin.address,
      operator.address,
      singleRouterA.getAddress(),
    );
    const singleIDB = await SignleIDInstance.deploy(
      protocolFee,
      admin.address,
      operator.address,
      singleRouterB.getAddress(),
    );

    //-------------------------------------------
    let tx = await registryContractA.connect(deployer).setRouter(singleRouterA.getAddress());
    await tx.wait();
    tx = await registryContractB.connect(deployer).setRouter(singleRouterB.getAddress());
    await tx.wait();

    tx = await layerZeroConnectorA.connect(deployer).setRouter(singleRouterA.getAddress());
    await tx.wait();
    tx = await layerZeroConnectorB.connect(deployer).setRouter(singleRouterB.getAddress());
    await tx.wait();

    tx = await sameChainConnectorA.connect(deployer).setRouter(singleRouterA.getAddress());
    await tx.wait();
    tx = await sameChainConnectorB.connect(deployer).setRouter(singleRouterB.getAddress());
    await tx.wait();

    const connectorAddressesA = [
      await sameChainConnectorA.getAddress(),
      //hyperlaneConnectorDeployment.address,
      await layerZeroConnectorA.getAddress(),
    ];

    const connectorAddressesB = [
      await sameChainConnectorB.getAddress(),
      //hyperlaneConnectorDeployment.address,
      await layerZeroConnectorB.getAddress(),
    ];

    tx = await singleRouterA.connect(deployer).setConnectors([0, 1], connectorAddressesA);
    await tx.wait();
    tx = await singleRouterB.connect(deployer).setConnectors([0, 1], connectorAddressesB);
    await tx.wait();
    //-------------------------------------------
    tx = await layerZeroConnectorA.connect(deployer).setRouter(singleRouterA.getAddress());
    await tx.wait();
    tx = await layerZeroConnectorB.connect(deployer).setRouter(singleRouterB.getAddress());
    await tx.wait();

    tx = await sameChainConnectorA.connect(deployer).setRouter(singleRouterA.getAddress());
    await tx.wait();
    tx = await sameChainConnectorB.connect(deployer).setRouter(singleRouterB.getAddress());
    await tx.wait();
    //-------------------------------------------
    const currentChainId = await getChainId();
    tx = await layerZeroConnectorA
      .connect(deployer)
      .setChainIds([currentChainId, lzEidB], [currentChainId, lzEidB]);
    await tx.wait();
    tx = await layerZeroConnectorB
      .connect(deployer)
      .setChainIds([currentChainId, lzEidB], [currentChainId, lzEidB]);
    await tx.wait();

    tx = await sameChainConnectorA
      .connect(deployer)
      .setChainIds([currentChainId, lzEidB], [currentChainId, lzEidB]);
    await tx.wait();
    tx = await sameChainConnectorB
      .connect(deployer)
      .setChainIds([currentChainId, lzEidB], [currentChainId, lzEidB]);
    await tx.wait();
    //-------------------------------------------

    const sameChainsAddresses = await Promise.all([
      sameChainConnectorA.getAddress(),
      sameChainConnectorB.getAddress(),
    ]);
    tx = await singleRouterA.connect(deployer).setPeers(
      0,
      [currentChainId, lzEidB],
      sameChainsAddresses.map((item) => {
        const strippedAddress = item.replace(/^0x/, "");
        // Добавляем нули в начало до 64 символов (32 байта в hex)
        const padded = strippedAddress.padStart(64, "0");
        // Возвращаем адрес с "0x"
        return `0x${padded}`;
      }),
    );
    await tx.wait();

    const lzAddresses = await Promise.all([
      layerZeroConnectorA.getAddress(),
      layerZeroConnectorB.getAddress(),
    ]);
    tx = await singleRouterA.connect(deployer).setPeers(
      1,
      [currentChainId, lzEidB],
      lzAddresses.map((item) => {
        const strippedAddress = item.replace(/^0x/, "");
        // Добавляем нули в начало до 64 символов (32 байта в hex)
        const padded = strippedAddress.padStart(64, "0");
        // Возвращаем адрес с "0x"
        return `0x${padded}`;
      }),
    );
    await tx.wait();

    tx = await singleRouterB.connect(deployer).setPeers(
      0,
      [currentChainId, lzEidB],
      sameChainsAddresses.map((item) => {
        const strippedAddress = item.replace(/^0x/, "");
        // Добавляем нули в начало до 64 символов (32 байта в hex)
        const padded = strippedAddress.padStart(64, "0");
        // Возвращаем адрес с "0x"
        return `0x${padded}`;
      }),
    );
    await tx.wait();

    tx = await singleRouterB.connect(deployer).setPeers(
      1,
      [currentChainId, lzEidB],
      lzAddresses.map((item) => {
        const strippedAddress = item.replace(/^0x/, "");
        // Добавляем нули в начало до 64 символов (32 байта в hex)
        const padded = strippedAddress.padStart(64, "0");
        // Возвращаем адрес с "0x"
        return `0x${padded}`;
      }),
    );
    await tx.wait();

    const lzs = lzAddresses.map((item) => {
      const strippedAddress = item.replace(/^0x/, "");
      // Добавляем нули в начало до 64 символов (32 байта в hex)
      const padded = strippedAddress.padStart(64, "0");
      // Возвращаем адрес с "0x"
      return `0x${padded}`;
    });

    await layerZeroConnectorA.connect(admin).setPeer(lzEidB, lzs[0]);
    await layerZeroConnectorA.connect(admin).setPeer(lzEidB, lzs[1]);
    await layerZeroConnectorB.connect(admin).setPeer(currentChainId, lzs[0]);
    await layerZeroConnectorB.connect(admin).setPeer(currentChainId, lzs[1]);

    /*const peer = await singleRouterA.getPeer(1, currentChainId);
    console.log("TEST PEER PEER PEER", peer, lzAddresses);*/
    //-------------------------------------------

    return {
      deployer,
      admin,
      operator,
      registryContractA,
      registryContractB,
      singleIDA,
      singleIDB,
      mockLzEndpointA,
      mockLzEndpointB,
    };
  }

  let deployer: HardhatEthersSigner;
  let admin: HardhatEthersSigner;
  let operator: HardhatEthersSigner;
  let emitter: HardhatEthersSigner;
  let user: HardhatEthersSigner;
  let registryContractA: SingleIdentifierRegistry;
  let registryContractB: SingleIdentifierRegistry;
  let singleIDA: SingleIdentifierID;
  let singleIDB: SingleIdentifierID;
  let registryParams: SIDSchemaParamsStruct;
  let registerSignature;
  let sendSidWithRegistryParams;
  //@ts-ignore
  let sendSidWithRegistrySignature;
  //@ts-ignore
  let resultRegisterEmitter;
  //@ts-ignore
  let schemaId;
  let resultRegistrySid;
  before(async () => {
    const fixture = await loadFixture(deployRegisterContract);
    deployer = fixture.deployer;
    admin = fixture.admin;
    operator = fixture.operator;
    registryContractA = fixture.registryContractA;
    registryContractB = fixture.registryContractB;
    singleIDA = fixture.singleIDA;
    singleIDB = fixture.singleIDB;

    [emitter, user] = await ethers.getSigners();

    const registryAddressA = await registryContractA.getAddress();
    const registryAddressB = await registryContractB.getAddress();
    const singleIDAddressA = await singleIDA.getAddress();
    const singleIDAddressB = await singleIDB.getAddress();
    console.log(`
    deployer: ${deployer.address}
    admin: ${admin.address}
    operator: ${operator.address}
    registryA: ${registryAddressA}
    registryB: ${registryAddressB}
    singleIdAddressA: ${singleIDAddressA}
    singleIdAddressB: ${singleIDAddressB}
    `);

    const registryDomain = {
      name: "Rubyscore_Single_Identifier_Registry",
      version: "0.0.1",
      chainId: await getChainId(),
      verifyingContract: await registryContractB.getAddress(),
    };

    const registryTypes = {
      SchemaRegistryParams: [
        { name: "name", type: "string" },
        { name: "description", type: "string" },
        { name: "schema", type: "string" },
        { name: "emitter", type: "address" },
      ],
    };

    registryParams = {
      name: "Test register emitter",
      description: "Test description emitter",
      schema: "string metadata",
      emitter: emitter.address,
    };

    registerSignature = await sign(
      registryDomain,
      registryTypes,
      registryParams as Record<string, any>,
      operator,
    );

    resultRegisterEmitter = await registryContractB
      .connect(emitter)
      .schemaRegistry(registryParams, registerSignature);
    schemaId = await registryContractB.schemaIds(emitter.address);

    const sendSidDomain = {
      name: "Rubyscore_Single_Identifier_Id",
      version: "0.0.1",
      chainId: 0,
      verifyingContract: ZeroAddress,
    };

    const sendSidTypes = {
      SendWithRegistryParams: [
        { name: "schemaId", type: "bytes32" },
        { name: "emitterAddress", type: "address" },
        { name: "registryChainId", type: "uint256" },
        { name: "user", type: "address" },
        { name: "data", type: "bytes" },
      ],
    };

    const currentChainId = await getChainId();

    sendSidWithRegistryParams = {
      //@ts-ignore
      schemaId,
      emitterAddress: emitter.address,
      registryChainId: lzEidB,
      user: user.address,
      data: ethers.toUtf8Bytes("custom data"),
    };

    sendSidWithRegistrySignature = await sign(
      sendSidDomain,
      sendSidTypes,
      sendSidWithRegistryParams as Record<string, any>,
      operator,
    );

    resultRegistrySid = await singleIDA.connect(user).registerSIDWithEmitter(
      //@ts-ignore
      schemaId,
      1,
      1732861209,
      100000,
      lzEidB,
      emitter.address,
      ethers.toUtf8Bytes("custom data"),
      "https://test.com",
      //@ts-ignore
      sendSidWithRegistrySignature,
      { value: ethers.parseEther("1.0") },
    );
  });

  describe("Should deploy contracts", () => {
    it("Test register emitter", async () => {
      //@ts-ignore
      await expect(resultRegisterEmitter).to.be.not.reverted;
    });

    it("Test register sid", async () => {
      const abiCoder = new AbiCoder();
      //@ts-ignore
      const encodedData = abiCoder.encode(["bytes32", "address"], [schemaId, user.address]);
      const hashedData = ethers.keccak256(encodedData);
      //const sid = await registryContractB.singleIdentifierData(hashedData);
      const sidCount = await registryContractB.sidCounter();
      const emitterCount = await registryContractB.emitterCounter();
      console.log("SID ID in TEST", sidCount, emitterCount);
      /*expect(sid).to.be.equals([
        hashedData,
        //@ts-ignore
        schemaId,
        BigInt(1732861209),
        BigInt(0),
        false,
        user.address,
        ethers.toUtf8Bytes("custom data"),
        "https://test.com",
      ]);*/
    });

    //it("Test exist sid", async () => {});
  });
});
