//
//  DemoStore.swift
//  tradetogether
//
//  Created by Codex on 05/05/26.
//

import Foundation

final class DemoStore {
    static let shared = DemoStore()

    let currentUser: TraderProfile
    let profiles: [TraderProfile]
    let stocks: [StockInstrument]
    let posts: [TradeIdea]
    let watchlist: [WatchlistItem]

    private init() {
        currentUser = TraderProfile(
            id: "me",
            name: "Likhit Grandhi",
            handle: "@likhit",
            role: "Swing trader",
            initials: "LG",
            followers: "214",
            bio: "Tracks clean setups across US tech and India large caps."
        )

        profiles = [
            currentUser,
            TraderProfile(id: "maya", name: "Maya Chen", handle: "@mayaMarkets", role: "Macro desk", initials: "MC", followers: "18.4K", bio: "Rates, mega-cap tech, and risk-on rotations."),
            TraderProfile(id: "arjun", name: "Arjun Rao", handle: "@niftyArjun", role: "India momentum", initials: "AR", followers: "9.7K", bio: "NSE breakouts, bank leadership, and disciplined stops."),
            TraderProfile(id: "sofia", name: "Sofia Reyes", handle: "@tapeReader", role: "Tape reader", initials: "SR", followers: "6.1K", bio: "Looks for market structure before earnings and policy events.")
        ]

        stocks = [
            StockInstrument(
                id: "aapl",
                symbol: "AAPL",
                name: "Apple Inc.",
                exchange: "NASDAQ",
                region: .us,
                price: 203.44,
                changePercent: 1.24,
                marketCap: "$3.1T",
                volumeNote: "Volume running 18% above 30-day average",
                priceHistory: [191, 193, 190, 196, 198, 197, 201, 203, 202, 204],
                aiOverview: AIStockOverview(
                    stance: "Constructive, but headline-sensitive",
                    riskLevel: .medium,
                    thesisAlignment: 74,
                    summary: "Price action is broadly tracking the bullish thesis, with higher lows and improving breadth in large-cap tech. The risk is that the move is still dependent on index strength rather than company-specific news.",
                    catalysts: ["Services margin commentary", "AI device cycle expectations", "NASDAQ breadth improvement"],
                    risks: ["Valuation compression", "China demand headlines", "Failed breakout below prior high"]
                )
            ),
            StockInstrument(
                id: "nvda",
                symbol: "NVDA",
                name: "Nvidia Corp.",
                exchange: "NASDAQ",
                region: .us,
                price: 126.88,
                changePercent: -0.62,
                marketCap: "$3.0T",
                volumeNote: "Options flow elevated into chip-sector earnings",
                priceHistory: [118, 121, 124, 123, 128, 131, 129, 127, 128, 126],
                aiOverview: AIStockOverview(
                    stance: "Momentum cooling near resistance",
                    riskLevel: .high,
                    thesisAlignment: 58,
                    summary: "The original momentum thesis is partially intact, but recent candles show hesitation near resistance. Bulls need a volume-backed reclaim before the setup improves.",
                    catalysts: ["Data-center guidance", "Semiconductor ETF inflows", "Cloud capex commentary"],
                    risks: ["Crowded positioning", "Multiple compression", "Failed reclaim of short-term moving average"]
                )
            ),
            StockInstrument(
                id: "reliance",
                symbol: "RELIANCE",
                name: "Reliance Industries",
                exchange: "NSE",
                region: .india,
                price: 2942.35,
                changePercent: 0.84,
                marketCap: "Rs 19.9T",
                volumeNote: "Delivery volume improving over the last three sessions",
                priceHistory: [2830, 2864, 2851, 2888, 2910, 2899, 2926, 2950, 2938, 2942],
                aiOverview: AIStockOverview(
                    stance: "Breakout attempt with support nearby",
                    riskLevel: .medium,
                    thesisAlignment: 69,
                    summary: "The stock is moving in line with a gradual breakout thesis, but confirmation still depends on holding above the prior consolidation zone.",
                    catalysts: ["Energy margin recovery", "Retail growth updates", "Index heavyweight flows"],
                    risks: ["Crude volatility", "Failed close above resistance", "Broad NIFTY weakness"]
                )
            ),
            StockInstrument(
                id: "hdfcbank",
                symbol: "HDFCBANK",
                name: "HDFC Bank",
                exchange: "NSE",
                region: .india,
                price: 1684.20,
                changePercent: -0.31,
                marketCap: "Rs 12.8T",
                volumeNote: "Muted tape while Bank Nifty consolidates",
                priceHistory: [1651, 1660, 1672, 1688, 1701, 1694, 1687, 1682, 1690, 1684],
                aiOverview: AIStockOverview(
                    stance: "Rangebound until banking breadth improves",
                    riskLevel: .low,
                    thesisAlignment: 52,
                    summary: "The setup is neither broken nor confirmed. The stock is respecting support, but participation from the banking basket is still thin.",
                    catalysts: ["Deposit growth data", "Bank Nifty follow-through", "Margin stabilization"],
                    risks: ["Weak credit growth", "Support retest", "Relative underperformance"]
                )
            )
        ]

        posts = [
            TradeIdea(id: "p1", authorID: "maya", stockID: "aapl", direction: .long, status: .active, title: "Added AAPL shares on the reclaim", thesis: "The stock is holding above its prior range with cleaner relative strength than QQQ. I want price above 198 before sizing up.", timeframe: "2-4 weeks", entry: 198.10, target: 214.00, stop: 191.50, postedAgo: "18m", votes: 142, comments: 31, returnPercent: nil, product: .equity),
            TradeIdea(id: "p2", authorID: "arjun", stockID: "reliance", direction: .long, status: .active, title: "Opened RELIANCE futures for a range break", thesis: "The futures contract is holding VWAP and delivery volume is improving. A close above 2960 keeps the long setup alive.", timeframe: "1-3 weeks", entry: 2895.00, target: 3060.00, stop: 2818.00, postedAgo: "44m", votes: 88, comments: 14, returnPercent: nil, product: .futures),
            TradeIdea(id: "p3", authorID: "sofia", stockID: "nvda", direction: .short, status: .thesisChanged, title: "Closed NVDA puts after the failed breakdown", thesis: "The put trade started well, but sellers could not hold the stock below the short-term average. I closed the option before theta did more damage.", timeframe: "3 days", entry: 130.40, target: 122.00, stop: 134.00, postedAgo: "2h", votes: 65, comments: 19, returnPercent: 1.9, product: .options),
            TradeIdea(id: "p4", authorID: "me", stockID: "hdfcbank", direction: .long, status: .active, title: "Holding HDFCBANK shares against support", thesis: "This is not a breakout yet. The stock has defined risk near support while Bank Nifty compresses, so I am keeping size modest.", timeframe: "1-2 weeks", entry: 1672.00, target: 1740.00, stop: 1634.00, postedAgo: "3h", votes: 27, comments: 7, returnPercent: nil, product: .equity),
            TradeIdea(id: "p5", authorID: "maya", stockID: "nvda", direction: .long, status: .hitTarget, title: "Closed NVDA futures at target", thesis: "The futures long caught the first pullback into the rising average. I booked the contract after price tagged the planned exit.", timeframe: "5 days", entry: 118.50, target: 127.00, stop: 114.20, postedAgo: "1d", votes: 231, comments: 54, returnPercent: 7.2, product: .futures),
            TradeIdea(id: "p6", authorID: "arjun", stockID: "hdfcbank", direction: .long, status: .stoppedOut, title: "Stopped out of HDFCBANK calls", thesis: "The call option needed bank-sector follow-through after the gap. The stock faded, the stop hit, and I cut the contract cleanly.", timeframe: "4 days", entry: 1704.00, target: 1765.00, stop: 1668.00, postedAgo: "2d", votes: 49, comments: 12, returnPercent: -2.1, product: .options)
        ]

        watchlist = [
            WatchlistItem(id: "w1", stockID: "aapl", note: "Portfolio position - watching 214 target", isInPortfolio: true),
            WatchlistItem(id: "w2", stockID: "reliance", note: "Trade idea active - needs close above 2960", isInPortfolio: false),
            WatchlistItem(id: "w3", stockID: "hdfcbank", note: "Portfolio position - range support", isInPortfolio: true),
            WatchlistItem(id: "w4", stockID: "nvda", note: "High-volume watch only", isInPortfolio: false)
        ]
    }

    func profile(id: TraderProfile.ID) -> TraderProfile {
        profiles.first { $0.id == id } ?? currentUser
    }

    func stock(id: StockInstrument.ID) -> StockInstrument {
        stocks.first { $0.id == id } ?? stocks[0]
    }

    func posts(for profile: TraderProfile) -> [TradeIdea] {
        posts.filter { $0.authorID == profile.id }
    }

    func posts(for stock: StockInstrument) -> [TradeIdea] {
        posts.filter { $0.stockID == stock.id }
    }
}
