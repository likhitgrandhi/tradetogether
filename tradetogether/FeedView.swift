//
//  FeedView.swift
//  tradetogether
//
//  Created by Codex on 05/05/26.
//

import SwiftUI
import UIKit

struct FeedView: View {
    let store: DemoStore
    @EnvironmentObject private var postStore: PostStore
    @State private var selectedTab: FeedTab = .posts
    @State private var selectedStockID: StockInstrument.ID?
    @State private var selectedProfileID: TraderProfile.ID?
    @State private var pullDistance: CGFloat = 0
    @State private var isRefreshing = false
    @State private var didPrimeRefreshHaptic = false

    private let refreshThreshold: CGFloat = 86
    private var logoPullProgress: CGFloat {
        isRefreshing ? 1 : min(max(pullDistance / refreshThreshold, 0), 1)
    }

    private var visiblePosts: [TradeIdea] {
        switch selectedTab {
        case .posts:
            return store.posts
        case .byStock:
            guard let selectedStockID else { return store.posts }
            return store.posts.filter { $0.stockID == selectedStockID }
        case .following:
            guard let selectedProfileID else { return store.posts }
            return store.posts.filter { $0.authorID == selectedProfileID }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            WSJMasthead(logoPullProgress: logoPullProgress, isRefreshing: isRefreshing)
                .zIndex(2)

            ScrollView {
                GeometryReader { proxy in
                    Color.clear
                        .preference(
                            key: FeedPullDistancePreferenceKey.self,
                            value: max(proxy.frame(in: .named("FeedScroll")).minY, 0)
                        )
                }
                .frame(height: 0)

                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        postList
                    } header: {
                        stickyFeedHeader
                    }
                }
            }
            .interactiveKeyboardDismissal()
            .coordinateSpace(name: "FeedScroll")
            .refreshable {
                await performRefresh()
            }
            .onPreferenceChange(FeedPullDistancePreferenceKey.self) { value in
                pullDistance = value
                if value >= refreshThreshold, !didPrimeRefreshHaptic {
                    didPrimeRefreshHaptic = true
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }
                if value < 6, !isRefreshing {
                    didPrimeRefreshHaptic = false
                }
            }
        }
        .background(TradeTheme.paper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func performRefresh() async {
        await MainActor.run {
            isRefreshing = true
            pullDistance = refreshThreshold
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        try? await Task.sleep(for: .milliseconds(650))
        await postStore.loadFeed()
        await MainActor.run {
            isRefreshing = false
            pullDistance = 0
            didPrimeRefreshHaptic = false
        }
    }

    private var stickyFeedHeader: some View {
        VStack(spacing: 0) {
            primaryTabs
            if selectedTab == .byStock {
                watchlistStockRail
            }
            if selectedTab == .following {
                followingCreatorRail
            }
        }
        .background(TradeTheme.paper)
    }

    private var primaryTabs: some View {
        HStack(spacing: 0) {
            ForEach(FeedTab.allCases) { tab in
                Button {
                    withAnimation(.snappy) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 10) {
                        Text(tab.title)
                            .font(.tradeFilterChip)
                            .foregroundStyle(selectedTab == tab ? TradeTheme.ink : TradeTheme.muted)
                        Rectangle()
                            .fill(selectedTab == tab ? TradeTheme.ink : Color.clear)
                            .frame(height: 2)
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 0)
        .background(TradeTheme.paper)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TradeTheme.line)
                .frame(height: 1)
        }
    }

    private var watchlistStockRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                StockRailItem(
                    title: "All",
                    symbol: "*",
                    color: TradeTheme.muted.opacity(0.18),
                    isSelected: selectedStockID == nil
                ) {
                    withAnimation(.snappy) {
                        selectedStockID = nil
                    }
                }

                ForEach(store.stocks.prefix(4)) { stock in
                    StockRailItem(
                        title: stock.symbol,
                        symbol: stockSymbolTitle(stock.symbol),
                        color: AvatarColor.color(for: stock.id),
                        isSelected: selectedStockID == stock.id
                    ) {
                        withAnimation(.snappy) {
                            selectedStockID = stock.id
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 14)
        }
        .background(TradeTheme.paper)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TradeTheme.line)
                .frame(height: 1)
        }
    }

    private var followingCreatorRail: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 12) {
                ForEach(store.profiles.prefix(4)) { profile in
                    CreatorRailItem(
                        title: creatorDisplayName(profile),
                        initials: profile.initials,
                        color: AvatarColor.color(for: profile.id),
                        isSelected: selectedProfileID == profile.id,
                        showsBadge: true
                    ) {
                        withAnimation(.snappy) {
                            selectedProfileID = profile.id
                        }
                    }
                }

                CreatorRailItem(
                    title: "Following",
                    initials: "...",
                    color: TradeTheme.muted.opacity(0.18),
                    isSelected: selectedProfileID == nil,
                    showsBadge: false
                ) {
                    withAnimation(.snappy) {
                        selectedProfileID = nil
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 16)
        }
        .background(TradeTheme.paper)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TradeTheme.line)
                .frame(height: 1)
        }
    }

    private func stockSymbolTitle(_ symbol: String) -> String {
        String(symbol.prefix(2))
    }

    private func creatorDisplayName(_ profile: TraderProfile) -> String {
        let name = profile.name
        return name.count > 10 ? "\(name.prefix(9))..." : name
    }

    private var postList: some View {
        VStack(alignment: .leading, spacing: 0) {
            if selectedTab == .following {
                followingSectionHeader
            }
            if selectedTab == .posts {
                if postStore.isLoading && postStore.feedPosts.isEmpty {
                    realPostLoadingRow
                }
                ForEach(postStore.feedPosts) { post in
                    RealPostCard(post: post)
                }
            }
            ForEach(visiblePosts) { post in
                NavigationLink {
                    PostDetailView(post: post, store: store)
                } label: {
                    let author = store.profile(id: post.authorID)
                    TradeIdeaCard(post: post, author: author, stock: store.stock(id: post.stockID), stats: TradeMetrics.stats(for: author, posts: store.posts(for: author)))
                }
                .buttonStyle(.plain)
            }
        }
        .background(TradeTheme.paper)
        .task {
            await postStore.loadFeed()
        }
    }

    private var realPostLoadingRow: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(TradeTheme.ink)
            Text("Loading posts")
                .font(.seek(size: 13, weight: .regular))
                .foregroundStyle(TradeTheme.muted)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TradeTheme.paper)
    }

    private var followingSectionHeader: some View {
        HStack(spacing: 6) {
            Text("Recommended")
                .font(.seek(size: 17, weight: .regular))
                .foregroundStyle(TradeTheme.ink)
            Image(systemName: "chevron.down")
                .font(.seek(size: 12, weight: .bold))
                .foregroundStyle(TradeTheme.ink)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 6)
        .background(TradeTheme.paper)
    }
}

