//
//  DiscoverView.swift
//  tradetogether
//
//  Created by Codex on 05/05/26.
//

import SwiftUI

struct DiscoverView: View {
    let store: DemoStore
    @State private var query = ""

    private var filteredStocks: [StockInstrument] {
        guard !query.isEmpty else { return store.stocks }
        return store.stocks.filter {
            $0.symbol.localizedCaseInsensitiveContains(query)
                || $0.name.localizedCaseInsensitiveContains(query)
                || $0.exchange.localizedCaseInsensitiveContains(query)
        }
    }

    private var filteredProfiles: [TraderProfile] {
        guard !query.isEmpty else { return store.profiles }
        return store.profiles.filter {
            $0.name.localizedCaseInsensitiveContains(query)
                || $0.handle.localizedCaseInsensitiveContains(query)
                || $0.role.localizedCaseInsensitiveContains(query)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                WSJMasthead()
                SectionHeader(title: "Stocks", subtitle: "Search US and India tickers")
                ForEach(filteredStocks) { stock in
                    NavigationLink {
                        StockDetailView(stock: stock, store: store)
                    } label: {
                        WatchlistRow(item: WatchlistItem(id: stock.id, stockID: stock.id, note: stock.volumeNote, isInPortfolio: false), stock: stock, ideaCount: store.posts(for: stock).count)
                    }
                    .buttonStyle(.plain)
                }

                SectionHeader(title: "Traders", subtitle: "Profiles with closed-idea track records")
                ForEach(filteredProfiles) { profile in
                    NavigationLink {
                        ProfileView(profile: profile, posts: store.posts(for: profile), store: store)
                    } label: {
                        profileSearchRow(profile)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(TradeTheme.paper.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.light, for: .navigationBar)
        .searchable(text: $query, prompt: "Search AAPL, RELIANCE, traders")
    }

    private func profileSearchRow(_ profile: TraderProfile) -> some View {
        let stats = TradeMetrics.stats(for: profile, posts: store.posts(for: profile))

        return HStack(spacing: 12) {
            TraderAvatar(profile: profile)
            VStack(alignment: .leading, spacing: 4) {
                Text(profile.name)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(TradeTheme.ink)
                Text("\(profile.handle) - \(profile.role)")
                    .font(.caption)
                    .foregroundStyle(TradeTheme.muted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(stats.winRate)%")
                    .font(.subheadline.monospacedDigit().weight(.bold))
                    .foregroundStyle(TradeTheme.gain)
                Text("win rate")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(TradeTheme.muted)
            }
        }
        .padding(14)
        .background(TradeTheme.tile)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(TradeTheme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
