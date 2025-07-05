#!/usr/bin/env python3

import time
from datetime import datetime
from web3 import Web3
from typing import Optional, Tuple

# Configuration - UPDATED FOR NEW CONTRACT
RPC_URL = "https://coston2-api.flare.network/ext/C/rpc"
CONTRACT_ADDRESS = "0x862E3acDE54f01a4540C4505a4E199214Ff6cD49"  # ✅ Your new contract
PRIVATE_KEY = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
INTERVAL_SECONDS = 4

# Updated ABI for the new contract (without timing constraints)
CONTRACT_ABI = [
    {
        "inputs": [],
        "name": "main",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "getLatestPrice",
        "outputs": [
            {"internalType": "uint256", "name": "price", "type": "uint256"},
            {"internalType": "uint256", "name": "timestamp",
             "type": "uint256"},
            {"internalType": "uint256", "name": "decimals", "type": "uint256"}
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "getPosition",
        "outputs": [
            {"internalType": "uint256", "name": "ethAmount",
             "type": "uint256"},
            {"internalType": "bool", "name": "hasPos", "type": "bool"}
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "getCurrentPrice",
        "outputs": [
            {"internalType": "uint256", "name": "", "type": "uint256"},
            {"internalType": "uint256", "name": "", "type": "uint256"},
            {"internalType": "uint256", "name": "", "type": "uint256"}
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "lastUpdate",
        "outputs": [
            {"internalType": "uint256", "name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "getPriceCount",
        "outputs": [
            {"internalType": "uint256", "name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "getTimeSinceLastUpdate",
        "outputs": [
            {"internalType": "uint256", "name": "", "type": "uint256"}],
        "stateMutability": "view",
        "type": "function"
    }
]


class UpdatedTurtleBot:
    def __init__(
        self,
        rpc_url: str,
        contract_address: str,
        private_key: str,
        interval: int
    ):
        self.w3 = Web3(Web3.HTTPProvider(rpc_url))
        self.contract_address = Web3.to_checksum_address(contract_address)
        self.account = self.w3.eth.account.from_key(private_key)
        self.interval = interval
        self.call_count = 0

        self.contract = self.w3.eth.contract(
            address=self.contract_address,
            abi=CONTRACT_ABI
        )

        print("🐢 UPDATED Turtle Trading Bot")
        print(f"📍 Contract: {self.contract_address}")
        print(f"👤 Account: {self.account.address}")
        print(f"⏱️  Interval: {self.interval} seconds")
        print(f"🔗 Network: Flare Coston2")
        print("─" * 50)

    def test_contract_connection(self) -> bool:
        """Test if contract is deployed and accessible"""
        try:
            # Check if contract has code
            code = self.w3.eth.get_code(self.contract_address)
            if code == b'':
                print("❌ No contract code found at address")
                return False

            print(f"✅ Contract code found ({len(code)} bytes)")

            # Test a simple view function
            try:
                price_count = self.contract.functions.getPriceCount().call()
                print(f"✅ Contract responsive, price count: {price_count}")
                return True
            except Exception as view_error:
                print(f"❌ Contract view call failed: {view_error}")
                return False

        except Exception as e:
            print(f"❌ Contract connection test failed: {e}")
            return False

    def get_current_status(self) -> Tuple[
        Optional[float], Optional[float], Optional[bool]]:
        """Get current price and position with better error handling"""
        try:
            # Try to get latest price
            try:
                price, timestamp, decimals = self.contract.functions.getLatestPrice().call()
                price_usd = price / (10 ** decimals) if price > 0 else None
            except Exception as price_error:
                print(f"   getLatestPrice failed: {price_error}")
                price_usd = None

            # Try to get position
            try:
                eth_amount, has_position = self.contract.functions.getPosition().call()
                eth_balance = self.w3.from_wei(eth_amount, 'ether')
            except Exception as position_error:
                print(f"   getPosition failed: {position_error}")
                eth_balance, has_position = None, None

            return price_usd, eth_balance, has_position

        except Exception as e:
            print(f"❌ Status error: {e}")
            return None, None, None

    def test_oracle_access(self) -> bool:
        """Test if oracle is accessible"""
        try:
            price, timestamp, decimals = self.contract.functions.getCurrentPrice().call()
            price_usd = price / (10 ** decimals)
            print(
                f"✅ Oracle working: ${price_usd:.2f} (timestamp: {timestamp})")
            return True
        except Exception as e:
            print(f"❌ Oracle test failed: {e}")
            if "testETH" in str(e):
                print(
                    "💡 Possible issue: 'testETH' symbol might not exist on Coston2")
            return False

    def call_main_function(self) -> bool:
        """Execute main() function"""
        try:
            # Build transaction
            nonce = self.w3.eth.get_transaction_count(self.account.address)

            transaction = self.contract.functions.main().build_transaction({
                'from': self.account.address,
                'nonce': nonce,
                'gas': 500000,
                'gasPrice': self.w3.to_wei('25', 'gwei'),
            })

            # Sign and send
            signed_txn = self.w3.eth.account.sign_transaction(
                transaction,
                private_key=self.account.key
            )

            tx_hash = self.w3.eth.send_raw_transaction(
                signed_txn.raw_transaction)
            tx_hash_hex = tx_hash.hex()

            print(f"📤 TX Hash: {tx_hash_hex}")

            # Wait for confirmation
            receipt = self.w3.eth.wait_for_transaction_receipt(tx_hash,
                                                               timeout=30)

            if receipt.status == 1:
                print(f"✅ Confirmed in block: {receipt.blockNumber}")
                print(f"⛽ Gas used: {receipt.gasUsed:,}")
                return True
            else:
                print(f"❌ Transaction failed in block {receipt.blockNumber}")

                # Try to get revert reason
                try:
                    self.w3.eth.call(transaction, receipt.blockNumber)
                except Exception as revert_error:
                    print(f"   Revert reason: {revert_error}")

                return False

        except Exception as e:
            print(f"❌ Call failed: {e}")
            return False

    def run_diagnostic(self):
        """Run diagnostic before starting main loop"""
        print("\n🔍 Running pre-flight diagnostic...")

        # Test contract connection
        if not self.test_contract_connection():
            print("🚨 Contract connection failed - stopping")
            return False

        # Test oracle access
        if not self.test_oracle_access():
            print("🚨 Oracle access failed - this will cause main() to revert")
            return False

        # Test getting contract state
        last_update_time = None
        try:
            last_update_time = self.contract.functions.lastUpdate().call()
            print(f"✅ Last update time: {last_update_time}")
        except Exception as e:
            print(f"⚠️  Could not get lastUpdate: {e}")

        print("✅ Diagnostic complete - ready to start trading")
        return True

    def run(self):
        """Main bot loop"""
        print("🚀 Starting updated turtle bot...\n")

        # Run diagnostic first
        if not self.run_diagnostic():
            print("❌ Diagnostic failed - please check contract deployment")
            return

        try:
            while True:
                self.call_count += 1
                timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

                print(f"\n[{timestamp}] Call #{self.call_count}")

                # Get current status before call
                price_before, eth_before, pos_before = self.get_current_status()

                if price_before is not None:
                    position_str = f"ETH ({eth_before:.4f})" if pos_before else "USDT"
                    print(
                        f"💰 Price: ${price_before:.2f} | Position: {position_str}")

                # Execute main function
                print("🔄 Calling main()...")
                success = self.call_main_function()

                if success:
                    # Check for position changes
                    price_after, eth_after, pos_after = self.get_current_status()

                    if pos_after != pos_before:
                        action = "🟢 BOUGHT ETH" if pos_after else "🔴 SOLD ETH"
                        print(f"🔄 TRADE EXECUTED! {action}")
                        if pos_after and eth_after:
                            print(f"   📈 New ETH position: {eth_after:.4f}")
                        elif not pos_after:
                            print(f"   💰 Back to USDT")

                # Wait for next interval
                print(f"⏳ Waiting {self.interval} seconds...")
                time.sleep(self.interval)

        except KeyboardInterrupt:
            print("\n🛑 Bot stopped by user")
        except Exception as e:
            print(f"\n💥 Fatal error: {e}")


def main():
    """Initialize and run the updated turtle bot"""
    print("🎯 Using new contract with no timing constraints!")
    print(f"📍 Contract: {CONTRACT_ADDRESS}")

    bot = UpdatedTurtleBot(
        rpc_url=RPC_URL,
        contract_address=CONTRACT_ADDRESS,
        private_key=PRIVATE_KEY,
        interval=INTERVAL_SECONDS
    )

    bot.run()


if __name__ == "__main__":
    main()