//
//  TradeModels.swift
//  tradetogether
//
//  Created by Codex on 05/05/26.
//

import Foundation
import SwiftUI
import UIKit

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
    static let ink = adaptive(light: UIColor.black, dark: UIColor.white)
    static let paper = adaptive(light: UIColor.white, dark: UIColor(red: 0.071, green: 0.071, blue: 0.071, alpha: 1))
    static let panel = adaptive(light: UIColor(red: 0.980, green: 0.980, blue: 0.980, alpha: 1), dark: UIColor(red: 0.094, green: 0.094, blue: 0.094, alpha: 1))
    static let tile = adaptive(light: UIColor(red: 0.961, green: 0.961, blue: 0.961, alpha: 1), dark: UIColor(red: 0.157, green: 0.157, blue: 0.157, alpha: 1))
    static let elevated = adaptive(light: UIColor.white, dark: UIColor(red: 0.243, green: 0.243, blue: 0.243, alpha: 1))
    static let line = adaptive(light: UIColor(red: 0.910, green: 0.910, blue: 0.920, alpha: 1), dark: UIColor(red: 0.165, green: 0.165, blue: 0.165, alpha: 1))
    static let muted = adaptive(light: UIColor(red: 0.467, green: 0.467, blue: 0.467, alpha: 1), dark: UIColor(red: 0.702, green: 0.702, blue: 0.702, alpha: 1))
    static let tertiary = adaptive(light: UIColor(red: 0.600, green: 0.600, blue: 0.600, alpha: 1), dark: UIColor(red: 0.416, green: 0.416, blue: 0.416, alpha: 1))
    static let gain = adaptive(light: UIColor(red: 0.345, green: 0.765, blue: 0.133, alpha: 1), dark: UIColor(red: 0.114, green: 0.725, blue: 0.329, alpha: 1))
    static let loss = adaptive(light: UIColor(red: 0.996, green: 0.173, blue: 0.333, alpha: 1), dark: UIColor(red: 0.945, green: 0.369, blue: 0.424, alpha: 1))
    static let error = adaptive(light: UIColor(red: 0.929, green: 0.286, blue: 0.337, alpha: 1), dark: UIColor(red: 0.945, green: 0.369, blue: 0.424, alpha: 1))
    static let gold = adaptive(light: UIColor(red: 0.90, green: 0.58, blue: 0.12, alpha: 1), dark: UIColor(red: 0.94, green: 0.67, blue: 0.24, alpha: 1))
    static let chartBlue = adaptive(light: UIColor(red: 0.176, green: 0.498, blue: 0.976, alpha: 1), dark: UIColor(red: 0.60, green: 0.76, blue: 1.00, alpha: 1))
    static let brandBlue = adaptive(light: UIColor(red: 0.176, green: 0.498, blue: 0.976, alpha: 1), dark: UIColor(red: 0.114, green: 0.725, blue: 0.329, alpha: 1))
    static let softPurple = adaptive(light: UIColor(red: 0.55, green: 0.32, blue: 0.96, alpha: 1), dark: UIColor(red: 0.63, green: 0.49, blue: 0.98, alpha: 1))
    static let verified = adaptive(light: UIColor(red: 0.000, green: 0.584, blue: 0.965, alpha: 1), dark: UIColor(red: 0.64, green: 0.76, blue: 1.00, alpha: 1))

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        })
    }
}

extension Font {
    static func seek(size: CGFloat, weight: Font.Weight = .regular, design: Font.Design? = nil) -> Font {
        Font.custom("Inter", size: size).weight(weight)
    }

    static let tradeScreenTitle = Font.seek(size: 17, weight: .bold)
    static let tradeDisplayName = Font.seek(size: 15, weight: .semibold)
    static let tradePostBody = Font.seek(size: 15, weight: .regular)
    static let tradeQuotedBody = Font.seek(size: 14, weight: .regular)
    static let tradeHandle = Font.seek(size: 14, weight: .regular)
    static let tradeActionCount = Font.seek(size: 13, weight: .regular)
    static let tradeButton = Font.seek(size: 15, weight: .semibold)
    static let tradeFilterChip = Font.seek(size: 14, weight: .semibold)
}

struct TradePressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.78 : 1)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}
