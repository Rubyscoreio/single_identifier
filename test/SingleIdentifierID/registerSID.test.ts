import { deployments, ethers, getChainId } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { ContractFactory, ContractTransactionResponse, hexlify, ZeroAddress } from "ethers";
import { sign, HardhatEthersSigner, Domain } from "@test-utils";
import { expect } from "chai";
import { SingleIdentifierID, SingleIdentifierRegistry } from "@contracts";
import { SIDSchemaParamsStruct } from "@contracts/SingleIdentifierRegistry";
import { addressToBytes32 } from "../../utils/addressToBytes32";

describe("Method: registerSID", () => {
  const protocolFee = "50000";
  const emitterFee = "100000";
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

    const addr = await sameChainConnectorA.getAddress();
    const addrB = await sameChainConnectorB.getAddress();
    console.log("Same Chain AddressA", addr);
    console.log("Same Chain AddressB", addrB);
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
    tx = await layerZeroConnectorA.connect(deployer).setSingleId(singleIDA.getAddress());
    await tx.wait();
    tx = await layerZeroConnectorB.connect(deployer).setSingleId(singleIDB.getAddress());
    await tx.wait();

    tx = await sameChainConnectorA.connect(deployer).setSingleId(singleIDA.getAddress());
    await tx.wait();
    tx = await sameChainConnectorB.connect(deployer).setSingleId(singleIDB.getAddress());
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
    tx = await singleRouterA
      .connect(deployer)
      .setPeers(0, [currentChainId, lzEidB], sameChainsAddresses.map(addressToBytes32));
    await tx.wait();

    const lzAddresses = await Promise.all([
      layerZeroConnectorA.getAddress(),
      layerZeroConnectorB.getAddress(),
    ]);
    tx = await singleRouterA
      .connect(deployer)
      .setPeers(1, [currentChainId, lzEidB], lzAddresses.map(addressToBytes32));
    await tx.wait();

    tx = await singleRouterB
      .connect(deployer)
      .setPeers(0, [currentChainId, lzEidB], sameChainsAddresses.map(addressToBytes32));
    await tx.wait();

    tx = await singleRouterB
      .connect(deployer)
      .setPeers(1, [currentChainId, lzEidB], lzAddresses.map(addressToBytes32));
    await tx.wait();
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

  describe("When register via layerZero", () => {
    let receiver: HardhatEthersSigner;
    let admin: HardhatEthersSigner;
    let operator: HardhatEthersSigner;
    let emitter: HardhatEthersSigner;
    let user: HardhatEthersSigner;
    let registryContractB: SingleIdentifierRegistry;
    let singleIDA: SingleIdentifierID;
    let registryParams: SIDSchemaParamsStruct;
    let registerSignature;
    let sendSidWithRegistryParams;
    let sendSidWithRegistrySignature;
    let resultRegisterEmitter: ContractTransactionResponse;
    let schemaId: string;
    before(async () => {
      const fixture = await loadFixture(deployRegisterContract);
      admin = fixture.admin;
      operator = fixture.operator;
      registryContractB = fixture.registryContractB;
      singleIDA = fixture.singleIDA;

      [emitter, user, receiver] = await ethers.getSigners();

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

      const sendSidDomain: Domain = {
        name: "Rubyscore_Single_Identifier_Id",
        version: "0.0.1",
        chainId: "0",
        verifyingContract: ZeroAddress,
      };

      const sendSidTypes = {
        SendWithRegistryParams: [
          { name: "schemaId", type: "bytes32" },
          { name: "emitterAddress", type: "address" },
          { name: "registryChainId", type: "uint256" },
          { name: "user", type: "address" },
          { name: "data", type: "bytes" },
          { name: "metadata", type: "string" },
        ],
      };

      sendSidWithRegistryParams = {
        schemaId,
        emitterAddress: emitter.address,
        registryChainId: lzEidB,
        user: user.address,
        data: ethers.toUtf8Bytes("custom data"),
        metadata: "https://test.com",
      };

      sendSidWithRegistrySignature = await sign(
        sendSidDomain,
        sendSidTypes,
        sendSidWithRegistryParams as Record<string, any>,
        operator,
      );

      await singleIDA
        .connect(user)
        .registerSIDWithEmitter(
          schemaId,
          1,
          1732861209,
          emitterFee,
          lzEidB,
          emitter.address,
          ethers.toUtf8Bytes("custom data"),
          "https://test.com",
          sendSidWithRegistrySignature,
          { value: ethers.parseEther("1.0") },
        );
    });

    it("should emitter created", async () => {
      const emitterCount = await registryContractB.emitterCounter();
      expect(emitterCount).to.be.equal(BigInt(1));
      await expect(resultRegisterEmitter).to.be.not.reverted;
    });

    it("should sid registered", async () => {
      const packed = ethers.solidityPacked(["bytes32", "address"], [schemaId, user.address]);
      const sidID = ethers.keccak256(packed);

      const sid = await registryContractB.singleIdentifierData(sidID);
      const sidCount = await registryContractB.sidCounter();
      expect(sidCount).to.be.equal(BigInt(1));

      expect(sid).to.deep.equals([
        sidID,
        schemaId,
        BigInt(1732861209),
        BigInt(0),
        false,
        user.address,
        hexlify(ethers.toUtf8Bytes("custom data")),
        "https://test.com",
      ]);
    });

    it("should emitter contract balance increase", async () => {
      const packed = ethers.solidityPacked(["bytes32", "uint256"], [schemaId, lzEidB]);
      const emitterId = ethers.keccak256(packed);
      const emitterBalance = await singleIDA.emittersBalances(emitterId);
      expect(emitterBalance).to.be.equal(BigInt(emitterFee));
    });

    it("should protocol contract balance increase", async () => {
      const protocolBalance = await singleIDA.protocolBalance();
      expect(protocolBalance).to.be.equal(BigInt(protocolFee));
    });

    it("should withdraw protocol balance fee", async () => {
      const balanceBefore = await ethers.provider.getBalance(receiver.address);
      const tx = await singleIDA.connect(admin)["withdraw(address)"](receiver.address);
      await tx.wait();
      const balanceAfter = await ethers.provider.getBalance(receiver.address);
      expect(balanceAfter).to.be.equal(balanceBefore + BigInt(protocolFee));
      await expect(tx).to.emit(singleIDA, "Withdrawal").withArgs(receiver.address, BigInt(protocolFee));
    });

    it("should withdraw emitter balance fee", async () => {
      const balanceBefore = await ethers.provider.getBalance(receiver.address);
      const packed = ethers.solidityPacked(["bytes32", "uint256"], [schemaId, lzEidB]);
      const emitterId = ethers.keccak256(packed);
      const tx = await singleIDA.connect(emitter)["withdraw(bytes32,address)"](emitterId, receiver.address);
      await tx.wait();
      const balanceAfter = await ethers.provider.getBalance(receiver.address);
      expect(balanceAfter).to.be.equal(balanceBefore + BigInt(emitterFee));
      await expect(tx).to.emit(singleIDA, "Withdrawal").withArgs(receiver.address, BigInt(emitterFee));
    });
  });

  /*describe("When register via same chain", () => {
    let deployer: HardhatEthersSigner;
    let receiver: HardhatEthersSigner;
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
    let sendSidWithRegistrySignature;
    let resultRegisterEmitter: ContractTransactionResponse;
    let currentChainId;
    let schemaId: string;
    before(async () => {
      const fixture = await loadFixture(deployRegisterContract);
      deployer = fixture.deployer;
      admin = fixture.admin;
      operator = fixture.operator;
      registryContractA = fixture.registryContractA;
      registryContractB = fixture.registryContractB;
      singleIDA = fixture.singleIDA;
      singleIDB = fixture.singleIDB;

      [emitter, user, receiver] = await ethers.getSigners();

      currentChainId = await getChainId();

      const registryDomain = {
        name: "Rubyscore_Single_Identifier_Registry",
        version: "0.0.1",
        chainId: currentChainId,
        verifyingContract: await registryContractA.getAddress(),
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

      resultRegisterEmitter = await registryContractA
        .connect(emitter)
        .schemaRegistry(registryParams, registerSignature);
      schemaId = await registryContractA.schemaIds(emitter.address);

      const sendSidDomain: Domain = {
        name: "Rubyscore_Single_Identifier_Id",
        version: "0.0.1",
        chainId: "0",
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

      sendSidWithRegistryParams = {
        schemaId,
        emitterAddress: emitter.address,
        registryChainId: currentChainId,
        user: user.address,
        data: ethers.toUtf8Bytes("custom data"),
      };

      sendSidWithRegistrySignature = await sign(
        sendSidDomain,
        sendSidTypes,
        sendSidWithRegistryParams as Record<string, any>,
        operator,
      );

      await singleIDA
        .connect(user)
        .registerSIDWithEmitter(
          schemaId,
          1,
          1732861209,
          emitterFee,
          currentChainId,
          emitter.address,
          ethers.toUtf8Bytes("custom data"),
          "https://test.com",
          sendSidWithRegistrySignature,
          { value: ethers.parseEther("1.0") },
        );
    });

    it("should emitter created", async () => {
      const emitterCount = await registryContractA.emitterCounter();
      console.log("Emitter Count", emitterCount);
      expect(emitterCount).to.be.equal(BigInt(1));
      await expect(resultRegisterEmitter).to.be.not.reverted;
    });

    it("should sid registered", async () => {
      const packed = ethers.solidityPacked(["bytes32", "address"], [schemaId, user.address]);
      const sidID = ethers.keccak256(packed);

      const sid = await registryContractA.singleIdentifierData(sidID);
      const sidCount = await registryContractA.sidCounter();
      expect(sidCount).to.be.equal(BigInt(1));

      expect(sid).to.deep.equals([
        sidID,
        schemaId,
        BigInt(1732861209),
        BigInt(0),
        false,
        user.address,
        hexlify(ethers.toUtf8Bytes("custom data")),
        "https://test.com",
      ]);
    });
  });*/

  describe("When register split register emitter and register SID", () => {
    let operator: HardhatEthersSigner;
    let emitter: HardhatEthersSigner;
    let user: HardhatEthersSigner;
    let user2: HardhatEthersSigner;
    let registryContractB: SingleIdentifierRegistry;
    let singleIDA: SingleIdentifierID;
    let registryParams: SIDSchemaParamsStruct;
    let registerSignature;
    let sendSidWithRegistryParams;
    let sendSidWithRegistrySignature;
    let resultRegisterEmitter: ContractTransactionResponse;
    let currentChainId;
    let schemaId: string;

    before(async () => {
      const fixture = await loadFixture(deployRegisterContract);
      operator = fixture.operator;
      registryContractB = fixture.registryContractB;
      singleIDA = fixture.singleIDA;

      [emitter, user, user2] = await ethers.getSigners();

      currentChainId = await getChainId();

      const registryDomain = {
        name: "Rubyscore_Single_Identifier_Registry",
        version: "0.0.1",
        chainId: currentChainId,
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

      const sendSidDomain: Domain = {
        name: "Rubyscore_Single_Identifier_Id",
        version: "0.0.1",
        chainId: "0",
        verifyingContract: ZeroAddress,
      };

      const sendSidTypes = {
        SendWithRegistryParams: [
          { name: "schemaId", type: "bytes32" },
          { name: "emitterAddress", type: "address" },
          { name: "registryChainId", type: "uint256" },
          { name: "user", type: "address" },
          { name: "data", type: "bytes" },
          { name: "metadata", type: "string" },
        ],
      };

      sendSidWithRegistryParams = {
        schemaId,
        emitterAddress: emitter.address,
        registryChainId: lzEidB,
        user: user.address,
        data: ethers.toUtf8Bytes("custom data"),
        metadata: "https://test.com",
      };

      sendSidWithRegistrySignature = await sign(
        sendSidDomain,
        sendSidTypes,
        sendSidWithRegistryParams as Record<string, any>,
        operator,
      );

      await singleIDA
        .connect(user)
        .registerSIDWithEmitter(
          schemaId,
          1,
          1732861209,
          emitterFee,
          lzEidB,
          emitter.address,
          ethers.toUtf8Bytes("custom data"),
          "https://test.com",
          sendSidWithRegistrySignature,
          { value: ethers.parseEther("1.0") },
        );
    });

    it("should emitter created", async () => {
      const emitterCount = await registryContractB.emitterCounter();
      console.log("Emitter Count", emitterCount);
      expect(emitterCount).to.be.equal(BigInt(1));
      await expect(resultRegisterEmitter).to.be.not.reverted;
    });

    it("should registered sid via sample method register", async () => {
      const domain: Domain = {
        name: "Rubyscore_Single_Identifier_Id",
        version: "0.0.1",
        chainId: await getChainId(),
        verifyingContract: await singleIDA.getAddress(),
      };

      const types = {
        RegisterParams: [
          { name: "schemaId", type: "bytes32" },
          { name: "user", type: "address" },
          { name: "data", type: "bytes" },
          { name: "metadata", type: "string" },
        ],
      };

      const params = {
        schemaId,
        user: user2.address,
        data: ethers.toUtf8Bytes("custom data"),
        metadata: "https://test.com",
      };

      const signature = await sign(domain, types, params as Record<string, any>, operator);

      const packed = ethers.solidityPacked(["bytes32", "uint256"], [schemaId, lzEidB]);
      const emitterId = ethers.keccak256(packed);

      await singleIDA
        .connect(user2)
        .registerSID(emitterId, 1, ethers.toUtf8Bytes("custom data"), signature, "https://test.com", {
          value: ethers.parseEther("1.0"),
        });
    });

    it("should sid registered", async () => {
      const packed = ethers.solidityPacked(["bytes32", "address"], [schemaId, user2.address]);
      const sidID = ethers.keccak256(packed);

      const sid = await registryContractB.singleIdentifierData(sidID);
      const sidCount = await registryContractB.sidCounter();
      expect(sidCount).to.be.equal(BigInt(2));

      expect(sid).to.deep.equals([
        sidID,
        schemaId,
        BigInt(1732861209),
        BigInt(0),
        false,
        user2.address,
        hexlify(ethers.toUtf8Bytes("custom data")),
        "https://test.com",
      ]);
    });
  });

  describe("When Update SID", () => {
    let receiver: HardhatEthersSigner;
    let operator: HardhatEthersSigner;
    let emitter: HardhatEthersSigner;
    let user: HardhatEthersSigner;
    let registryContractB: SingleIdentifierRegistry;
    let singleIDA: SingleIdentifierID;
    let registryParams: SIDSchemaParamsStruct;
    let registerSignature;
    let sendSidWithRegistryParams;
    let sendSidWithRegistrySignature;
    let schemaId: string;
    before(async () => {
      const fixture = await loadFixture(deployRegisterContract);
      operator = fixture.operator;
      registryContractB = fixture.registryContractB;
      singleIDA = fixture.singleIDA;

      [emitter, user, receiver] = await ethers.getSigners();

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

      await registryContractB.connect(emitter).schemaRegistry(registryParams, registerSignature);
      schemaId = await registryContractB.schemaIds(emitter.address);

      const sendSidDomain: Domain = {
        name: "Rubyscore_Single_Identifier_Id",
        version: "0.0.1",
        chainId: "0",
        verifyingContract: ZeroAddress,
      };

      const sendSidTypes = {
        SendWithRegistryParams: [
          { name: "schemaId", type: "bytes32" },
          { name: "emitterAddress", type: "address" },
          { name: "registryChainId", type: "uint256" },
          { name: "user", type: "address" },
          { name: "data", type: "bytes" },
          { name: "metadata", type: "string" },
        ],
      };

      sendSidWithRegistryParams = {
        schemaId,
        emitterAddress: emitter.address,
        registryChainId: lzEidB,
        user: user.address,
        data: ethers.toUtf8Bytes("custom data"),
        metadata: "https://test.com",
      };

      sendSidWithRegistrySignature = await sign(
        sendSidDomain,
        sendSidTypes,
        sendSidWithRegistryParams as Record<string, any>,
        operator,
      );

      await singleIDA
        .connect(user)
        .registerSIDWithEmitter(
          schemaId,
          1,
          1732861209,
          emitterFee,
          lzEidB,
          emitter.address,
          ethers.toUtf8Bytes("custom data"),
          "https://test.com",
          sendSidWithRegistrySignature,
          { value: ethers.parseEther("1.0") },
        );
    });

    it("should success update SID", async () => {
      const packedSid = ethers.solidityPacked(["bytes32", "address"], [schemaId, user.address]);
      const sidId = ethers.keccak256(packedSid);

      const packedEmitter = ethers.solidityPacked(["bytes32", "uint256"], [schemaId, lzEidB]);
      const emitterId = ethers.keccak256(packedEmitter);

      const domain: Domain = {
        name: "Rubyscore_Single_Identifier_Id",
        version: "0.0.1",
        chainId: await getChainId(),
        verifyingContract: await singleIDA.getAddress(),
      };

      const types = {
        UpdateParams: [
          { name: "sidId", type: "bytes32" },
          { name: "expirationDate", type: "uint64" },
          { name: "data", type: "bytes" },
          { name: "metadata", type: "string" },
        ],
      };

      const params = {
        sidId,
        expirationDate: 1732861999,
        data: ethers.toUtf8Bytes("custom data"),
        metadata: "https://test-update.com",
      };

      const signature = await sign(domain, types, params as Record<string, any>, operator);

      const tx = await singleIDA
        .connect(user)
        .updateSID(emitterId, 1, sidId, params.expirationDate, params.data, params.metadata, signature, {
          value: ethers.parseEther("1.0"),
        });

      await expect(tx).to.be.not.reverted;

      const sid = await registryContractB.singleIdentifierData(sidId);

      expect(sid).to.deep.equals([
        sidId,
        schemaId,
        BigInt(params.expirationDate),
        BigInt(0),
        false,
        user.address,
        hexlify(ethers.toUtf8Bytes("custom data")),
        params.metadata,
      ]);
    });

    it("should updated schema emitter", async () => {
      const tx = await registryContractB.connect(operator).updateSchemaEmitter(schemaId, receiver);
      await expect(tx).to.be.not.reverted;

      const emitterSchemaId = await registryContractB.schemaIds(receiver);
      const schema = await registryContractB.schemas(schemaId);

      expect(schema[4]).to.be.equal(receiver.address);
      expect(emitterSchemaId).to.be.equal(schemaId);
    });

    it("should revoked SID", async () => {
      const packedSid = ethers.solidityPacked(["bytes32", "address"], [schemaId, user.address]);
      const sidId = ethers.keccak256(packedSid);

      await registryContractB.connect(receiver).revoke(sidId);
      const sid = await registryContractB.singleIdentifierData(sidId);
      expect(sid[4]).to.be.equal(true);
    });
  });
});
