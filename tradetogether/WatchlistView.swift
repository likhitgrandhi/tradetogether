//
//  WatchlistView.swift
//  tradetogether
//
//  Created by Codex on 05/05/26.
//

import SwiftUI

struct WatchlistView: View {
    let store: DemoStore
    @State private var selectedStockID: StockInstrument.ID?

    private var visibleItems: [WatchlistItem] {
        guard let selectedStockID else { return store.watchlist }
        return store.watchlist.filter { $0.stockID == selectedStockID }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                WSJMasthead()
                header
                stockRail
                ForEach(visibleItems) { item in
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
                .font(.seek(size: 34, weight: .bold))
                .foregroundStyle(TradeTheme.ink)
            Text("Manual portfolio and watchlist names, paired with community ideas.")
                .font(.seek(size: 15, weight: .regular))
                .foregroundStyle(TradeTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var stockRail: some View {
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

                ForEach(store.watchlist) { item in
                    let stock = store.stock(id: item.stockID)
                    StockRailItem(
                        title: stock.symbol,
                        symbol: String(stock.symbol.prefix(2)),
                        color: AvatarColor.color(for: stock.id),
                        isSelected: selectedStockID == stock.id
                    ) {
                        withAnimation(.snappy) {
                            selectedStockID = stock.id
                        }
                    }
                }
            }
            .padding(.vertical, 2)
        }
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
                        .font(.seek(size: 17, weight: .bold))
                        .foregroundStyle(TradeTheme.ink)
                    Text(stock.exchange)
                        .font(.seek(size: 12, weight: .bold))
                        .foregroundStyle(TradeTheme.muted)
                }
                Text(stock.name)
                    .font(.seek(size: 15, weight: .regular))
                    .foregroundStyle(TradeTheme.ink)
                Text(item.note)
                    .font(.seek(size: 12, weight: .regular))
                    .foregroundStyle(TradeTheme.muted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 5) {
                Text("\(stock.region == .india ? "Rs " : "$")\(stock.price.cleanPrice)")
                    .font(.seek(size: 15, weight: .bold).monospacedDigit())
                Text(stock.changePercent.percentText)
                    .font(.seek(size: 12, weight: .bold).monospacedDigit())
                    .foregroundStyle(stock.changePercent >= 0 ? TradeTheme.gain : TradeTheme.loss)
                Text("\(ideaCount) ideas")
                    .font(.seek(size: 11, weight: .semibold))
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
