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
                .frame(width: 34, height: 34)

            Spacer()

            UpDownLogo()
                .frame(width: 20, height: 27)

            Spacer()

            if profile.id == store.currentUser.id {
                NavigationLink {
                    SettingsView()
                } label: {
                    Image(systemName: "gearshape")
                        .font(.seek(size: 18, weight: .semibold))
                        .foregroundStyle(TradeTheme.ink)
                        .frame(width: 34, height: 34)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Open settings")
            } else {
                Image(systemName: "ellipsis")
                    .font(.seek(size: 19, weight: .semibold))
                    .foregroundStyle(TradeTheme.ink)
                    .frame(width: 34, height: 34)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 4)
        .padding(.bottom, 8)
        .background(TradeTheme.paper)
    }

    private func profileHeader(stats: ProfileStats, isCurrentUser: Bool) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                TraderAvatar(profile: profile, size: 56)
                    .overlay {
                        Circle()
                            .stroke(TradeTheme.line, lineWidth: 1)
                    }

                VStack(alignment: .leading, spacing: 4) {
                    Text(profile.name)
                        .font(.seek(size: 21, weight: .bold))
                        .foregroundStyle(TradeTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                    Text("\(profile.handle) - \(profile.role)")
                        .font(.seek(size: 13, weight: .semibold))
                        .foregroundStyle(TradeTheme.muted)
                        .lineLimit(1)
                    Text(profile.bio)
                        .font(.seek(size: 13, weight: .regular))
                        .lineSpacing(2)
                        .foregroundStyle(TradeTheme.muted)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                if isCurrentUser {
                    Button {} label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(TradeTheme.ink)
                            .frame(width: 32, height: 32)
                            .background(TradeTheme.tile)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(TradePressableStyle())
                    .accessibilityLabel("Edit profile")
                }
            }

            HStack(spacing: 0) {
                profileStat(value: "\(stats.winRate)%", label: "Win Rate", tint: TradeTheme.gain)
                profileStat(value: profile.followers, label: "Followers")
                profileStat(value: "\(stats.activeIdeas)", label: "Active")
                profileStat(value: "\(stats.closedIdeas)", label: "Closed")
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 16)
        .background(TradeTheme.paper)
    }

    private func profileStat(value: String, label: String, tint: Color = TradeTheme.ink) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(value)
                .font(.seek(size: 14, weight: .bold).monospacedDigit())
                .foregroundStyle(tint)
            Text(label)
                .font(.seek(size: 11, weight: .semibold))
                .foregroundStyle(TradeTheme.muted)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.78)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var profileTabs: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 24) {
                ForEach(ProfileTab.allCases) { tab in
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selectedProfileTab = tab
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Text(tab.rawValue)
                                .font(.seek(size: 14, weight: selectedProfileTab == tab ? .bold : .semibold))
                                .foregroundStyle(selectedProfileTab == tab ? TradeTheme.ink : TradeTheme.muted)
                            Rectangle()
                                .fill(selectedProfileTab == tab ? TradeTheme.spotifyGreen : Color.clear)
                                .frame(width: 22, height: 2)
                        }
                        .frame(height: 42)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
            }
            .padding(.horizontal, 18)

            Rectangle()
                .fill(TradeTheme.line)
                .frame(height: 1)

            switch selectedProfileTab {
            case .posts:
                ProfilePostsSection(
                    profile: profile,
                    posts: posts,
                    store: store,
                    isCurrentUser: profile.id == store.currentUser.id
                )
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
                .font(.seek(size: 13, weight: .regular))
                .foregroundStyle(TradeTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 18)
        .background(TradeTheme.paper)
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
    let isCurrentUser: Bool
    @EnvironmentObject private var postStore: PostStore

    var body: some View {
        VStack(spacing: 0) {
            if isCurrentUser, postStore.isLoading, postStore.myPosts.isEmpty {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(TradeTheme.ink)
                    Text("Loading posts")
                        .font(.seek(size: 13, weight: .regular))
                        .foregroundStyle(TradeTheme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            } else if isCurrentUser, !postStore.myPosts.isEmpty {
                ForEach(postStore.myPosts) { post in
                    RealPostCard(post: post)
                }
            } else if posts.isEmpty {
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
        .task {
            guard isCurrentUser else { return }
            await postStore.loadMyPosts()
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
    @EnvironmentObject private var tradeStore: TradeStore
    @State private var selectedTrade: SeekTradeCandidate?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Verified")
                        .font(.seek(size: 14, weight: .bold))
                        .foregroundStyle(TradeTheme.ink)
                    Text(subtitle)
                        .font(.seek(size: 12, weight: .regular))
                        .foregroundStyle(TradeTheme.muted)
                }
                Spacer()
                Button {
                    Task { await tradeStore.syncAllAccounts() }
                } label: {
                    ZStack {
                        Circle()
                            .fill(TradeTheme.tile)
                            .frame(width: 32, height: 32)
                        if tradeStore.isLoading {
                            ProgressView()
                                .controlSize(.mini)
                                .tint(TradeTheme.ink)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(TradeTheme.ink)
                        }
                    }
                }
                .buttonStyle(.plain)
                .disabled(tradeStore.isLoading)
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 10)

            if let errorText = tradeStore.errorText {
                ProfileSyncMessage(
                    icon: "exclamationmark.circle",
                    title: "Sync failed",
                    message: cleanSyncMessage(errorText),
                    tint: TradeTheme.loss
                )
            } else if tradeStore.isLoading && tradeStore.trades.isEmpty {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(TradeTheme.ink)
                    Text("Loading verified trades")
                        .font(.seek(size: 13, weight: .regular))
                        .foregroundStyle(TradeTheme.muted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
            } else if tradeStore.trades.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    ForEach(tradeStore.trades) { trade in
                        Button {
                            selectedTrade = trade
                        } label: {
                            ProfileTradeRow(trade: trade)
                        }
                        .buttonStyle(.plain)
                        Rectangle()
                            .fill(TradeTheme.line)
                            .frame(height: 1)
                            .padding(.leading, 18)
                    }
                }
                .overlay(alignment: .top) {
                    Rectangle()
                        .fill(TradeTheme.line)
                        .frame(height: 1)
                }
            }
        }
        .task {
            await tradeStore.load()
        }
        .sheet(item: $selectedTrade) { trade in
            VerifiedTradeDetailSheet(trade: trade, syncedAt: tradeStore.lastSyncedAt)
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        }
    }

    private var subtitle: String {
        if tradeStore.isLoading {
            return tradeStore.trades.isEmpty ? "Syncing brokerage data" : "Refreshing verified trades"
        }
        if tradeStore.errorText != nil {
            return "Could not refresh"
        }
        if let lastSyncedAt = tradeStore.lastSyncedAt {
            return "Updated \(lastSyncedAt.relativeSyncText)"
        }
        return tradeStore.trades.isEmpty ? "Synced trades will show here" : "\(tradeStore.trades.count) synced trades"
    }

    private var emptyState: some View {
        ProfileEmptyState(
            icon: "chart.line.uptrend.xyaxis",
            title: "No verified trades",
            message: "Connect a brokerage in Settings to sync verified positions."
        )
    }

    private func cleanSyncMessage(_ raw: String) -> String {
        if raw.localizedCaseInsensitiveContains("bearer") ||
            raw.localizedCaseInsensitiveContains("401") ||
            raw.localizedCaseInsensitiveContains("session") {
            return "Sign in again, then refresh verified trades."
        }
        if raw.count > 96 {
            return "Could not refresh verified trades. Check your connection and try again."
        }
        return raw
    }
}

