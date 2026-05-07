//
//  FeedView.swift
//  tradetogether
//
//  Created by Codex on 05/05/26.
//

import SwiftUI

struct FeedView: View {
    let store: DemoStore
    @State private var selectedTab: FeedTab = .posts
    @State private var selectedStockID: StockInstrument.ID?
    @State private var selectedProfileID: TraderProfile.ID?

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
            WSJMasthead()
                .zIndex(2)

            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        postList
                    } header: {
                        stickyFeedHeader
                    }
                }
            }
        }
        .background(TradeTheme.paper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
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
    }

    private var followingSectionHeader: some View {
        HStack(spacing: 6) {
            Text("Recommended")
                .font(.headline)
                .foregroundStyle(TradeTheme.ink)
            Image(systemName: "chevron.down")
                .font(.caption.weight(.bold))
                .foregroundStyle(TradeTheme.ink)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 6)
        .background(TradeTheme.paper)
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
                    .font(.system(size: initials == "..." ? 16 : 13, weight: .black))
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
                                .font(.system(size: 13))
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
                .font(.system(size: symbol == "*" ? 17 : 13, weight: .black))
                .foregroundStyle(symbol == "*" ? TradeTheme.ink : .white)
        }
    }
}

struct MarketOverviewTile: View {
    let stock: StockInstrument

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("CLOSED")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(TradeTheme.muted)
            Text(stock.symbol)
                .font(.headline.weight(.bold))
                .foregroundStyle(TradeTheme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.74)
            Spacer(minLength: 2)
            Text(stock.price.cleanPrice)
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(stock.changePercent >= 0 ? TradeTheme.gain : TradeTheme.loss)
            HStack(spacing: 5) {
                Text(stock.changePercent.percentText)
                    .font(.subheadline.monospacedDigit().weight(.semibold))
                Image(systemName: "triangle.fill")
                    .font(.system(size: 9, weight: .bold))
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

    var body: some View {
        let author = store.profile(id: post.authorID)
        let stock = store.stock(id: post.stockID)

        VStack(spacing: 0) {
            postTopNav

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    detailedPost(author: author, stock: stock)

                    HStack(spacing: 0) {
                        PostActionButton(title: "\(post.votes)", icon: "heart")
                        PostActionButton(title: "\(post.comments)", icon: "bubble.left")
                        PostActionButton(title: "", icon: "arrow.2.squarepath")
                        PostActionButton(title: "", icon: "paperplane")
                    }
                    .padding(.vertical, 8)
                    .background(TradeTheme.paper)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(TradeTheme.line)
                            .frame(height: 1)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        NavigationLink {
                            StockDetailView(stock: stock, store: store)
                        } label: {
                            Label("Open Quote", systemImage: "chart.xyaxis.line")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(TradeTheme.brandBlue)
                        .foregroundStyle(.white)

                        NavigationLink {
                            ProfileView(profile: author, posts: store.posts(for: author), store: store)
                        } label: {
                            Label("Profile", systemImage: "person")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(TradeTheme.brandBlue)
                    }
                    .padding(20)

                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader(title: post.status.isClosed ? "Closed Trade" : "Open Trade", subtitle: tradePlanSubtitle(stock: stock))
                        HStack(spacing: 8) {
                            MetricPill(title: "Entry", value: price(post.entry, stock: stock))
                            MetricPill(title: post.status.isClosed ? "Exit" : "Target", value: post.status.isClosed ? exitPrice(stock: stock) : price(post.target, stock: stock), tint: post.status.isClosed ? resultColor(stock: stock) : TradeTheme.gain)
                            MetricPill(title: post.status.isClosed ? "Result" : "Stop", value: post.status.isClosed ? post.status.rawValue : price(post.stop, stock: stock), tint: post.status.isClosed ? resultColor(stock: stock) : TradeTheme.loss)
                        }
                    }
                    .padding(20)
                    .background(TradeTheme.panel)
                }
            }
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
                    .font(.system(size: 19, weight: .semibold))
                    .foregroundStyle(TradeTheme.ink)
                    .frame(width: 44, height: 44, alignment: .leading)
            }
            .buttonStyle(TradePressableStyle())

            Spacer()
            Text("Post")
                .font(.tradeScreenTitle)
                .foregroundStyle(TradeTheme.ink)
            Spacer()
            Image(systemName: "ellipsis")
                .font(.system(size: 18))
                .foregroundStyle(TradeTheme.ink)
                .frame(width: 44, height: 44, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 2)
        .background(TradeTheme.paper)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TradeTheme.line)
                .frame(height: 1)
        }
    }

    private func detailedPost(author: TraderProfile, stock: StockInstrument) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                TraderAvatar(profile: author, size: 40)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(author.handle)
                            .font(.tradeDisplayName)
                            .foregroundStyle(TradeTheme.ink)
                        Text("(WR: \(winRateText(author)))")
                            .font(.tradeActionCount.weight(.semibold))
                            .foregroundStyle(TradeTheme.gain)
                        Text(post.postedAgo)
                            .font(.tradeHandle)
                            .foregroundStyle(TradeTheme.muted)
                    }
                    Text(tradeHeadline(stock: stock))
                        .font(.tradeHandle.weight(.semibold))
                        .foregroundStyle(TradeTheme.ink)
                }
                Spacer()
                Image(systemName: "ellipsis")
                    .font(.system(size: 18))
                    .foregroundStyle(TradeTheme.muted)
            }

            Text("\(post.title). \(post.thesis)")
                .font(.tradePostBody)
                .lineSpacing(5)
                .foregroundStyle(TradeTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            TradeTicketView(post: post, stock: stock)

            Text("12:36 PM - \(post.postedAgo) - Seek for iOS")
                .font(.subheadline)
                .foregroundStyle(TradeTheme.muted)

            HStack(spacing: 12) {
                Text("\(post.votes)")
                    .font(.headline.monospacedDigit().weight(.bold))
                    .foregroundStyle(TradeTheme.ink)
                Text("Reposts")
                    .foregroundStyle(TradeTheme.muted)
                Text("\(post.comments)")
                    .font(.headline.monospacedDigit().weight(.bold))
                    .foregroundStyle(TradeTheme.ink)
                Text("Replies")
                    .foregroundStyle(TradeTheme.muted)
            }
            .font(.subheadline)
        }
        .padding(20)
        .background(TradeTheme.paper)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TradeTheme.line)
                .frame(height: 1)
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
        .font(.system(size: 13, weight: .regular))
        .foregroundStyle(TradeTheme.muted)
        .frame(maxWidth: .infinity)
    }
}
