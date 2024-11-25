# RubyScore Single Identifier Contracts

This repo will have a code of RubyScore Identifier Contracts.

## Setting project

### Install dependencies

```sh
npm install
```

---

## config

```
DEPLOYER_KEY = ""
INFURA_KEY = ""
ETHERSCAN_API_KEY = ""
POLYGONSCAN_API_KEY = ""
BSCSCAN_API_KEY = ""
```

### Setup config

Create and fill _.env_ file.

```sh
cp .env.example .env
```

---

### Compile contracts

```sh
npm run compile
```

---

### Migrate contracts

```sh
npm run migrate:<NETWORK> (mainnet, goerli, polygon, polygonMumbai, bsc, bscTestnet)
```

---

### Verify contracts

To verify the contract, you must specify the names of the contracts for verification through "," WITHOUT SPACES

```sh
npm run verify:<NETWORK> <NAME_CONTRACT_FIRST>,<NAME_CONTRACT_SECOND>
```

---

### Tests contracts

```sh
# Run Tests
npm run test

# Run test watcher
npm run test:watch
```

---

### Node hardhat(Localfork)

NOTE:// To work with a node or fork, you need to run the node in a separate console

```sh
# Run Node hardhat (For run localfork setting config { FORK_ENABLED: true, FORK_PROVIDER_URI: "https://...."})
npm run node

# Run test watcher
npm run test:node
```

---

### Coverage

```sh
npm run coverage
```

---

### Gas reporter

You can start the gas reporter either through a separate gas reporter script through "**npm run**" or by changing the variable in the config "**GAS_REPORTER.ENABLED**" when running tests

```sh
# Native gas reporter
npm run gas-reporter

# GAS_REPORTER.ENABLED = true
npm run test
```

---

### Clean

```sh
# Rm artifacts, cache, typechain-types
npm run clean

# Rm deployments for choose network
npm run clean:deployments <NETWORK>
```

---

### Linter

```sh
# Checking code style for .ts, .sol
npm run lint

# Run fix code style for .ts, .sol
npm run lint:fix

# Checking code style for .ts
npm run lint:ts

# Run fix code style for .ts
npm run lint:ts:fix

# Checking code style for .sol
npm run lint:sol

# Run fix code style for .sol
npm run lint:sol:fix
```

---

## Auto audit with slither

To run the analyzer, you must first install it globally

To audit all contracts, use the command :

```sh
slither .
```

To exclude warnings in subsequent audits, use :

```sh
slither . --triage
```

---