private struct ProfileSyncMessage: View {
    let icon: String
    let title: String
    let message: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.seek(size: 15, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 20, height: 20)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.seek(size: 13, weight: .bold))
                    .foregroundStyle(TradeTheme.ink)
                Text(message)
                    .font(.seek(size: 12, weight: .regular))
                    .foregroundStyle(TradeTheme.muted)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(TradeTheme.paper)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(TradeTheme.line)
                .frame(height: 1)
        }
    }
}

private struct ProfileEmptyState: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.seek(size: 25, weight: .regular))
                .foregroundStyle(TradeTheme.tertiary.opacity(0.78))
            VStack(spacing: 4) {
                Text(title)
                    .font(.seek(size: 14, weight: .bold))
                    .foregroundStyle(TradeTheme.ink)
                Text(message)
                    .font(.seek(size: 13, weight: .regular))
                    .foregroundStyle(TradeTheme.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 34)
        .padding(.vertical, 54)
        .background(TradeTheme.paper)
    }
}

private extension Date {
    var relativeSyncText: String {
        let elapsed = max(0, Int(Date().timeIntervalSince(self)))
        if elapsed < 60 {
            return "just now"
        }
        let minutes = elapsed / 60
        if minutes < 60 {
            return "\(minutes)m ago"
        }
        let hours = minutes / 60
        if hours < 24 {
            return "\(hours)h ago"
        }
        let days = hours / 24
        return "\(days)d ago"
    }
}