struct RealPostCard: View {
    let post: GrowHousePost

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                realAvatar
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.author.displayName)
                        .font(.seek(size: 14, weight: .bold))
                        .foregroundStyle(TradeTheme.ink)
                        .lineLimit(1)
                    Text("\(post.author.handle) - \(relativeCreatedAt)")
                        .font(.seek(size: 12, weight: .regular))
                        .foregroundStyle(TradeTheme.muted)
                        .lineLimit(1)
                }
                Spacer()
                if post.verifiedTrade != nil {
                    Text("Verified trade")
                        .font(.seek(size: 10, weight: .bold))
                        .foregroundStyle(TradeTheme.verified)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(TradeTheme.tile)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                }
            }

            Text(post.body)
                .font(.seek(size: 15, weight: .regular))
                .foregroundStyle(TradeTheme.ink)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if let verifiedTrade = post.verifiedTrade {
                verifiedTradeSummary(verifiedTrade)
            }

            HStack(spacing: 22) {
                postAction("bubble.left", "0")
                postAction("arrow.2.squarepath", "0")
                postAction("hand.thumbsup", "0")
                Spacer()
                Image(systemName: "arrowshape.turn.up.right")
                    .font(.seek(size: 17, weight: .regular))
                    .foregroundStyle(TradeTheme.muted)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(TradeTheme.paper)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TradeTheme.line)
                .frame(height: 1)
        }
    }

    private var realAvatar: some View {
        ZStack {
            Circle()
                .fill(AvatarColor.color(for: post.author.id))
            Text(authorInitials)
                .font(.seek(size: 12, weight: .black))
                .foregroundStyle(.white)
        }
        .frame(width: 36, height: 36)
    }

    private var authorInitials: String {
        let pieces = post.author.displayName.split(separator: " ")
        if pieces.count > 1 {
            return pieces.prefix(2).compactMap { $0.first }.map(String.init).joined().uppercased()
        }
        return String(post.author.displayName.prefix(2)).uppercased()
    }

    private var relativeCreatedAt: String {
        PostDateFormatter.relativeText(from: post.createdAt)
    }

    private func verifiedTradeSummary(_ trade: GrowHousePostVerifiedTrade) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 7) {
                    Text(trade.symbol ?? "UNKNOWN")
                        .font(.seek(size: 14, weight: .bold))
                        .foregroundStyle(TradeTheme.ink)
                    Text(trade.side.uppercased())
                        .font(.seek(size: 9, weight: .bold))
                        .foregroundStyle(sideTint(trade))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(TradeTheme.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                Text(trade.instrumentName ?? trade.providerSourceType.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.seek(size: 11, weight: .regular))
                    .foregroundStyle(TradeTheme.muted)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(pnlText(trade))
                    .font(.seek(size: 14, weight: .bold).monospacedDigit())
                    .foregroundStyle(pnlTint(trade))
                Text("Entry \(trade.entryPrice?.currencyText ?? "-")")
                    .font(.seek(size: 11, weight: .regular))
                    .foregroundStyle(TradeTheme.muted)
            }
        }
        .padding(12)
        .background(TradeTheme.tile)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func postAction(_ icon: String, _ count: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.seek(size: 17, weight: .regular))
            Text(count)
                .font(.seek(size: 12, weight: .regular).monospacedDigit())
        }
        .foregroundStyle(TradeTheme.muted)
    }

    private func sideTint(_ trade: GrowHousePostVerifiedTrade) -> Color {
        trade.side.lowercased() == "sell" || trade.side.lowercased() == "short" ? TradeTheme.loss : TradeTheme.gain
    }

    private func pnlTint(_ trade: GrowHousePostVerifiedTrade) -> Color {
        let value = trade.returnPercent ?? trade.unrealizedPnl ?? trade.realizedPnl ?? 0
        return value >= 0 ? TradeTheme.gain : TradeTheme.loss
    }

    private func pnlText(_ trade: GrowHousePostVerifiedTrade) -> String {
        if let returnPercent = trade.returnPercent {
            return returnPercent.percentText
        }
        if let unrealizedPnl = trade.unrealizedPnl {
            return unrealizedPnl.currencyText
        }
        if let realizedPnl = trade.realizedPnl {
            return realizedPnl.currencyText
        }
        return "Verified"
    }
}

