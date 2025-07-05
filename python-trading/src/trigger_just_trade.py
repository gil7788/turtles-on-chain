#!/usr/bin/env python3

import time
from datetime import datetime
from web3 import Web3
from typing import Tuple, Optional

# Configuration - UPDATE THESE AFTER DEPLOYMENT
RPC_URL = "https://coston2-api.flare.network/ext/C/rpc"
SWAP_CONTRACT_ADDRESS = "0xA13d4a67745D4Ed129AF590c495897eE2C7F8Cfc"  # Update with deployed address
USDT_TOKEN_ADDRESS = "0xC1A5B41512496B80903D1f32d6dEa3a73212E71F"  # Update with deployed USDT address
PRIVATE_KEY = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
INTERVAL_SECONDS = 10

# Contract ABI
SWAP_CONTRACT_ABI = [
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
        "name": "getCurrentETHPrice",
        "outputs": [
            {"internalType": "uint256", "name": "price", "type": "uint256"},
            {"internalType": "uint256", "name": "decimals", "type": "uint256"}
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "getLastSwap",
        "outputs": [
            {"internalType": "uint256", "name": "price", "type": "uint256"},
            {"internalType": "uint256", "name": "amount", "type": "uint256"},
            {"internalType": "uint256", "name": "count", "type": "uint256"}
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [{"internalType": "uint256", "name": "usdtAmount",
                    "type": "uint256"}],
        "name": "getSwapQuote",
        "outputs": [{"internalType": "uint256", "name": "ethAmount",
                     "type": "uint256"}],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {"internalType": "uint256", "name": "amount", "type": "uint256"}],
        "name": "fundWithUSDT",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    }
]

