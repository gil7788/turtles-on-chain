#!/bin/bash

set -e

NETWORKS="hedera-mainnet,flare-mainnet"

echo "Deploying contracts via Hardhat LayerZero plugin..."
npx hardhat lz:deploy --tags asset --networks $NETWORKS --ci

o "Deploying contracts via Hardhat LayerZero plugin..."
npx hardhat lz:deploy --tags share --networks $NETWORKS --ci

o "Deploying contracts via Hardhat LayerZero plugin..."
npx hardhat lz:deploy --tags ovault --networks $NETWORKS --ci


echo "Wiring asset using LayerZero config..."
pnpm hardhat lz:oapp:wire --oapp-config layerzero.mainnet.asset.config.ts

echo "Wiring share using LayerZero config..."
pnpm hardhat lz:oapp:wire --oapp-config layerzero.mainnet.share.config.ts

echo "All steps completed successfully."