enum PostDateFormatter {
    static func relativeText(from isoString: String) -> String {
        guard let date = isoFormatter.date(from: isoString) ?? fallbackFormatter.date(from: isoString) else {
            return "now"
        }
        let elapsed = max(0, Int(Date().timeIntervalSince(date)))
        if elapsed < 60 { return "now" }
        let minutes = elapsed / 60
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h" }
        return "\(hours / 24)d"
    }

    private static let isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let fallbackFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}

private struct FeedPullDistancePreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

enum FeedTab: String, CaseIterable, Identifiable {
    case posts
    case byStock
    case following

    var id: String { rawValue }

    var title: String {
        switch self {
        case .posts: "Discover"
        case .byStock: "Watchlist"
        case .following: "Following"
        }
    }
}

struct FilterChipRow<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                content
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 20)
        }
        .background(TradeTheme.paper)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TradeTheme.line)
                .frame(height: 1)
        }
    }
}

struct CircleFilterChip: View {
    let title: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.tradeFilterChip)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .foregroundStyle(isSelected ? TradeTheme.paper : TradeTheme.ink)
                .padding(.horizontal, 16)
                .frame(minWidth: 64, minHeight: 36)
                .background(
                    Capsule().fill(isSelected ? TradeTheme.ink : Color.clear)
                )
                .overlay {
                    Capsule()
                        .stroke(isSelected ? Color.clear : TradeTheme.line, lineWidth: 1)
                }
        }
        .buttonStyle(TradePressableStyle())
    }
}

struct CreatorRailItem: View {
    let title: String
    let initials: String
    let color: Color
    let isSelected: Bool
    let showsBadge: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(initials)
                    .font(.seek(size: initials == "..." ? 16 : 13, weight: .black))
                    .foregroundStyle(initials == "..." ? TradeTheme.ink : .white)
                    .frame(width: 44, height: 44)
                    .background(color)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(isSelected ? TradeTheme.ink : Color.clear, lineWidth: 2)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        if showsBadge {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.seek(size: 13))
                                .foregroundStyle(TradeTheme.verified)
                                .background(Circle().fill(TradeTheme.paper).frame(width: 11, height: 11))
                                .offset(x: 2, y: 2)
                        }
                    }

                Text(title)
                    .font(.tradeHandle)
                    .foregroundStyle(TradeTheme.ink)
                    .lineLimit(1)
                    .frame(width: 58)
            }
        }
        .buttonStyle(.plain)
    }
}

