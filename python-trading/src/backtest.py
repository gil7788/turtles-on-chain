import time
from typing import List, Dict, Tuple, Optional
from datetime import datetime, timedelta, timezone

import requests
import pandas as pd
import numpy as np


def get_buy_signal(last_twenty_prices, current_price):
    return max(last_twenty_prices) < current_price

def get_sell_signal(last_ten_prices, current_price):
    return min(last_ten_prices) > current_price

# Data from coinmarketcap
df = pd.read_csv("python-trading/eth_prices.csv")

balance_usdc = 100000
balance_eth = 0
total_usdc = balance_usdc

fee = 0.05 / 100
slippage = 0.25 / 100
cost_multiplier = 1 - fee - slippage
trades = []

in_position = False  # Track if we're currently holding ETH

for i, row in df.iterrows():
    if i < 20:  # Need 20 days of history
        continue
    # Get last 20 and last 10 prices correctly
    last_twenty = df.iloc[i - 20:i]["price"].values
    last_ten = df.iloc[i - 10:i]["price"].values

    current_price = row['price']
    current_date = row['datetime']

    signal_buy = get_buy_signal(last_twenty, current_price)
    signal_sell = get_sell_signal(last_ten, current_price)

    # Execute trades based on signals
    if signal_buy and balance_usdc > 0:
        # Buy ETH with all available USDC (whether first buy or additional buy)
        eth_bought = (balance_usdc / current_price) * cost_multiplier
        balance_eth += eth_bought
        balance_usdc = 0
        in_position = True

        trades.append({
            'date': current_date,
            'action': 'BUY',
            'price': current_price,
            'eth_amount': eth_bought,
            'usdc_amount': balance_usdc + balance_eth * current_price
        })

    elif signal_sell and balance_eth > 0:
        # Sell all ETH for USDC
        usdc_received = balance_eth * current_price * cost_multiplier
        balance_usdc += usdc_received
        balance_eth = 0
        in_position = False

        trades.append({
            'date': current_date,
            'action': 'SELL',
            'price': current_price,
            'eth_amount': 0,
            'usdc_amount': balance_usdc
        })

    # Calculate total portfolio value
    total_usdc = balance_usdc + balance_eth * current_price

    # Print progress every 30 days
    if i % 10 == 0:
        print(f"Day {i}: Total Value: ${total_usdc:,.2f} "
              f"| ETH: {balance_eth:.4f} | USDC: ${balance_usdc:,.2f}")




