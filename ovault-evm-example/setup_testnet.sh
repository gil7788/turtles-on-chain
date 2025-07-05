#!/bin/bash

set -e

echo "Deploying on adapter-only networks..."
npx hardhat lz:deploy --tags share --networks arbitrum-sepolia,base-sepolia --ci

echo "Deploying contracts via Hardhat LayerZero plugin..."
npx hardhat lz:deploy --tags asset --networks arbitrum-sepolia,base-sepolia --ci

echo "Deploying on adapter-only networks..."
npx hardhat lz:deploy --tags ovault --networks arbitrum-sepolia,base-sepolia --ci

echo "Wiring asset using LayerZero config..."
pnpm hardhat lz:oapp:wire --oapp-config layerzero.asset.config.ts

echo "Wiring share using LayerZero config..."
pnpm hardhat lz:oapp:wire --oapp-config layerzero.share.config.ts

echo "All steps completed successfully."
