# include .env
-include .env

.PHONY: help deploy-marketplace


help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  deploy-marketplace		Deploy Marketplace contract"

deploy-marketplace:
	@echo "Deploying Marketplace contract"
	@forge script script/Marketplace.s.sol:MarketplaceScript --rpc-url ${JSON_RPC_URL} --private-key ${PRIVATE_KEY} --broadcast -vvvv


# create  sender,nonce => contract_address


# create2  sender, salt, init_code => contract_address