//
//  WatchlistView.swift
//  tradetogether
//
//  Created by Codex on 05/05/26.
//

import SwiftUI

struct WatchlistView: View {
    let store: DemoStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                WSJMasthead()
                header
                ForEach(store.watchlist) { item in
                    let stock = store.stock(id: item.stockID)
                    NavigationLink {
                        StockDetailView(stock: stock, store: store)
                    } label: {
                        WatchlistRow(item: item, stock: stock, ideaCount: store.posts(for: stock).count)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .background(TradeTheme.paper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Your Tape")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(TradeTheme.ink)
            Text("Manual portfolio and watchlist names, paired with community ideas.")
                .font(.subheadline)
                .foregroundStyle(TradeTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WatchlistRow: View {
    let item: WatchlistItem
    let stock: StockInstrument
    let ideaCount: Int

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(stock.symbol)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(TradeTheme.ink)
                    Text(stock.exchange)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(TradeTheme.muted)
                }
                Text(stock.name)
                    .font(.subheadline)
                    .foregroundStyle(TradeTheme.ink)
                Text(item.note)
                    .font(.caption)
                    .foregroundStyle(TradeTheme.muted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                Text("\(stock.region == .india ? "Rs " : "$")\(stock.price.cleanPrice)")
                    .font(.subheadline.monospacedDigit().weight(.bold))
                Text(stock.changePercent.percentText)
                    .font(.caption.monospacedDigit().weight(.bold))
                    .foregroundStyle(stock.changePercent >= 0 ? TradeTheme.gain : TradeTheme.loss)
                Text("\(ideaCount) ideas")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(TradeTheme.muted)
            }
        }
        .padding(14)
        .background(TradeTheme.tile)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(item.isInPortfolio ? TradeTheme.gold : TradeTheme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
