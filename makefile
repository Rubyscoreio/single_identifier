-include .env

build:
	forge build

test:
	forge test --via-ir

simulateDeploySingleId:
	@echo "Simulating deployment to $(chain)"
	forge script scripts/DeploySingleIdentifierIdScript.s.sol:DeploySingleIdentifierIdScript \
	$(chain) \
	--sig "run(string)" \
	--via-ir \
	-vvvv \

simulateDeploySingleIdMultichain:
	@echo "Simulating deployment to $(chains)"
	forge script scripts/DeploySingleIdentifierIdScript.s.sol:DeploySingleIdentifierIdScript \
	$(chains) \
	--sig "runMultichain(string[])" \
	--via-ir \
	-vvvv \

deploySingleId:
	@echo "Deploying to $(chain)"
	@echo "Broadcast and verify are commented for security reasons, dont forget to uncomment them."
	forge script scripts/DeploySingleIdentifierIdScript.s.sol:DeploySingleIdentifierIdScript \
	$(chain) \
	--sig "run(string)" \
	--via-ir \
	-vvvv \
	--etherscan-api-key ${ETHERSCAN_API_KEY} \
#	--broadcast \
#	--verify \

extendProtocolWithChain:
	forge script scripts/DeployProtocol.s.sol:DeployProtocolScript \
	$(chain) \
	--sig "run(string)" \
	--via-ir \
	-vvvv \
	--etherscan-api-key ${ETHERSCAN_API_KEY} \
#	--broadcast \
#	--verify \

configureL0Connectors:
	forge script scripts/ConfigureL0Connectors.s.sol:ConfigureL0ConnectorsScript \
	$(chains) \
	--sig "runMultichain(string[])" \
	--via-ir \
	-vvvv \
#	--broadcast \

deployHyperlaneConnector:
	forge script scripts/DeployHyperlaneConnectorScript.s.sol:DeployHyperlaneConnectorScript \
	$(chain) \
	--sig "run(string)" \
	--via-ir \
	-vvvv \
	--etherscan-api-key ${ETHERSCAN_API_KEY} \
#	--broadcast \
#	--verify \

setUpHyperlaneConnectors:
	forge script scripts/SetUpHyperlaneConnectors.s.sol:SetUpHyperlaneConnectors \
	$(chains) \
	--sig "runMultichain(string[])" \
	--via-ir \
	-vvvv \
#	--broadcast \

checkHealth:
	forge script scripts/CheckProtocolCrossChainHealth.s.sol:CheckProtocolCrossChainHealthScript \
	--via-ir \
