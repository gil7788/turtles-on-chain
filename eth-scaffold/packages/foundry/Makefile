.PHONY: deploy-and-generate-abis

deploy-and-generate-abis:
	forge script script/DeployFlare.s.sol:Deploy --rpc-url coston2 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
	forge build
