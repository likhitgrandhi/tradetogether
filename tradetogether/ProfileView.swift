//
//  ProfileView.swift
//  tradetogether
//
//  Created by Codex on 05/05/26.
//

import SwiftUI

struct ProfileView: View {
    let profile: TraderProfile
    let posts: [TradeIdea]
    let store: DemoStore
    @State private var selectedProfileTab: ProfileTab = .posts

    var body: some View {
        let stats = TradeMetrics.stats(for: profile, posts: posts)

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                profileTopBar
                profileHeader(stats: stats, isCurrentUser: profile.id == store.currentUser.id)
                profileTabs
            }
            .padding(.bottom, 24)
        }
        .background(TradeTheme.paper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var profileTopBar: some View {
        HStack {
            Color.clear
                .frame(width: 44, height: 44)

            Spacer()

            UpDownLogo()

            Spacer()

            if profile.id == store.currentUser.id {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.seek(size: 22, weight: .semibold))
                        .foregroundStyle(TradeTheme.ink)
                        .frame(width: 44, height: 44)
                        .background(TradeTheme.tile)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open settings")
            } else {
                Image(systemName: "ellipsis")
                    .font(.seek(size: 22, weight: .semibold))
                    .foregroundStyle(TradeTheme.ink)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 10)
        .background(TradeTheme.paper)
    }

    private func profileHeader(stats: ProfileStats, isCurrentUser: Bool) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                TraderAvatar(profile: profile, size: 72)
                VStack(alignment: .leading, spacing: 5) {
                    Text(profile.name)
                        .font(.seek(size: 24, weight: .bold))
                        .foregroundStyle(TradeTheme.ink)
                    Text("\(profile.handle) - \(profile.role)")
                        .font(.seek(size: 15, weight: .semibold))
                        .foregroundStyle(TradeTheme.muted)
                    Text(profile.bio)
                        .font(.seek(size: 15, weight: .regular))
                        .foregroundStyle(TradeTheme.ink.opacity(0.82))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                if isCurrentUser {
                    Button {} label: {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Edit")
                                .font(.seek(size: 13, weight: .bold))
                        }
                        .foregroundStyle(TradeTheme.ink)
                        .padding(.horizontal, 10)
                        .frame(height: 34)
                        .background(TradeTheme.tile)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(TradePressableStyle())
                    .accessibilityLabel("Edit profile")
                }
            }

            HStack(spacing: 18) {
                profileStat(value: "\(stats.winRate)%", label: "Win Rate", tint: TradeTheme.gain)
                profileStat(value: profile.followers, label: "Followers")
                profileStat(value: "\(stats.activeIdeas)", label: "Active")
                profileStat(value: "\(stats.closedIdeas)", label: "Closed")
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 18)
        .background(TradeTheme.paper)
    }

    private func profileStat(value: String, label: String, tint: Color = TradeTheme.ink) -> some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.seek(size: 15, weight: .bold))
                .foregroundStyle(tint)
            Text(label)
                .font(.seek(size: 14, weight: .regular))
                .foregroundStyle(TradeTheme.muted)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.78)
    }

    private var profileTabs: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 28) {
                ForEach(ProfileTab.allCases) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selectedProfileTab = tab
                        }
                    } label: {
                        VStack(spacing: 9) {
                            Text(tab.rawValue)
                                .font(.seek(size: 17, weight: selectedProfileTab == tab ? .bold : .semibold))
                                .foregroundStyle(selectedProfileTab == tab ? TradeTheme.ink : TradeTheme.muted)
                            Rectangle()
                                .fill(selectedProfileTab == tab ? TradeTheme.spotifyGreen : Color.clear)
                                .frame(width: 30, height: 4)
                        }
                        .frame(height: 48)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 20)

            Rectangle()
                .fill(TradeTheme.line)
                .frame(height: 1)

            switch selectedProfileTab {
            case .posts:
                ProfilePostsSection(profile: profile, posts: posts, store: store)
            case .trades:
                if profile.id == store.currentUser.id {
                    MyTradesProfileSection()
                } else {
                    publicTradesPlaceholder
                }
            case .saved:
                SavedProfileSection()
            }
        }
    }

    private var publicTradesPlaceholder: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Verified trades will appear here once this profile is connected to live data.")
                .font(.seek(size: 14, weight: .regular))
                .foregroundStyle(TradeTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(TradeTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

private enum ProfileTab: String, CaseIterable, Identifiable {
    case posts = "Posts"
    case trades = "Trades"
    case saved = "Saved"

    var id: String { rawValue }
}

private struct ProfilePostsSection: View {
    let profile: TraderProfile
    let posts: [TradeIdea]
    let store: DemoStore

    var body: some View {
        VStack(spacing: 0) {
            if posts.isEmpty {
                ProfileEmptyState(
                    icon: "doc.text.magnifyingglass",
                    title: "No posts yet",
                    message: "Trade ideas and market notes will show here."
                )
            } else {
                ForEach(posts) { post in
                    TradeIdeaCard(
                        post: post,
                        author: profile,
                        stock: store.stock(id: post.stockID),
                        stats: TradeMetrics.stats(for: profile, posts: posts)
                    )
                }
            }
        }
    }
}

private struct SavedProfileSection: View {
    var body: some View {
        ProfileEmptyState(
            icon: "bookmark",
            title: "No saved posts",
            message: "Saved trade ideas and references will collect here."
        )
    }
}

private struct MyTradesProfileSection: View {
    @StateObject private var settings = SeekAPISettings.shared
    @State private var trades: [SeekTradeCandidate] = []
    @State private var isLoading = false
    @State private var statusText: String?

    private var api: SeekAPIClient {
        SeekAPIClient(settings: settings)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("My Trades")
                        .font(.seek(size: 15, weight: .bold))
                        .foregroundStyle(TradeTheme.ink)
                    Text(subtitle)
                        .font(.seek(size: 13, weight: .regular))
                        .foregroundStyle(TradeTheme.muted)
                }
                Spacer()
                Button {
                    Task {
                        await loadTrades()
                    }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(TradeTheme.ink)
                        .frame(width: 34, height: 34)
                        .background(TradeTheme.tile)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }

            if isLoading {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(TradeTheme.ink)
                    Text("Loading verified trades")
                        .font(.seek(size: 14, weight: .regular))
                        .foregroundStyle(TradeTheme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(TradeTheme.panel)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if trades.isEmpty {
                emptyState
            } else {
                ForEach(trades) { trade in
                    ProfileTradeRow(trade: trade)
                }
            }
        }
        .task {
            if trades.isEmpty {
                await loadTrades()
            }
        }
    }

    private var subtitle: String {
        if let statusText {
            return statusText
        }
        return trades.isEmpty ? "Synced brokerage trades will show here" : "\(trades.count) synced trades"
    }

    private var emptyState: some View {
        ProfileEmptyState(
            icon: "chart.line.uptrend.xyaxis",
            title: "No verified trades yet",
            message: "Connect and sync a brokerage account in Settings. Open positions and closed activity from SnapTrade will populate this tab."
        )
    }

    private func loadTrades() async {
        isLoading = true
        defer { isLoading = false }
        do {
            trades = try await api.tradeCandidates()
            statusText = trades.isEmpty ? "No synced trades found" : "\(trades.count) synced trades"
        } catch {
            statusText = error.localizedDescription
        }
    }
}

private struct ProfileEmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.seek(size: 42, weight: .regular))
                .foregroundStyle(TradeTheme.tertiary.opacity(0.72))
            VStack(spacing: 5) {
                Text(title)
                    .font(.seek(size: 15, weight: .bold))
                    .foregroundStyle(TradeTheme.ink)
                Text(message)
                    .font(.seek(size: 14, weight: .regular))
                    .foregroundStyle(TradeTheme.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 28)
        .padding(.vertical, 86)
        .background(TradeTheme.paper)
    }
}

