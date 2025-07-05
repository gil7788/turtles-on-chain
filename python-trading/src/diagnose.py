#!/usr/bin/env python3

from web3 import Web3

# Configuration
RPC_URL = "https://coston2-api.flare.network/ext/C/rpc"
SWAP_CONTRACT_ADDRESS = "0xA13d4a67745D4Ed129AF590c495897eE2C7F8Cfc"
TESTNET_USDT = "0xC1A5B41512496B80903D1f32d6dEa3a73212E71F"

# Contract ABIs
SWAP_ABI = [
    {
        "inputs": [],
        "name": "main",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "getBalances",
        "outputs": [
            {"internalType": "uint256", "name": "usdtBal", "type": "uint256"},
            {"internalType": "uint256", "name": "wethBal", "type": "uint256"}
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "usdt",
        "outputs": [
            {"internalType": "address", "name": "", "type": "address"}],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "weth",
        "outputs": [
            {"internalType": "address", "name": "", "type": "address"}],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "dex",
        "outputs": [
            {"internalType": "address", "name": "", "type": "address"}],
        "stateMutability": "view",
        "type": "function"
    }
]

TOKEN_ABI = [
    {
        "inputs": [
            {"internalType": "address", "name": "account", "type": "address"}],
        "name": "balanceOf",
        "outputs": [
            {"internalType": "uint256", "name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "symbol",
        "outputs": [{"internalType": "string", "name": "", "type": "string"}],
        "stateMutability": "view",
        "type": "function"
    }
]


def diagnose_failure():
    """Diagnose exactly why the contract calls are failing"""
    w3 = Web3(Web3.HTTPProvider(RPC_URL))

    print("🔍 DETAILED FAILURE DIAGNOSTIC")
    print("=" * 50)
    print(f"Swap Contract: {SWAP_CONTRACT_ADDRESS}")
    print(f"Expected USDT: {TESTNET_USDT}")

    try:
        # 1. Check if swap contract exists
        swap_code = w3.eth.get_code(SWAP_CONTRACT_ADDRESS)
        print(
            f"\n📍 Swap Contract: {'✅ Exists' if len(swap_code) > 0 else '❌ Missing'} ({len(swap_code)} bytes)")

        if len(swap_code) == 0:
            print("🚨 CRITICAL: Swap contract doesn't exist at that address!")
            return

        # 2. Create contract instance
        swap_contract = w3.eth.contract(address=SWAP_CONTRACT_ADDRESS,
                                        abi=SWAP_ABI)

        # 3. Check what USDT address the contract is actually using
        print(f"\n🔍 CHECKING CONTRACT CONFIGURATION:")
        try:
            actual_usdt = swap_contract.functions.usdt().call()
            actual_weth = swap_contract.functions.weth().call()
            actual_dex = swap_contract.functions.dex().call()

            print(f"   Contract's USDT: {actual_usdt}")
            print(f"   Contract's WETH: {actual_weth}")
            print(f"   Contract's DEX:  {actual_dex}")
            print(f"   Expected USDT:   {TESTNET_USDT}")

            if actual_usdt.lower() != TESTNET_USDT.lower():
                print(
                    f"🚨 MISMATCH: Contract uses {actual_usdt}, bot expects {TESTNET_USDT}")
                print(f"💡 You need to update bot to use: {actual_usdt}")
                return actual_usdt
            else:
                print(f"✅ USDT addresses match!")

        except Exception as config_error:
            print(f"❌ Cannot read contract config: {config_error}")
            return None

        # 4. Test individual function calls
        print(f"\n🧪 TESTING INDIVIDUAL FUNCTIONS:")

        # Test getBalances()
        try:
            usdt_bal, weth_bal = swap_contract.functions.getBalances().call()
            print(f"   ✅ getBalances(): USDT={usdt_bal}, WETH={weth_bal}")
        except Exception as balance_error:
            print(f"   ❌ getBalances() failed: {balance_error}")

        # 5. Check token contracts
        print(f"\n💰 CHECKING TOKEN CONTRACTS:")

        for name, addr in [("USDT", actual_usdt), ("WETH", actual_weth)]:
            try:
                token_code = w3.eth.get_code(addr)
                if len(token_code) == 0:
                    print(f"   ❌ {name} ({addr}): No contract code!")
                    continue

                print(
                    f"   ✅ {name} ({addr}): Contract exists ({len(token_code)} bytes)")

                # Try to call token functions
                token_contract = w3.eth.contract(address=addr, abi=TOKEN_ABI)

                try:
                    symbol = token_contract.functions.symbol().call()
                    balance = token_contract.functions.balanceOf(
                        SWAP_CONTRACT_ADDRESS).call()
                    print(
                        f"      Symbol: {symbol}, Swap contract balance: {balance}")
                except Exception as token_error:
                    print(
                        f"      ❌ Token function calls failed: {token_error}")

            except Exception as e:
                print(f"   ❌ {name} check failed: {e}")

        # 6. Check DEX contract
        print(f"\n🔄 CHECKING DEX CONTRACT:")
        try:
            dex_code = w3.eth.get_code(actual_dex)
            if len(dex_code) == 0:
                print(f"   ❌ DEX ({actual_dex}): No contract code!")
            else:
                print(
                    f"   ✅ DEX ({actual_dex}): Contract exists ({len(dex_code)} bytes)")
        except Exception as dex_error:
            print(f"   ❌ DEX check failed: {dex_error}")

        # 7. Try to simulate main() call
        print(f"\n🚀 SIMULATING main() CALL:")
        try:
            # This should fail and tell us why
            result = swap_contract.functions.main().call()
            print(f"   ✅ main() simulation succeeded: {result}")
        except Exception as main_error:
            print(f"   ❌ main() simulation failed: {main_error}")

            error_str = str(main_error).lower()
            if "no usdt to swap" in error_str:
                print(f"   💡 Issue: Contract has no USDT balance")
            elif "exchange rate not set" in error_str:
                print(f"   💡 Issue: DEX exchange rate not configured")
            elif "insufficient balance" in error_str:
                print(f"   💡 Issue: Token balance or allowance problem")
            else:
                print(f"   💡 Unknown error - check contract logic")

        print(f"\n🎯 SUMMARY:")
        print("=" * 15)
        print(
            "If you see 'MISMATCH' above, update your bot with the correct USDT address.")
        print(
            "If main() fails with 'No USDT to swap', the contract needs USDT funding.")
        print(
            "If token calls fail, the token contracts might not be ERC20 compatible.")

    except Exception as e:
        print(f"❌ Diagnostic failed: {e}")


if __name__ == "__main__":
    diagnose_failure()