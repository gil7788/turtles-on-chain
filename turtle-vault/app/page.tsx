"use client"

import { useState } from "react"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { ArrowDown, ChevronDown } from "lucide-react"

export default function TurtlesOnChain() {
  const [amount, setAmount] = useState("")
  const [selectedToken, setSelectedToken] = useState<"asset" | "share">("asset")

  // Mock data for vault
  const vaultData = {
    assetToken: {
      symbol: "USDC",
      name: "USD Coin",
      balance: "1,234.56",
    },
    shareToken: {
      symbol: "tUSDC",
      name: "Turtle USDC Vault",
      balance: "987.34",
    },
    vaultName: "Turtle USDC Yield Vault",
  }

  const TurtleIcon = ({
    className = "w-16 h-16",
    emoji = "🐢",
    opacity = "opacity-20",
  }: {
    className?: string
    emoji?: string
    opacity?: string
  }) => <div className={`${className} ${opacity} text-4xl flex items-center justify-center animate-pulse`}>{emoji}</div>

  const currentToken = selectedToken === "asset" ? vaultData.assetToken : vaultData.shareToken
  const receiveToken = selectedToken === "asset" ? vaultData.shareToken : vaultData.assetToken

  return (
    <div className="min-h-screen bg-gradient-to-br from-green-50 via-emerald-50 to-teal-50 relative overflow-hidden">
      {/* Floating Turtles Background - Bigger and More Variety */}
      <div className="absolute inset-0 pointer-events-none">
        <TurtleIcon className="absolute top-16 left-16 w-20 h-20" emoji="🐢" opacity="opacity-15" />
        <TurtleIcon className="absolute top-24 right-24 w-24 h-24" emoji="🟢" opacity="opacity-10" />
        <TurtleIcon className="absolute top-48 left-48 w-18 h-18" emoji="🐢" opacity="opacity-20" />
        <TurtleIcon className="absolute top-72 right-72 w-22 h-22" emoji="🟫" opacity="opacity-15" />
        <TurtleIcon className="absolute bottom-24 right-16 w-20 h-20" emoji="🐢" opacity="opacity-18" />
        <TurtleIcon className="absolute bottom-48 left-24 w-24 h-24" emoji="🟢" opacity="opacity-12" />
        <TurtleIcon className="absolute bottom-72 right-48 w-16 h-16" emoji="🟫" opacity="opacity-25" />
        <TurtleIcon className="absolute top-96 right-96 w-20 h-20" emoji="🐢" opacity="opacity-15" />
        <TurtleIcon className="absolute bottom-96 left-96 w-28 h-28" emoji="🟢" opacity="opacity-8" />
        <TurtleIcon className="absolute top-32 left-1/2 w-18 h-18" emoji="🟫" opacity="opacity-22" />
        <TurtleIcon className="absolute bottom-32 right-1/2 w-22 h-22" emoji="🐢" opacity="opacity-16" />
        <TurtleIcon className="absolute top-64 right-1/3 w-20 h-20" emoji="🟢" opacity="opacity-14" />
        <TurtleIcon className="absolute bottom-64 left-1/3 w-24 h-24" emoji="🟫" opacity="opacity-10" />
      </div>

      {/* Header */}
      <header className="relative z-10 flex items-center justify-between p-6 bg-white/80 backdrop-blur-sm border-b border-green-100">
        <div className="flex items-center space-x-2">
          <div className="text-2xl">🐢</div>
          <span className="text-xl font-bold text-green-800">Turtles on Chain</span>
        </div>
        <div className="flex items-center">
          <Button className="bg-green-600 hover:bg-green-700 text-white">Connect</Button>
        </div>
      </header>

      {/* Main Content */}
      <main className="relative z-10 flex flex-col items-center justify-center min-h-[calc(100vh-80px)] p-6">
        <div className="text-center mb-8">
          <h1 className="text-5xl font-bold text-green-800 mb-4">
            Vault anytime,
            <br />
            anywhere.
          </h1>
          <div className="text-lg text-green-600 max-w-md space-y-2">
            <p>Onclick premissionless sophisticated trading</p>
            <p>The safest onchain vault</p>
          </div>
        </div>

        {/* Vault Interface */}
        <Card className="w-full max-w-md bg-white/90 backdrop-blur-sm border-green-200 shadow-xl">
          <CardContent className="p-6">
            {/* From Wallet Section */}
            <div className="space-y-4 mb-6">
              <div className="text-sm font-medium text-green-700 mb-2">From wallet</div>

              <div className="flex items-center justify-between p-4 bg-green-50 rounded-lg border border-green-200">
                <div className="flex items-center space-x-3">
                  <div className="text-2xl">🐢</div>
                  <div>
                    <div className="font-semibold text-green-800">{currentToken.symbol}</div>
                    <div className="text-sm text-green-600">{currentToken.name}</div>
                  </div>
                </div>
                <div className="flex items-center space-x-2">
                  <div className="text-right">
                    <div className="font-semibold text-green-800">{currentToken.balance}</div>
                  </div>
                  <button
                    onClick={() => setSelectedToken(selectedToken === "asset" ? "share" : "asset")}
                    className="p-1 hover:bg-green-100 rounded"
                  >
                    <ChevronDown className="w-4 h-4 text-green-500" />
                  </button>
                </div>
              </div>

              {/* Amount Input */}
              <div className="relative">
                <Input
                  type="number"
                  placeholder="0"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  className="text-lg font-semibold border-green-200 focus:border-green-400 focus:ring-green-400 pr-16"
                />
                <button className="absolute right-3 top-1/2 transform -translate-y-1/2 text-sm text-green-700 hover:text-green-800 font-medium">
                  MAX
                </button>
              </div>

              <div className="text-sm text-green-600">Balance: {currentToken.balance}</div>
            </div>

            {/* Arrow and To Vault */}
            <div className="flex flex-col items-center mb-6">
              <div className="flex items-center space-x-2 text-green-600 mb-2">
                <ArrowDown className="w-5 h-5" />
                <span className="text-sm font-medium">To vault</span>
              </div>

              {/* Vault Name */}
              <div className="w-full p-3 bg-emerald-50 rounded-lg border border-emerald-200 text-center">
                <div className="text-sm text-emerald-600 mb-1">Vault</div>
                <div className="font-semibold text-emerald-800">{vaultData.vaultName}</div>
              </div>
            </div>

            {/* You Will Receive Section */}
            <div className="space-y-4 mb-6">
              <div className="text-sm font-medium text-green-700">You will receive</div>

              <div className="flex items-center justify-between p-4 bg-emerald-50 rounded-lg border border-emerald-200">
                <div className="flex items-center space-x-3">
                  <div className="text-2xl">🐢</div>
                  <div>
                    <div className="font-semibold text-emerald-800">{receiveToken.symbol}</div>
                    <div className="text-sm text-emerald-600">{receiveToken.name}</div>
                  </div>
                </div>
                <div className="text-right">
                  <div className="font-semibold text-emerald-800">
                    {amount ? (Number.parseFloat(amount) * (selectedToken === "asset" ? 0.89 : 1.12)).toFixed(2) : "--"}
                  </div>
                </div>
              </div>
            </div>

            {/* Action Buttons */}
            <div className="space-y-3">
              <Button
                className="w-full bg-gradient-to-r from-green-600 to-emerald-600 hover:from-green-700 hover:to-emerald-700 text-white font-semibold py-3"
                disabled={!amount}
              >
                {selectedToken === "asset" ? "Deposit" : "Withdraw"}
              </Button>

              <Button
                variant="outline"
                className="w-full border-green-200 text-green-700 hover:bg-green-50 bg-transparent"
                disabled={!amount}
              >
                {selectedToken === "asset" ? "Withdraw" : "Deposit"}
              </Button>
            </div>
          </CardContent>
        </Card>
      </main>
    </div>
  )
}
