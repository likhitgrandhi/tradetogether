//
//  TradeModels.swift
//  tradetogether
//
//  Created by Codex on 05/05/26.
//

import Foundation
import SwiftUI

enum MarketRegion: String, CaseIterable {
    case us = "US"
    case india = "India"
}

enum TradeDirection: String {
    case long = "Long"
    case short = "Short"

    var symbolName: String {
        switch self {
        case .long: "arrow.up.right"
        case .short: "arrow.down.right"
        }
    }
}

enum TradeStatus: String {
    case active = "Active"
    case hitTarget = "Target Hit"
    case stoppedOut = "Stopped Out"
    case thesisChanged = "Thesis Changed"

    var isClosed: Bool {
        self != .active
    }

    var isWin: Bool {
        self == .hitTarget
    }
}

enum RiskLevel: String {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

enum TradeProduct: String, CaseIterable, Hashable {
    case equity = "Equity"
    case futures = "Futures"
    case options = "Options"
}

struct StockInstrument: Identifiable, Hashable {
    let id: String
    let symbol: String
    let name: String
    let exchange: String
    let region: MarketRegion
    let price: Double
    let changePercent: Double
    let marketCap: String
    let volumeNote: String
    let priceHistory: [Double]
    let aiOverview: AIStockOverview

    var displaySymbol: String {
        "\(symbol) - \(exchange)"
    }

}

struct AIStockOverview: Hashable {
    let stance: String
    let riskLevel: RiskLevel
    let thesisAlignment: Int
    let summary: String
    let catalysts: [String]
    let risks: [String]
}

struct TraderProfile: Identifiable, Hashable {
    let id: String
    let name: String
    let handle: String
    let role: String
    let initials: String
    let followers: String
    let bio: String
}

struct TradeIdea: Identifiable, Hashable {
    let id: String
    let authorID: TraderProfile.ID
    let stockID: StockInstrument.ID
    let direction: TradeDirection
    let status: TradeStatus
    let title: String
    let thesis: String
    let timeframe: String
    let entry: Double
    let target: Double
    let stop: Double
    let postedAgo: String
    let votes: Int
    let comments: Int
    let returnPercent: Double?
    let product: TradeProduct

    var expectedMovePercent: Double {
        ((target - entry) / entry) * 100
    }
}

struct WatchlistItem: Identifiable, Hashable {
    let id: String
    let stockID: StockInstrument.ID
    let note: String
    let isInPortfolio: Bool
}

struct ProfileStats: Hashable {
    let closedIdeas: Int
    let wins: Int
    let averageReturn: Double
    let activeIdeas: Int

    var winRate: Int {
        guard closedIdeas > 0 else { return 0 }
        return Int((Double(wins) / Double(closedIdeas) * 100).rounded())
    }
}

enum TradeMetrics {
    static func stats(for profile: TraderProfile, posts: [TradeIdea]) -> ProfileStats {
        let closed = posts.filter { $0.status.isClosed }
        let wins = closed.filter(\.status.isWin).count
        let returns = closed.compactMap(\.returnPercent)
        let averageReturn = returns.isEmpty ? 0 : returns.reduce(0, +) / Double(returns.count)
        let active = posts.filter { $0.status == .active }.count

        return ProfileStats(
            closedIdeas: closed.count,
            wins: wins,
            averageReturn: averageReturn,
            activeIdeas: active
        )
    }
}

enum TradeTheme {
    static let ink = Color.black
    static let paper = Color.white
    static let panel = Color(red: 0.980, green: 0.980, blue: 0.980)
    static let tile = Color(red: 0.961, green: 0.961, blue: 0.961)
    static let line = Color(red: 0.910, green: 0.910, blue: 0.920)
    static let muted = Color(red: 0.467, green: 0.467, blue: 0.467)
    static let tertiary = Color(red: 0.600, green: 0.600, blue: 0.600)
    static let gain = Color(red: 0.345, green: 0.765, blue: 0.133)
    static let loss = Color(red: 0.996, green: 0.173, blue: 0.333)
    static let error = Color(red: 0.929, green: 0.286, blue: 0.337)
    static let gold = Color(red: 0.90, green: 0.58, blue: 0.12)
    static let chartBlue = Color(red: 0.176, green: 0.498, blue: 0.976)
    static let brandBlue = Color(red: 0.176, green: 0.498, blue: 0.976)
    static let softPurple = Color(red: 0.55, green: 0.32, blue: 0.96)
    static let verified = Color(red: 0.000, green: 0.584, blue: 0.965)
}

extension Font {
    static let tradeScreenTitle = Font.system(size: 17, weight: .bold)
    static let tradeDisplayName = Font.system(size: 15, weight: .semibold)
    static let tradePostBody = Font.system(size: 15, weight: .regular)
    static let tradeQuotedBody = Font.system(size: 14, weight: .regular)
    static let tradeHandle = Font.system(size: 14, weight: .regular)
    static let tradeActionCount = Font.system(size: 13, weight: .regular)
    static let tradeButton = Font.system(size: 15, weight: .semibold)
    static let tradeFilterChip = Font.system(size: 14, weight: .semibold)
}

struct TradePressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.78 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
