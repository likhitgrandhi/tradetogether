//
//  TradesHubView.swift
//  tradetogether
//
//  Created by Codex on 09/05/26.
//

import SwiftUI

enum TradesHubSection: String, CaseIterable, Identifiable {
    case topTrades = "Top Trades"
    case topTraders = "Top Traders"
    case subscribed = "Subscribed"

    var id: String { rawValue }
}

enum TradeDurationFilter: String, CaseIterable, Identifiable {
    case sevenDays = "7D"
    case thirtyDays = "30D"
    case ninetyDays = "90D"
    case all = "All"

    var id: String { rawValue }

    var days: Int? {
        switch self {
        case .sevenDays: 7
        case .thirtyDays: 30
        case .ninetyDays: 90
        case .all: nil
        }
    }

    var label: String { rawValue }

    var menuTitle: String {
        switch self {
        case .sevenDays:
            "Last 7 days"
        case .thirtyDays:
            "Last 30 days"
        case .ninetyDays:
            "Last 90 days"
        case .all:
            "All time"
        }
    }
}

enum TradeListFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case stocks = "Stocks"
    case options = "Options"
    case futures = "Futures"
    case open = "Open"
    case closed = "Closed"

    var id: String { rawValue }

    func matches(_ post: TradeIdea) -> Bool {
        switch self {
        case .all:
            true
        case .stocks:
            post.product == .equity
        case .options:
            post.product == .options
        case .futures:
            post.product == .futures
        case .open:
            post.status == .active
        case .closed:
            post.status.isClosed
        }
    }
}

struct TradesHubView: View {
    let store: DemoStore
    @State private var selectedSection: TradesHubSection = .topTrades
    @State private var selectedDuration: TradeDurationFilter = .thirtyDays
    @State private var selectedTradeFilter: TradeListFilter = .all

    private var topTrades: [TradeIdea] {
        store.topTrades(duration: selectedDuration).filter { selectedTradeFilter.matches($0) }
    }

    private var subscribedTrades: [TradeIdea] {
        store.subscribedTrades(duration: selectedDuration).filter { selectedTradeFilter.matches($0) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            sectionControl

            ScrollView {
                VStack(spacing: 0) {
                    listControls

                    switch selectedSection {
                    case .topTrades:
                        tradeList(topTrades, emptyMessage: "No trades match these filters.")
                    case .topTraders:
                        traderList
                    case .subscribed:
                        tradeList(subscribedTrades, emptyMessage: "Subscribe to traders to see their trades here.")
                    }
                }
                .padding(.bottom, 28)
            }
        }
        .background(TradeTheme.paper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack {
            Text("Trades")
                .font(.seek(size: 34, weight: .bold))
                .foregroundStyle(TradeTheme.ink)

            Spacer()

            HStack(spacing: 20) {
                Image(systemName: "magnifyingglass")
                filterMenu
            }
            .font(.seek(size: 20, weight: .regular))
            .foregroundStyle(TradeTheme.ink)
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, 18)
        .background(TradeTheme.paper)
    }

    private var sectionControl: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(TradesHubSection.allCases) { section in
                    QuietFilterChip(
                        title: section.rawValue,
                        isSelected: selectedSection == section
                    ) {
                        withAnimation(.snappy) {
                            selectedSection = section
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.bottom, 14)
        .background(TradeTheme.paper)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TradeTheme.line)
                .frame(height: 1)
        }
    }

    private var listControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Menu {
                    ForEach(TradeDurationFilter.allCases) { duration in
                        Button {
                            withAnimation(.snappy) {
                                selectedDuration = duration
                            }
                        } label: {
                            if selectedDuration == duration {
                                Label(duration.menuTitle, systemImage: "checkmark")
                            } else {
                                Text(duration.menuTitle)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 5) {
                        Text(selectedDuration.menuTitle)
                        Image(systemName: "chevron.down")
                            .font(.seek(size: 10, weight: .bold))
                    }
                    .font(.seek(size: 13, weight: .semibold))
                    .foregroundStyle(TradeTheme.ink)
                }
                .buttonStyle(TradePressableStyle())

                Text(durationSummary)
                    .font(.seek(size: 12, weight: .semibold))
                    .foregroundStyle(TradeTheme.muted)

                Spacer(minLength: 0)
            }

            activeFilterSummary
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .background(TradeTheme.paper)
    }

