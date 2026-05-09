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
    @StateObject private var settings = SeekAPISettings.shared
    @State private var selectedProfileTab: ProfileTab = .myTrades

    var body: some View {
        let stats = TradeMetrics.stats(for: profile, posts: posts)

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                WSJMasthead()
                profileHeader(stats: stats, isCurrentUser: profile.id == store.currentUser.id)
                if profile.id == store.currentUser.id {
                    BrokerageConnectionView()
                }
                profileTabs
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(TradeTheme.paper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func profileHeader(stats: ProfileStats, isCurrentUser: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                TraderAvatar(profile: profile, size: 58)
                VStack(alignment: .leading, spacing: 5) {
                    Text(profile.name)
                        .font(.seek(size: 22, weight: .bold))
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
                    Button {
                        settings.signOut()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Log out")
                                .font(.seek(size: 13, weight: .bold))
                        }
                        .foregroundStyle(TradeTheme.ink)
                        .padding(.horizontal, 10)
                        .frame(height: 34)
                        .background(TradeTheme.tile)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(TradePressableStyle())
                    .accessibilityLabel("Log out")
                }
            }

            HStack(spacing: 8) {
                MetricPill(title: "Win Rate", value: "\(stats.winRate)%", tint: TradeTheme.gain)
                MetricPill(title: "Closed", value: "\(stats.closedIdeas)")
                MetricPill(title: "Avg Return", value: stats.averageReturn.percentText, tint: stats.averageReturn >= 0 ? TradeTheme.gain : TradeTheme.loss)
            }

            HStack(spacing: 8) {
                MetricPill(title: "Active Ideas", value: "\(stats.activeIdeas)")
                MetricPill(title: "Followers", value: profile.followers)
            }
        }
        .padding(14)
        .background(TradeTheme.panel)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(TradeTheme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var profileTabs: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ForEach(ProfileTab.allCases) { tab in
                    Button {
                        selectedProfileTab = tab
                    } label: {
                        Text(tab.rawValue)
                            .font(.seek(size: 14, weight: .bold))
                            .foregroundStyle(selectedProfileTab == tab ? TradeTheme.paper : TradeTheme.ink)
                            .padding(.horizontal, 14)
                            .frame(height: 34)
                            .background(selectedProfileTab == tab ? TradeTheme.ink : TradeTheme.tile)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }

            switch selectedProfileTab {
            case .myTrades:
                if profile.id == store.currentUser.id {
                    MyTradesProfileSection()
                } else {
                    publicTradesPlaceholder
                }
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
    case myTrades = "My Trades"

    var id: String { rawValue }
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
        VStack(alignment: .leading, spacing: 8) {
            Text("No verified trades yet")
                .font(.seek(size: 14, weight: .bold))
                .foregroundStyle(TradeTheme.ink)
            Text("Connect and sync a brokerage account above. Open positions and closed activity from SnapTrade will populate this tab.")
                .font(.seek(size: 14, weight: .regular))
                .foregroundStyle(TradeTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(TradeTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