# Token ABI (for funding)
TOKEN_ABI = [
    {
        "inputs": [
            {"internalType": "address", "name": "spender", "type": "address"},
            {"internalType": "uint256", "name": "amount", "type": "uint256"}],
        "name": "approve",
        "outputs": [{"internalType": "bool", "name": "", "type": "bool"}],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {"internalType": "address", "name": "account", "type": "address"}],
        "name": "balanceOf",
        "outputs": [
            {"internalType": "uint256", "name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function"
    }
]


class SimpleSwapBot:
    def __init__(
        self,
        rpc_url: str,
        swap_contract_address: str,
        usdt_address: str,
        private_key: str,
        interval: int
    ):
        self.w3 = Web3(Web3.HTTPProvider(rpc_url))
        self.swap_contract_address = Web3.to_checksum_address(
            swap_contract_address)
        self.usdt_address = Web3.to_checksum_address(usdt_address)
        self.account = self.w3.eth.account.from_key(private_key)
        self.interval = interval
        self.swap_count = 0

        self.swap_contract = self.w3.eth.contract(
            address=self.swap_contract_address,
            abi=SWAP_CONTRACT_ABI
        )

        self.usdt_contract = self.w3.eth.contract(
            address=self.usdt_address,
            abi=TOKEN_ABI
        )

        print("🔄 Simple Swap Bot")
        print(f"📍 Swap Contract: {self.swap_contract_address}")
        print(f"💵 USDT Token: {self.usdt_address}")
        print(f"👤 Account: {self.account.address}")
        print(f"⏱️  Interval: {self.interval} seconds")
        print("─" * 50)

    def get_contract_status(self) -> Tuple[
        Optional[float], Optional[float], Optional[float]]:
        """Get current contract status"""
        try:
            # Get balances
            usdt_bal, weth_bal = self.swap_contract.functions.getBalances().call()
            usdt_formatted = usdt_bal / (10 ** 6)  # USDT has 6 decimals
            weth_formatted = weth_bal / (10 ** 18)  # WETH has 18 decimals

            # Get ETH price
            price, decimals = self.swap_contract.functions.getCurrentETHPrice().call()
            eth_price = price / (10 ** decimals)

            return usdt_formatted, weth_formatted, eth_price

        except Exception as e:
            print(f"❌ Status error: {e}")
            return None, None, None

    def get_swap_quote(self, usdt_amount: int) -> Optional[float]:
        """Get quote for swapping USDT amount"""
        try:
            eth_amount = self.swap_contract.functions.getSwapQuote(
                usdt_amount).call()
            return eth_amount / (10 ** 18)  # Convert to ETH
        except Exception as e:
            print(f"❌ Quote error: {e}")
            return None

    def fund_contract_if_needed(self, min_usdt: float = 50.0):
        """Fund contract with USDT if balance is low"""
        try:
            usdt_bal, _, _ = self.get_contract_status()

            if usdt_bal and usdt_bal < min_usdt:
                print(f"💰 Contract USDT low ({usdt_bal:.2f}), funding...")

                # Check our USDT balance
                our_balance = self.usdt_contract.functions.balanceOf(
                    self.account.address).call()
                our_balance_formatted = our_balance / (10 ** 6)

                if our_balance_formatted < 100:
                    print(
                        f"❌ Insufficient USDT in wallet: {our_balance_formatted:.2f}")
                    return False

                # Fund with 500 USDT
                fund_amount = 500 * 10 ** 6  # 500 USDT

                # Approve first
                approve_tx = self.usdt_contract.functions.approve(
                    self.swap_contract_address,
                    fund_amount
                ).build_transaction({
                    'from': self.account.address,
                    'nonce': self.w3.eth.get_transaction_count(
                        self.account.address),
                    'gas': 100000,
                    'gasPrice': self.w3.to_wei('25', 'gwei'),
                })

                signed_approve = self.w3.eth.account.sign_transaction(
                    approve_tx, private_key=self.account.key)
                approve_hash = self.w3.eth.send_raw_transaction(
                    signed_approve.raw_transaction)
                self.w3.eth.wait_for_transaction_receipt(approve_hash)

                # Fund contract
                fund_tx = self.swap_contract.functions.fundWithUSDT(
                    fund_amount).build_transaction({
                    'from': self.account.address,
                    'nonce': self.w3.eth.get_transaction_count(
                        self.account.address),
                    'gas': 200000,
                    'gasPrice': self.w3.to_wei('25', 'gwei'),
                })

                signed_fund = self.w3.eth.account.sign_transaction(fund_tx,
                                                                   private_key=self.account.key)
                fund_hash = self.w3.eth.send_raw_transaction(
                    signed_fund.raw_transaction)
                receipt = self.w3.eth.wait_for_transaction_receipt(fund_hash)

                if receipt.status == 1:
                    print(f"✅ Funded contract with 500 USDT")
                    return True
                else:
                    print(f"❌ Funding failed")
                    return False

        except Exception as e:
            print(f"❌ Funding error: {e}")
            return False

    def execute_swap(self) -> bool:
        """Execute the main swap function"""
        try:
            nonce = self.w3.eth.get_transaction_count(self.account.address)

            transaction = self.swap_contract.functions.main().build_transaction(
                {
                    'from': self.account.address,
                    'nonce': nonce,
                    'gas': 300000,  # Lower gas limit for simple swap
                    'gasPrice': self.w3.to_wei('25', 'gwei'),
                })

            signed_txn = self.w3.eth.account.sign_transaction(
                transaction,
                private_key=self.account.key
            )

            tx_hash = self.w3.eth.send_raw_transaction(
                signed_txn.raw_transaction)
            tx_hash_hex = tx_hash.hex()

            print(f"📤 TX Hash: {tx_hash_hex}")

            receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash,
                                                               timeout=30)

            if receipt.status == 1:
                print(
                    f"✅ Swap successful! Block: {receipt.blockNumber}, Gas: {receipt.gasUsed:,}")
                return True
            else:
                print(f"❌ Swap failed")
                return False

        except Exception as e:
            print(f"❌ Swap execution failed: {e}")
            return False

    def run(self):
        """Main bot loop"""
        if not SWAP_CONTRACT_ADDRESS or not USDT_TOKEN_ADDRESS:
            print(
                "❌ Please update CONTRACT_ADDRESS and USDT_ADDRESS in the script")
            return

        print("🚀 Starting simple swap bot...\n")

        try:
            while True:
                self.swap_count += 1
                timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

                print(f"\n[{timestamp}] Swap #{self.swap_count}")

                # Get current status
                usdt_bal, weth_bal, eth_price = self.get_contract_status()

                if usdt_bal is not None:
                    print(f"💰 ETH Price: ${eth_price:.2f}")
                    print(
                        f"📊 Contract: {usdt_bal:.2f} USDT, {weth_bal:.6f} WETH")

                    # Get quote for current balance
                    if usdt_bal > 0:
                        quote = self.get_swap_quote(int(usdt_bal * 10 ** 6))
                        if quote:
                            print(
                                f"🔄 Quote: {usdt_bal:.2f} USDT → {quote:.6f} WETH")

                # Fund if needed
                self.fund_contract_if_needed()

                # Execute swap
                print("🔄 Executing swap...")
                success = self.execute_swap()

                if success:
                    # Show results
                    new_usdt_bal, new_weth_bal, _ = self.get_contract_status()
                    if new_usdt_bal is not None:
                        usdt_swapped = (usdt_bal or 0) - new_usdt_bal
                        weth_received = new_weth_bal - (weth_bal or 0)
                        print(
                            f"🎯 Swapped {usdt_swapped:.2f} USDT → {weth_received:.6f} WETH")

                # Wait for next interval
                print(f"⏳ Waiting {self.interval} seconds...")
                time.sleep(self.interval)

        except KeyboardInterrupt:
            print("\n🛑 Bot stopped by user")
        except Exception as e:
            print(f"\n💥 Fatal error: {e}")


def main():
    if not SWAP_CONTRACT_ADDRESS:
        print("⚠️  Please deploy the contract first and update the addresses:")
        print("   1. Run: forge script script/Deploy.s.sol --broadcast")
        print("   2. Update SWAP_CONTRACT_ADDRESS in this script")
        print("   3. Update USDT_TOKEN_ADDRESS in this script")
        return

    bot = SimpleSwapBot(
        rpc_url=RPC_URL,
        swap_contract_address=SWAP_CONTRACT_ADDRESS,
        usdt_address=USDT_TOKEN_ADDRESS,
        private_key=PRIVATE_KEY,
        interval=INTERVAL_SECONDS
    )

    bot.run()


if __name__ == "__main__":
    main()