struct StockRailItem: View {
    let title: String
    let symbol: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                stockLogo
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(isSelected ? TradeTheme.ink : Color.clear, lineWidth: 2)
                    }

                Text(title)
                    .font(.tradeHandle)
                    .foregroundStyle(TradeTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                    .frame(width: 62)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var stockLogo: some View {
        ZStack {
            Circle()
                .fill(symbol == "*" ? TradeTheme.tile : color)
            Circle()
                .fill(.white.opacity(symbol == "*" ? 0 : 0.16))
                .frame(width: 25, height: 25)
                .offset(x: 8, y: -8)
            Text(symbol)
                .font(.seek(size: symbol == "*" ? 17 : 13, weight: .black))
                .foregroundStyle(symbol == "*" ? TradeTheme.ink : .white)
        }
    }
}

struct MarketOverviewTile: View {
    let stock: StockInstrument

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("CLOSED")
                .font(.seek(size: 10, weight: .bold))
                .foregroundStyle(TradeTheme.muted)
            Text(stock.symbol)
                .font(.seek(size: 17, weight: .bold))
                .foregroundStyle(TradeTheme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.74)
            Spacer(minLength: 2)
            Text(stock.price.cleanPrice)
                .font(.seek(size: 15, weight: .semibold).monospacedDigit())
                .foregroundStyle(stock.changePercent >= 0 ? TradeTheme.gain : TradeTheme.loss)
            HStack(spacing: 5) {
                Text(stock.changePercent.percentText)
                    .font(.seek(size: 15, weight: .semibold).monospacedDigit())
                Image(systemName: "triangle.fill")
                    .font(.seek(size: 9, weight: .bold))
                    .rotationEffect(stock.changePercent >= 0 ? .zero : .degrees(180))
            }
            .foregroundStyle(stock.changePercent >= 0 ? TradeTheme.gain : TradeTheme.loss)
        }
        .frame(height: 110, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(TradeTheme.tile)
    }
}

struct PostDetailView: View {
    let post: TradeIdea
    let store: DemoStore
    @Environment(\.dismiss) private var dismiss
    @State private var isCommentComposerOpen = false
    @State private var commentDraft = ""
    @FocusState private var isCommentFocused: Bool

    var body: some View {
        let author = store.profile(id: post.authorID)
        let stock = store.stock(id: post.stockID)

        VStack(spacing: 0) {
            postTopNav

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    detailedPost(author: author, stock: stock)
                    repliesList
                }
            }
            .interactiveKeyboardDismissal()
            .dismissKeyboardOnBackgroundTap()

