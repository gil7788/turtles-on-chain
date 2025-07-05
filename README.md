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