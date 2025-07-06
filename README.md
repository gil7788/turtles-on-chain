# Turtles On Chain!!

## Setup Ovalut
### Installation
cd to package:
```bash
cd <repo_path>/ovault/ovault-evm
```

```bash
npm link
```

```bash
npm ls -g --depth=0
```

Expected output:
```bash
@layerzerolabs/ovault-evm@0.0.1 -> ./../../../../home/user/Projects/hackatons/eth-global-cannes/ovault/ovault-evm
```

```bash
cd <repo>/ovault/ovault-evm-example
```

```bash
npm link @layerzerolabs/ovault-evm
```

### Deployment
```bash
npx hardhat lz:deploy
```

Wiring Transaction
```bash
pnpm hardhat lz:oapp:wire --oapp-config layerzero.asset.config.ts
```

```bash
npx hardhat etherscan-verify --api-key UITCH99PJ8WH1T5K1Y3ZWQH9PZZ88M4R9P --api-url https://api-sepolia.arbiscan.io/ --contract-name MyOVaultComposer --network arbitrum-sepolia
```

Testnet
```bash
forge script script/SendScript.s.sol --rpc-url https://base-sepolia.drpc.org --private-key eec5114d22861479be10c9db7850f75473bbcde37076163fbf94222a3864ee74 --sig "exec(address,string,uint256,uint256,uint128,uint128)" 0x33457F5E32380AEFeac8A8eBF887E4608Eb6c3ca "arb-sep" 1ether 0 0 0 0.000025ether --broadcast
```

Mainnet
```bash
forge script script/SendScript.s.sol:SendScript --rpc-url https://rpc.au.cc/flare --private-key eec5114d22861479be10c9db7850f75473bbcde37076163fbf94222a3864ee74 --sig "exec(address,string,uint256,uint256,uint128,uint128)" 0xA509024fdF63959CC4126Fb6E6E59929315970c1 "flare-mainnet" 1ether 0 0 0 0.000025ether --broadcast
```