            composerBar
        }
        .background(TradeTheme.paper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var postTopNav: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.seek(size: 19, weight: .semibold))
                    .foregroundStyle(TradeTheme.ink)
                    .frame(width: 44, height: 44, alignment: .leading)
            }
            .buttonStyle(TradePressableStyle())

            Spacer()
            HStack(spacing: 18) {
                Image(systemName: "ellipsis")
                    .font(.seek(size: 18, weight: .semibold))
                    .foregroundStyle(TradeTheme.ink)
            }
            .frame(width: 44, height: 44, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 2)
        .background(TradeTheme.paper)
    }

    private func detailedPost(author: TraderProfile, stock: StockInstrument) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 12) {
                NavigationLink {
                    ProfileView(profile: author, posts: store.posts(for: author), store: store)
                } label: {
                    TraderAvatar(profile: author, size: 40)
                }
                .buttonStyle(TradePressableStyle())

                Text(author.handle)
                    .font(.seek(size: 17, weight: .bold))
                    .foregroundStyle(TradeTheme.ink)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Button {} label: {
                    Text("Follow")
                        .font(.seek(size: 14, weight: .bold))
                        .foregroundStyle(TradeTheme.paper)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(RoundedRectangle(cornerRadius: 8).fill(TradeTheme.ink))
                }
                .buttonStyle(TradePressableStyle())
            }

            Text("\(post.title). \(post.thesis)")
                .font(.seek(size: 15, weight: .regular))
                .lineSpacing(4)
                .foregroundStyle(TradeTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            NavigationLink {
                StockDetailView(stock: stock, store: store)
            } label: {
                Text("See original")
                    .font(.seek(size: 14, weight: .semibold))
                    .foregroundStyle(TradeTheme.chartBlue)
            }
            .buttonStyle(TradePressableStyle())

            TradeTicketView(post: post, stock: stock)

            Text("Disclaimer: Includes third-party opinions. No financial advice. May include sponsored content. See T&Cs.")
                .font(.seek(size: 12, weight: .regular))
                .lineSpacing(3)
                .foregroundStyle(TradeTheme.muted)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                Text(detailTimestamp)
                    .foregroundStyle(TradeTheme.muted)
                Text("82.4K")
                    .fontWeight(.bold)
                    .foregroundStyle(TradeTheme.ink)
                Text("Views")
                    .foregroundStyle(TradeTheme.muted)
            }
            .font(.seek(size: 15, weight: .regular))

            detailActionRow
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .padding(.bottom, 18)
        .background(TradeTheme.paper)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TradeTheme.line)
                .frame(height: 1)
        }
    }

    private var detailActionRow: some View {
        HStack(spacing: 0) {
            detailAction(icon: "bubble.left", title: "\(post.comments)")
            detailAction(icon: "arrow.2.squarepath", title: "0")
            detailAction(icon: "hand.thumbsup", title: "\(post.votes)")
            detailAction(icon: "chart.bar", title: "6")
            detailAction(icon: "arrowshape.turn.up.right", title: "4")
        }
        .padding(.top, 2)
    }

    private func detailAction(icon: String, title: String) -> some View {
        HStack(spacing: 7) {
            Image(systemName: icon)
                .font(.seek(size: 22, weight: .regular))
            Text(title)
                .font(.seek(size: 13, weight: .regular))
                .monospacedDigit()
        }
        .foregroundStyle(TradeTheme.muted)
        .frame(maxWidth: .infinity)
    }

    private var repliesList: some View {
        VStack(spacing: 0) {
            PostReplyRow(
                initials: "SR",
                name: "Sofia Reyes",
                time: "May 7",
                text: "Nice plan. I would watch whether the bid stays above entry after the first thirty minutes.",
                likes: 3
            )
            PostReplyRow(
                initials: "AR",
                name: "Arjun Rao",
                time: "2h",
                text: "Clean risk box. The stop makes sense if volume dries up near the level.",
                likes: 1
            )
        }
        .background(TradeTheme.paper)
    }

    private var composerBar: some View {
        VStack(spacing: 10) {
            if isCommentComposerOpen {
                VStack(alignment: .leading, spacing: 10) {
                    TextField("Comment", text: $commentDraft, axis: .vertical)
                        .font(.seek(size: 15, weight: .regular))
                        .foregroundStyle(TradeTheme.ink)
                        .lineLimit(2...5)
                        .padding(.vertical, 6)
                        .focused($isCommentFocused)

                    HStack(spacing: 12) {
                        Button("Cancel") {
                            closeCommentComposer()
                        }
                        .font(.seek(size: 14, weight: .semibold))
                        .foregroundStyle(TradeTheme.muted)
                        .buttonStyle(TradePressableStyle())

                        Spacer()

                        Button {
                            closeCommentComposer(clearDraft: true)
                        } label: {
                            Text("Post")
                                .font(.seek(size: 14, weight: .bold))
                                .foregroundStyle(commentDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? TradeTheme.muted : TradeTheme.paper)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(commentDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? TradeTheme.tile : TradeTheme.ink)
                                )
                        }
                        .disabled(commentDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .buttonStyle(TradePressableStyle())
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 12)
                .padding(.bottom, 12)
            } else {
                HStack(spacing: 14) {
                    Button {
                        openCommentComposer()
                    } label: {
                        Text("Comment")
                            .font(.seek(size: 15, weight: .regular))
                            .foregroundStyle(TradeTheme.muted)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .frame(height: 44)
                            .background(RoundedRectangle(cornerRadius: 12).fill(TradeTheme.tile))
                    }
                    .buttonStyle(TradePressableStyle())

                    Image(systemName: "bubble.left")
                    Image(systemName: "arrow.2.squarepath")
                    Image(systemName: "hand.thumbsup")
                    Image(systemName: "arrowshape.turn.up.right")
                }
                .font(.seek(size: 21, weight: .regular))
                .foregroundStyle(TradeTheme.muted)
                .padding(.horizontal, 22)
                .padding(.top, 10)
                .padding(.bottom, 12)
            }
        }
        .frame(maxWidth: .infinity)
        .background {
            Group {
                if isCommentComposerOpen {
                    TradeTheme.tile
                        .ignoresSafeArea(.container, edges: .bottom)
                } else {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .ignoresSafeArea(.container, edges: .bottom)
                }
            }
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(TradeTheme.line)
                .frame(height: 1)
        }
    }

    private func openCommentComposer() {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.86)) {
            isCommentComposerOpen = true
        }
        isCommentFocused = true
    }

    private func closeCommentComposer(clearDraft: Bool = false) {
        isCommentFocused = false
        if clearDraft {
            commentDraft = ""
        }
        withAnimation(.easeInOut(duration: 0.18)) {
            isCommentComposerOpen = false
        }
    }

    private func winRateText(_ author: TraderProfile) -> String {
        let stats = TradeMetrics.stats(for: author, posts: store.posts(for: author))
        return String(format: "%.1f%%", Double(stats.winRate))
    }

    private func price(_ value: Double, stock: StockInstrument) -> String {
        "\(stock.region == .india ? "Rs " : "$")\(value.cleanPrice)"
    }

    private func tradeHeadline(stock: StockInstrument) -> String {
        let state = post.status.isClosed ? "Closed" : "Opened"
        return "\(state) \(post.direction.rawValue.lowercased()) \(post.product.rawValue.lowercased()) in \(stock.symbol)"
    }

    private var detailTimestamp: String {
        switch post.postedAgo {
        case "18m": "1:39 PM"
        case "44m": "1:13 PM"
        case "2h": "11:57 AM"
        case "3h": "10:44 AM"
        case "1d": "May 8"
        default: "May 7"
        }
    }

    private func tradePlanSubtitle(stock: StockInstrument) -> String {
        if post.status.isClosed {
            return "Entry, exit, and realized result for \(stock.symbol)"
        }
        return "Entry, target, and invalidation for \(stock.symbol)"
    }

    private func exitPrice(stock: StockInstrument) -> String {
        switch post.status {
        case .hitTarget:
            return price(post.target, stock: stock)
        case .stoppedOut:
            return price(post.stop, stock: stock)
        case .thesisChanged:
            return price(stock.price, stock: stock)
        case .active:
            return price(stock.price, stock: stock)
        }
    }

    private func resultColor(stock: StockInstrument) -> Color {
        let value = post.returnPercent ?? stock.changePercent
        return value >= 0 ? TradeTheme.gain : TradeTheme.loss
    }
}