private struct ProfileTradeRow: View {
    let trade: SeekTradeCandidate

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(trade.symbol ?? "UNKNOWN")
                        .font(.seek(size: 15, weight: .bold))
                        .foregroundStyle(TradeTheme.ink)
                    Text(trade.instrumentName ?? trade.providerSourceType.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.seek(size: 13, weight: .regular))
                        .foregroundStyle(TradeTheme.muted)
                        .lineLimit(1)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(trade.status.capitalized)
                        .font(.seek(size: 13, weight: .bold))
                        .foregroundStyle(trade.status == "open" ? TradeTheme.gain : TradeTheme.ink)
                    Text(trade.side.capitalized)
                        .font(.seek(size: 13, weight: .regular))
                        .foregroundStyle(TradeTheme.muted)
                }
            }

            HStack(spacing: 0) {
                tradeMetric("Entry", trade.entryPrice?.currencyText ?? "-")
                Divider()
                    .background(TradeTheme.line)
                tradeMetric(trade.status == "closed" ? "Exit" : "Mark", activePriceText)
                Divider()
                    .background(TradeTheme.line)
                tradeMetric("PnL", pnlText, tint: pnlTint)
            }
            .frame(height: 46)
        }
        .padding(14)
        .background(TradeTheme.panel)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(TradeTheme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var activePriceText: String {
        if trade.status == "closed" {
            return trade.exitPrice?.currencyText ?? "-"
        }
        return trade.markPrice?.currencyText ?? "-"
    }

    private var pnlText: String {
        if let returnPercent = trade.returnPercent {
            return returnPercent.percentText
        }
        if let pnl = trade.realizedPnl ?? trade.unrealizedPnl {
            return pnl.currencyText
        }
        return "Verified"
    }

    private var pnlTint: Color {
        let value = trade.returnPercent ?? trade.realizedPnl ?? trade.unrealizedPnl ?? 0
        return value >= 0 ? TradeTheme.gain : TradeTheme.loss
    }

    private func tradeMetric(_ label: String, _ value: String, tint: Color = TradeTheme.ink) -> some View {
        VStack(alignment: .center, spacing: 4) {
            Text(label)
                .font(.seek(size: 12, weight: .semibold))
                .foregroundStyle(TradeTheme.muted)
            Text(value)
                .font(.seek(size: 14, weight: .bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
    }
}