private struct ProfileTradeRow: View {
    let trade: SeekTradeCandidate

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(trade.symbol ?? "UNKNOWN")
                        .font(.seek(size: 15, weight: .bold))
                        .foregroundStyle(TradeTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.76)
                    sidePill
                    statusPill
                }

                Text(instrumentText)
                    .font(.seek(size: 11, weight: .regular))
                    .foregroundStyle(TradeTheme.muted)
                    .lineLimit(1)
            }

            Spacer(minLength: 10)

            HStack(alignment: .center, spacing: 18) {
                tradeMetric("Entry", entryText)
                tradeMetric(trade.status.lowercased() == "closed" ? "Exit" : "Mark", activePriceText)
                tradeMetric("P/L", pnlText, tint: pnlTint, alignment: .trailing)
            }
            .frame(width: 205, alignment: .trailing)

            Image(systemName: "chevron.right")
                .font(.seek(size: 11, weight: .semibold))
                .foregroundStyle(TradeTheme.tertiary)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 11)
        .background(TradeTheme.paper)
        .contentShape(Rectangle())
    }

    private var sidePill: some View {
        Text(trade.side.uppercased())
            .font(.seek(size: 9, weight: .bold))
            .foregroundStyle(trade.side.lowercased() == "sell" || trade.side.lowercased() == "short" ? TradeTheme.loss : TradeTheme.gain)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(TradeTheme.tile)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var statusPill: some View {
        Text(trade.status.capitalized)
            .font(.seek(size: 9, weight: .bold))
            .foregroundStyle(trade.status.lowercased() == "open" ? TradeTheme.gain : TradeTheme.muted)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(TradeTheme.tile)
            .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var instrumentText: String {
        trade.instrumentName ?? trade.providerSourceType.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private var entryText: String {
        trade.entryPrice?.currencyText ?? "-"
    }

    private var activePriceText: String {
        if trade.status.lowercased() == "closed" {
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

    private func tradeMetric(
        _ label: String,
        _ value: String,
        tint: Color = TradeTheme.ink,
        alignment: HorizontalAlignment = .leading
    ) -> some View {
        VStack(alignment: alignment, spacing: 3) {
            Text(label)
                .font(.seek(size: 9, weight: .semibold))
                .foregroundStyle(TradeTheme.muted)
            Text(value)
                .font(.seek(size: 12, weight: .bold).monospacedDigit())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: alignment == .trailing ? .trailing : .leading)
    }
}

private struct VerifiedTradeDetailSheet: View {
    let trade: SeekTradeCandidate
    let syncedAt: Date?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 8) {
                        Text(trade.symbol ?? "UNKNOWN")
                            .font(.seek(size: 24, weight: .bold))
                            .foregroundStyle(TradeTheme.ink)
                            .lineLimit(1)
                        Text(trade.status.capitalized)
                            .font(.seek(size: 10, weight: .bold))
                            .foregroundStyle(trade.status.lowercased() == "open" ? TradeTheme.gain : TradeTheme.muted)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 4)
                            .background(TradeTheme.tile)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    Text(instrumentText)
                        .font(.seek(size: 13, weight: .regular))
                        .foregroundStyle(TradeTheme.muted)
                        .lineLimit(2)
                }

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.seek(size: 12, weight: .bold))
                        .foregroundStyle(TradeTheme.ink)
                        .frame(width: 32, height: 32)
                        .background(TradeTheme.tile)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 18)

            VStack(spacing: 0) {
                detailRow("Side", trade.side.capitalized, tint: sideTint)
                detailRow("Quantity", quantityText)
                detailRow("Entry", trade.entryPrice?.currencyText ?? "-")
                detailRow(trade.status.lowercased() == "closed" ? "Exit" : "Mark", activePriceText)
                detailRow("Return", pnlText, tint: pnlTint)
                detailRow("Source", trade.providerSourceType.replacingOccurrences(of: "_", with: " ").capitalized)
                if let syncedAt {
                    detailRow("Synced", syncedAt.relativeSyncText)
                }
            }
            .background(TradeTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(TradeTheme.line, lineWidth: 1)
            )
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(TradeTheme.paper.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }

    private var instrumentText: String {
        trade.instrumentName ?? trade.providerSourceType.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private var quantityText: String {
        guard let quantity = trade.quantity else { return "-" }
        if quantity.rounded() == quantity {
            return "\(Int(quantity))"
        }
        return String(format: "%.2f", quantity)
    }

    private var activePriceText: String {
        if trade.status.lowercased() == "closed" {
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

    private var sideTint: Color {
        trade.side.lowercased() == "sell" || trade.side.lowercased() == "short" ? TradeTheme.loss : TradeTheme.gain
    }

    private func detailRow(_ label: String, _ value: String, tint: Color = TradeTheme.ink) -> some View {
        HStack {
            Text(label)
                .font(.seek(size: 13, weight: .regular))
                .foregroundStyle(TradeTheme.muted)
            Spacer()
            Text(value)
                .font(.seek(size: 13, weight: .bold).monospacedDigit())
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .padding(.horizontal, 14)
        .frame(height: 46)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TradeTheme.line)
                .frame(height: 1)
                .padding(.leading, 14)
        }
    }
}