struct PostReplyRow: View {
    let initials: String
    let name: String
    let time: String
    let text: String
    let likes: Int

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(AvatarColor.color(for: name))
                Text(initials)
                    .font(.seek(size: 13, weight: .black))
                    .foregroundStyle(.white)
            }
            .frame(width: 38, height: 38)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(name)
                        .font(.seek(size: 15, weight: .bold))
                        .foregroundStyle(TradeTheme.ink)
                    Text("- \(time)")
                        .font(.seek(size: 14, weight: .regular))
                        .foregroundStyle(TradeTheme.muted)
                    Spacer(minLength: 0)
                    Image(systemName: "ellipsis")
                        .font(.seek(size: 15, weight: .semibold))
                        .foregroundStyle(TradeTheme.muted)
                }

                Text(text)
                    .font(.seek(size: 15, weight: .regular))
                    .lineSpacing(4)
                    .foregroundStyle(TradeTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 38) {
                    Image(systemName: "bubble.left")
                    Image(systemName: "arrow.2.squarepath")
                    HStack(spacing: 5) {
                        Image(systemName: "hand.thumbsup")
                        if likes > 0 {
                            Text("\(likes)")
                                .font(.seek(size: 12, weight: .regular))
                        }
                    }
                    Image(systemName: "chart.bar")
                    Image(systemName: "arrowshape.turn.up.right")
                }
                .font(.seek(size: 16, weight: .regular))
                .foregroundStyle(TradeTheme.muted)
                .padding(.top, 2)
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 16)
        .background(TradeTheme.paper)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TradeTheme.line)
                .frame(height: 1)
        }
    }
}

struct PostActionButton: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
            if !title.isEmpty {
                Text(title)
            }
        }
        .font(.seek(size: 13, weight: .regular))
        .foregroundStyle(TradeTheme.muted)
        .frame(maxWidth: .infinity)
    }
}