    @ViewBuilder
    private var filterMenu: some View {
        if selectedSection == .topTraders {
            Image(systemName: "line.3.horizontal.decrease")
        } else {
            Menu {
                ForEach(TradeListFilter.allCases) { filter in
                    Button {
                        withAnimation(.snappy) {
                            selectedTradeFilter = filter
                        }
                    } label: {
                        if selectedTradeFilter == filter {
                            Label(filter.rawValue, systemImage: "checkmark")
                        } else {
                            Text(filter.rawValue)
                        }
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
            }
            .buttonStyle(TradePressableStyle())
        }
    }

    @ViewBuilder
    private var activeFilterSummary: some View {
        if selectedSection != .topTraders, selectedTradeFilter != .all {
            HStack(spacing: 6) {
                Text("Filter:")
                    .font(.seek(size: 12, weight: .regular))
                    .foregroundStyle(TradeTheme.muted)
                Text(selectedTradeFilter.rawValue)
                    .font(.seek(size: 12, weight: .semibold))
                    .foregroundStyle(TradeTheme.ink)
                Button {
                    withAnimation(.snappy) {
                        selectedTradeFilter = .all
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.seek(size: 10, weight: .bold))
                        .foregroundStyle(TradeTheme.muted)
                }
                .buttonStyle(TradePressableStyle())
            }
        }
    }

    private func tradeList(_ posts: [TradeIdea], emptyMessage: String) -> some View {
        VStack(spacing: 12) {
            if posts.isEmpty {
                TradesEmptyState(message: emptyMessage)
            } else {
                ForEach(Array(posts.enumerated()), id: \.element.id) { index, post in
                    let stock = store.stock(id: post.stockID)
                    NavigationLink {
                        PostDetailView(post: post, store: store)
                    } label: {
                        TradeListRow(
                            rank: index + 1,
                            post: post,
                            stock: stock
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    private var traderList: some View {
        VStack(spacing: 12) {
            ForEach(Array(store.rankedTraders(duration: selectedDuration).enumerated()), id: \.element.id) { index, profile in
                NavigationLink {
                    ProfileView(profile: profile, posts: store.posts(for: profile), store: store)
                } label: {
                    TraderPerformanceRow(
                        rank: index + 1,
                        profile: profile,
                        posts: store.posts(for: profile).filter { store.isInDuration($0, duration: selectedDuration) },
                        duration: selectedDuration,
                        isSubscribed: store.subscribedTraderIDs.contains(profile.id),
                        store: store
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }

    private var durationSummary: String {
        switch selectedSection {
        case .topTrades:
            "\(topTrades.count) trades"
        case .topTraders:
            "\(store.rankedTraders(duration: selectedDuration).count) traders"
        case .subscribed:
            "\(subscribedTrades.count) trades"
        }
    }
}

struct QuietFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.seek(size: 13, weight: .semibold))
                .foregroundStyle(isSelected ? TradeTheme.ink : TradeTheme.muted)
                .padding(.horizontal, 14)
                .frame(height: 32)
                .background(Capsule().fill(isSelected ? TradeTheme.tile : Color.clear))
                .overlay {
                    Capsule()
                        .stroke(TradeTheme.line, lineWidth: 1)
                }
        }
        .buttonStyle(TradePressableStyle())
    }
}

struct TradeListRow: View {
    let rank: Int
    let post: TradeIdea
    let stock: StockInstrument

    private var score: Double {
        post.returnPercent ?? stock.changePercent
    }

    private var scoreColor: Color {
        score >= 0 ? TradeTheme.gain : TradeTheme.loss
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 7) {
                        Text("#\(rank)")
                            .font(.seek(size: 12, weight: .bold).monospacedDigit())
                            .foregroundStyle(TradeTheme.muted)
                        tag(productLabel)
                        tag(post.direction.rawValue)
                    }

                    Text(instrumentTitle)
                        .font(.seek(size: 15, weight: .semibold))
                        .foregroundStyle(TradeTheme.ink)
                        .lineLimit(2)
                        .minimumScaleFactor(0.78)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 6) {
                    Text(pnlLabel)
                        .font(.seek(size: 13, weight: .semibold))
                        .foregroundStyle(TradeTheme.ink)
                    Text(score.percentText)
                        .font(.seek(size: 15, weight: .semibold).monospacedDigit())
                        .foregroundStyle(scoreColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
            }

            HStack(spacing: 0) {
                metric("Entry", currency(post.entry))
                metric("Target", currency(post.target))
                metric(post.status.isClosed ? "Exit" : "Mark", post.status.isClosed ? exitText : currency(stock.price))
                metric("Status", statusText, tint: post.status == .active ? TradeTheme.gain : TradeTheme.ink)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(TradeTheme.panel)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(TradeTheme.line, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func metric(_ title: String, _ value: String, tint: Color = TradeTheme.ink) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.seek(size: 12, weight: .regular))
                .foregroundStyle(TradeTheme.muted)
            Text(value)
                .font(.seek(size: 14, weight: .semibold).monospacedDigit())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func tag(_ title: String) -> some View {
        Text(title)
            .font(.seek(size: 12, weight: .semibold))
            .foregroundStyle(TradeTheme.muted)
            .padding(.horizontal, 8)
            .frame(height: 22)
            .background(RoundedRectangle(cornerRadius: 6).fill(TradeTheme.paper))
            .overlay {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(TradeTheme.line, lineWidth: 1)
            }
    }

    private var pnlLabel: String {
        post.status.isClosed ? "Realized PnL" : "Unrealized PnL"
    }

    private var statusText: String {
        post.status == .active ? "Open" : "Closed"
    }

    private var productLabel: String {
        switch post.product {
        case .equity: "Stock"
        case .futures: "Future"
        case .options: post.direction == .long ? "Call" : "Put"
        }
    }

    private var instrumentTitle: String {
        switch post.product {
        case .equity:
            stock.symbol
        case .futures:
            "\(stock.symbol) Future Exp: May 06"
        case .options:
            "\(stock.symbol) \(post.direction == .long ? "Call" : "Put") \(strikeText) Exp: May 06"
        }
    }

    private var strikeText: String {
        let strike = post.direction == .long ? post.target : post.stop
        return String(format: "%.2f", strike)
    }

    private var exitText: String {
        switch post.status {
        case .hitTarget:
            currency(post.target)
        case .stoppedOut:
            currency(post.stop)
        case .thesisChanged, .active:
            currency(stock.price)
        }
    }

    private func currency(_ value: Double) -> String {
        "\(stock.region == .india ? "Rs " : "$")\(value.cleanPrice)"
    }
}

struct TraderPerformanceRow: View {
    let rank: Int
    let profile: TraderProfile
    let posts: [TradeIdea]
    let duration: TradeDurationFilter
    let isSubscribed: Bool
    let store: DemoStore

    private var stats: ProfileStats {
        TradeMetrics.stats(for: profile, posts: posts)
    }

    private var pnl: Double {
        posts.reduce(0) { partial, post in
            let stock = store.stock(id: post.stockID)
            let quantity: Double
            switch post.product {
            case .equity: quantity = 10
            case .futures: quantity = 75
            case .options: quantity = 100
            }
            let returnPercent = post.returnPercent ?? stock.changePercent
            return partial + (post.entry * quantity * returnPercent / 100)
        }
    }

    private var roi: Double {
        let returns = posts.map { post in
            post.returnPercent ?? store.stock(id: post.stockID).changePercent
        }
        guard !returns.isEmpty else { return 0 }
        return returns.reduce(0, +) / Double(returns.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                TraderAvatar(profile: profile, size: 38)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text("#\(rank)")
                            .font(.seek(size: 12, weight: .bold).monospacedDigit())
                            .foregroundStyle(TradeTheme.muted)
                        Text(profile.handle)
                            .font(.seek(size: 15, weight: .semibold))
                            .foregroundStyle(TradeTheme.ink)
                            .lineLimit(1)
                    }

                    Text("\(profile.role) - \(profile.followers) subscribers")
                        .font(.seek(size: 12, weight: .regular))
                        .foregroundStyle(TradeTheme.muted)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(alignment: .trailing, spacing: 6) {
                    Text("\(duration.label) PnL")
                        .font(.seek(size: 13, weight: .semibold))
                        .foregroundStyle(TradeTheme.ink)
                    Text(currency(pnl))
                        .font(.seek(size: 15, weight: .semibold).monospacedDigit())
                        .foregroundStyle(pnl >= 0 ? TradeTheme.gain : TradeTheme.loss)
                        .lineLimit(1)
                        .minimumScaleFactor(0.74)
                }
            }

            HStack(spacing: 0) {
                traderMetric("ROI", roi.percentText, tint: roi >= 0 ? TradeTheme.gain : TradeTheme.loss)
                traderMetric("WR", "\(stats.winRate)%")
                traderMetric("Closed", "\(stats.closedIdeas)")
                traderMetric("Open", "\(stats.activeIdeas)")
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(TradeTheme.panel)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(TradeTheme.line, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func traderMetric(_ title: String, _ value: String, tint: Color = TradeTheme.ink) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.seek(size: 12, weight: .regular))
                .foregroundStyle(TradeTheme.muted)
            Text(value)
                .font(.seek(size: 13, weight: .bold).monospacedDigit())
                .foregroundStyle(tint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func currency(_ value: Double) -> String {
        let sign = value >= 0 ? "+" : "-"
        return "\(sign)$\(abs(value).cleanPrice)"
    }
}

struct MiniPerformanceSparkline: View {
    let values: [Double]
    let positive: Bool

    var body: some View {
        GeometryReader { proxy in
            let points = points(in: proxy.size)
            ZStack {
                if points.count > 1 {
                    Path { path in
                        path.move(to: CGPoint(x: points[0].x, y: proxy.size.height))
                        points.forEach { point in
                            path.addLine(to: point)
                        }
                        path.addLine(to: CGPoint(x: points[points.count - 1].x, y: proxy.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [
                                (positive ? TradeTheme.gain : TradeTheme.loss).opacity(0.24),
                                (positive ? TradeTheme.gain : TradeTheme.loss).opacity(0.02)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    Path { path in
                        path.move(to: points[0])
                        points.dropFirst().forEach { point in
                            path.addLine(to: point)
                        }
                    }
                    .stroke(positive ? TradeTheme.gain : TradeTheme.loss, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func points(in size: CGSize) -> [CGPoint] {
        guard values.count > 1 else { return [] }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 1
        let range = max(maxValue - minValue, 0.01)
        return values.enumerated().map { index, value in
            let x = CGFloat(index) / CGFloat(values.count - 1) * size.width
            let normalized = (value - minValue) / range
            let y = size.height - CGFloat(normalized) * size.height
            return CGPoint(x: x, y: y)
        }
    }
}

struct TradesEmptyState: View {
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "arrow.2.squarepath")
                .font(.seek(size: 30, weight: .regular))
                .foregroundStyle(TradeTheme.muted)
            Text(message)
                .font(.seek(size: 15, weight: .semibold))
                .foregroundStyle(TradeTheme.ink)
                .multilineTextAlignment(.center)
            Text("Adjust filters or subscribe to more traders.")
                .font(.seek(size: 13, weight: .regular))
                .foregroundStyle(TradeTheme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 28)
        .padding(.vertical, 56)
    }
}

extension DemoStore {
    var subscribedTraderIDs: Set<TraderProfile.ID> {
        ["maya", "arjun"]
    }

    func topTrades(duration: TradeDurationFilter) -> [TradeIdea] {
        posts
            .filter { isInDuration($0, duration: duration) }
            .sorted { first, second in
                tradeScore(first) > tradeScore(second)
            }
    }

    func subscribedTrades(duration: TradeDurationFilter) -> [TradeIdea] {
        topTrades(duration: duration)
            .filter { subscribedTraderIDs.contains($0.authorID) }
    }

    func rankedTraders(duration: TradeDurationFilter) -> [TraderProfile] {
        profiles
            .filter { $0.id != currentUser.id }
            .sorted { first, second in
                traderScore(first, duration: duration) > traderScore(second, duration: duration)
            }
    }

    func isInDuration(_ post: TradeIdea, duration: TradeDurationFilter) -> Bool {
        guard let days = duration.days else { return true }
        return postAgeInDays(post.postedAgo) <= days
    }

    private func tradeScore(_ post: TradeIdea) -> Double {
        let stock = stock(id: post.stockID)
        let rawReturn = post.returnPercent ?? stock.changePercent
        let statusBoost = post.status == .active ? 0.35 : 0
        let engagementBoost = Double(post.votes + post.comments) / 500
        return rawReturn + statusBoost + engagementBoost
    }

    private func traderScore(_ profile: TraderProfile, duration: TradeDurationFilter) -> Double {
        let traderPosts = posts(for: profile).filter { isInDuration($0, duration: duration) }
        let returns = traderPosts.map { post in
            post.returnPercent ?? stock(id: post.stockID).changePercent
        }
        let averageReturn = returns.isEmpty ? 0 : returns.reduce(0, +) / Double(returns.count)
        let stats = TradeMetrics.stats(for: profile, posts: traderPosts)
        return averageReturn + Double(stats.winRate) / 20 + Double(stats.activeIdeas) * 0.15
    }

    private func postAgeInDays(_ postedAgo: String) -> Int {
        if postedAgo.hasSuffix("m") || postedAgo.hasSuffix("h") {
            return 0
        }
        if postedAgo.hasSuffix("d") {
            return Int(postedAgo.dropLast()) ?? 0
        }
        return 90
    }
}
