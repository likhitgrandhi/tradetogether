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
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section {
                    postList
                } header: {
                    stickyFeedHeader
                }
            }
        }
        .background(TradeTheme.paper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var stickyFeedHeader: some View {
        VStack(spacing: 0) {
            WSJMasthead()
            primaryTabs
            if selectedTab == .byStock {
                stockFilterRow
            }
            if selectedTab == .following {
                profileFilterRow
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
                            .font(.title3.weight(.bold))
                            .foregroundStyle(selectedTab == tab ? TradeTheme.ink : TradeTheme.muted)
                        Rectangle()
                            .fill(selectedTab == tab ? TradeTheme.ink : Color.clear)
                            .frame(height: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 4)
        .padding(.bottom, 2)
        .background(TradeTheme.paper)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TradeTheme.line)
                .frame(height: 1)
        }
    }

    private var stockFilterRow: some View {
        FilterChipRow {
            FilterChip(title: "All", isSelected: selectedStockID == nil) {
                withAnimation(.snappy) {
                    selectedStockID = nil
                }
            }
            ForEach(store.stocks.prefix(4)) { stock in
                FilterChip(title: stock.symbol, isSelected: selectedStockID == stock.id) {
                    withAnimation(.snappy) {
                        selectedStockID = stock.id
                    }
                }
            }
        }
    }

    private var profileFilterRow: some View {
        FilterChipRow {
            FilterChip(title: "All", isSelected: selectedProfileID == nil) {
                withAnimation(.snappy) {
                    selectedProfileID = nil
                }
            }
            ForEach(store.profiles.prefix(4)) { profile in
                FilterChip(title: profile.initials, isSelected: selectedProfileID == profile.id) {
                    withAnimation(.snappy) {
                        selectedProfileID = profile.id
                    }
                }
            }
        }
    }

    private var postList: some View {
        VStack(alignment: .leading, spacing: 0) {
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
}

enum FeedTab: String, CaseIterable, Identifiable {
    case posts
    case byStock
    case following

    var id: String { rawValue }

    var title: String {
        switch self {
        case .posts: "Posts"
        case .byStock: "By stock"
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

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .foregroundStyle(isSelected ? .white : TradeTheme.brandBlue)
                .padding(.horizontal, 18)
                .frame(minWidth: title == "All" ? 56 : 72, minHeight: 44)
                .background(isSelected ? TradeTheme.brandBlue : TradeTheme.brandBlue.opacity(0.08))
                .overlay {
                    Capsule()
                        .stroke(isSelected ? TradeTheme.brandBlue : TradeTheme.brandBlue.opacity(0.35), lineWidth: 1.5)
                }
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
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

    var body: some View {
        let author = store.profile(id: post.authorID)
        let stock = store.stock(id: post.stockID)

        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                WSJMasthead(showBackHint: true)
                detailedPost(author: author, stock: stock)

                HStack(spacing: 0) {
                    PostActionButton(title: "\(post.comments)", icon: "bubble")
                    PostActionButton(title: "\(post.votes)", icon: "arrow.2.squarepath")
                    PostActionButton(title: "16", icon: "heart")
                    PostActionButton(title: "", icon: "square.and.arrow.up")
                }
                .padding(.vertical, 14)
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
                    SectionHeader(title: "Trade Plan", subtitle: "Entry, timeframe, and invalidation")
                    HStack(spacing: 8) {
                        MetricPill(title: "Entry", value: price(post.entry, stock: stock))
                        MetricPill(title: "Timeframe", value: post.timeframe)
                        MetricPill(title: "Stop", value: price(post.stop, stock: stock), tint: TradeTheme.loss)
                    }
                }
                .padding(20)
                .background(TradeTheme.panel)
            }
        }
        .background(TradeTheme.paper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private func detailedPost(author: TraderProfile, stock: StockInstrument) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 12) {
                TraderAvatar(profile: author, size: 48)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(author.handle.replacingOccurrences(of: "@", with: ""))
                            .font(.headline.weight(.bold))
                            .foregroundStyle(TradeTheme.ink)
                        Text("Winrate: \(winRateText(author))")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(TradeTheme.gain)
                    }
                    Text(author.handle)
                        .font(.subheadline)
                        .foregroundStyle(TradeTheme.muted)
                }
                Spacer()
                Image(systemName: "ellipsis")
                    .font(.headline)
                    .foregroundStyle(TradeTheme.muted)
            }

            Text("\(post.title). \(post.thesis)")
                .font(.title2)
                .lineSpacing(4)
                .foregroundStyle(TradeTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            TradeTicketView(post: post, stock: stock, author: author)

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
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(TradeTheme.muted)
        .frame(maxWidth: .infinity)
    }
}
