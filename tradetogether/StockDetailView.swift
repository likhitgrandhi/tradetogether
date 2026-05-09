//
//  StockDetailView.swift
//  tradetogether
//
//  Created by Codex on 05/05/26.
//

import SwiftUI

struct StockDetailView: View {
    let stock: StockInstrument
    let store: DemoStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                WSJMasthead(showBackHint: true)
                instrumentTitle
                quoteBlock
                keyQuoteRows
                chartBlock
                watchlistAction
                aiPanel
                relatedPosts
            }
        }
        .background(TradeTheme.paper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var instrumentTitle: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(stock.name)
                    .font(.seek(size: 31, weight: .semibold))
                    .foregroundStyle(TradeTheme.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
                Text(stock.symbol)
                    .font(.seek(size: 20, weight: .regular))
                    .foregroundStyle(TradeTheme.muted)
            }
            Spacer()
            Text(stock.exchange)
                .font(.seek(size: 12, weight: .semibold))
                .foregroundStyle(TradeTheme.muted)
                .padding(.top, 6)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
        .background(TradeTheme.paper)
    }

    private var quoteBlock: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AT CLOSE 4:00 PM")
                .font(.seek(size: 12, weight: .semibold))
                .foregroundStyle(TradeTheme.muted)
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(price(stock.price))
                    .font(.seek(size: 58, weight: .light))
                    .foregroundStyle(TradeTheme.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.62)
                Text(stock.region == .india ? "INR" : "USD")
                    .font(.seek(size: 17, weight: .semibold))
                    .foregroundStyle(TradeTheme.muted)
                Spacer(minLength: 4)
            }

            HStack(spacing: 10) {
                Text(stock.changePercent.percentText)
                Image(systemName: "triangle.fill")
                    .font(.seek(size: 13, weight: .bold))
                    .rotationEffect(stock.changePercent >= 0 ? .zero : .degrees(180))
            }
            .font(.seek(size: 20, weight: .semibold).monospacedDigit())
            .foregroundStyle(stock.changePercent >= 0 ? TradeTheme.gain : TradeTheme.loss)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
        .background(TradeTheme.panel)
    }

    private var keyQuoteRows: some View {
        VStack(spacing: 0) {
            QuoteDataRow(title: "Volume", value: stock.volumeNote)
            QuoteDataRow(title: "Market Cap", value: stock.marketCap)
            QuoteDataRow(title: "Related Ideas", value: "\(store.posts(for: stock).count)")
            HStack {
                Text("Key Quote Data")
                    .font(.seek(size: 20, weight: .regular))
                    .foregroundStyle(TradeTheme.muted)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.seek(size: 22, weight: .semibold))
                    .foregroundStyle(TradeTheme.muted)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(TradeTheme.panel)
        }
        .padding(.bottom, 16)
        .background(TradeTheme.paper)
    }

    private var chartBlock: some View {
        VStack(alignment: .leading, spacing: 18) {
            SegmentedRangeControl(selected: stock.changePercent >= 0 ? "3M" : "1D")
            ZStack {
                chartGrid
                MiniLineChart(values: stock.priceHistory, positive: stock.changePercent >= 0)
                    .padding(.trailing, 62)
                    .padding(.bottom, 28)
                    .padding(.top, 12)
            }
            .frame(height: 280)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        .background(TradeTheme.panel)
    }

    private var chartGrid: some View {
        VStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { index in
                Rectangle()
                    .fill(TradeTheme.line)
                    .frame(height: 1)
                if index < 3 {
                    Spacer()
                }
            }
        }
        .overlay(alignment: .trailing) {
            VStack(alignment: .trailing) {
                Text(price((stock.priceHistory.max() ?? stock.price) * 1.01))
                Spacer()
                Text(price(stock.price))
                Spacer()
                Text(price((stock.priceHistory.min() ?? stock.price) * 0.99))
            }
            .font(.seek(size: 12, weight: .regular).monospacedDigit())
            .foregroundStyle(TradeTheme.muted)
            .frame(width: 58)
        }
        .overlay {
            HStack(spacing: 0) {
                ForEach(0..<4, id: \.self) { index in
                    Rectangle()
                        .fill(TradeTheme.line)
                        .frame(width: 1)
                    if index < 3 {
                        Spacer()
                    }
                }
            }
            .padding(.trailing, 76)
        }
    }

    private var watchlistAction: some View {
        HStack(spacing: 16) {
            Image(systemName: "plus.circle")
                .font(.seek(size: 34, weight: .light))
            Text("Watchlist")
                .font(.seek(size: 22, weight: .semibold))
            Spacer()
        }
        .foregroundStyle(TradeTheme.ink)
        .padding(.horizontal, 20)
        .padding(.vertical, 28)
        .background(TradeTheme.paper)
    }

    private var aiPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            SectionHeader(title: "AI Risk View", subtitle: "Educational thesis check, not a trade signal")
            Text(stock.aiOverview.stance)
                .font(.seek(size: 20, weight: .semibold))
                .foregroundStyle(TradeTheme.ink)
            Text(stock.aiOverview.summary)
                .font(.seek(size: 15, weight: .regular))
                .foregroundStyle(TradeTheme.muted)
            HStack(spacing: 8) {
                MetricPill(title: "Alignment", value: "\(stock.aiOverview.thesisAlignment)%", tint: TradeTheme.gold)
                MetricPill(title: "Risk", value: stock.aiOverview.riskLevel.rawValue, tint: riskColor)
            }
        }
        .padding(20)
        .background(TradeTheme.panel)
    }

    private var relatedPosts: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Related Ideas", subtitle: "Posts that mention \(stock.symbol)")
            ForEach(store.posts(for: stock)) { post in
                NavigationLink {
                    PostDetailView(post: post, store: store)
                } label: {
                    let author = store.profile(id: post.authorID)
                    TradeIdeaCard(
                        post: post,
                        author: author,
                        stock: stock,
                        stats: TradeMetrics.stats(for: author, posts: store.posts(for: author))
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(TradeTheme.paper)
    }

    private var riskColor: Color {
        switch stock.aiOverview.riskLevel {
        case .low: TradeTheme.gain
        case .medium: TradeTheme.gold
        case .high: TradeTheme.loss
        }
    }

    private func price(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}

struct QuoteDataRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.seek(size: 20, weight: .regular))
                .foregroundStyle(TradeTheme.muted)
            Spacer(minLength: 16)
            Text(value)
                .font(.seek(size: 20, weight: .regular).monospacedDigit())
                .foregroundStyle(TradeTheme.ink)
                .multilineTextAlignment(.trailing)
                .lineLimit(2)
                .minimumScaleFactor(0.72)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(TradeTheme.panel)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TradeTheme.line)
                .frame(height: 1)
                .padding(.leading, 20)
        }
    }
}
