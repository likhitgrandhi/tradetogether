//
//  TradeComponents.swift
//  tradetogether
//
//  Created by Codex on 05/05/26.
//

import SwiftUI

struct MarketTapeView: View {
    let stocks: [StockInstrument]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(stocks) { stock in
                    VStack(alignment: .leading, spacing: 5) {
                        Text("CLOSED")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(TradeTheme.muted)
                        Text(stock.symbol)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(TradeTheme.ink)
                            .lineLimit(1)
                        HStack(spacing: 4) {
                            Text(stock.changePercent.percentText)
                                .font(.caption2.monospacedDigit().weight(.bold))
                            Image(systemName: stock.changePercent >= 0 ? "triangle.fill" : "triangle.fill")
                                .font(.system(size: 8, weight: .bold))
                                .rotationEffect(stock.changePercent >= 0 ? .zero : .degrees(180))
                        }
                        .foregroundStyle(stock.changePercent >= 0 ? TradeTheme.gain : TradeTheme.loss)
                    }
                    .frame(width: 92, height: 66, alignment: .leading)
                    .padding(8)
                    .background(TradeTheme.tile)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(TradeTheme.paper)
    }
}

struct WSJMasthead: View {
    @Environment(\.dismiss) private var dismiss
    var showBackHint = false

    var body: some View {
        HStack {
            if showBackHint {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                    .font(.title3)
                    .foregroundStyle(TradeTheme.ink)
                }
                .buttonStyle(.plain)
                .frame(width: 70, alignment: .leading)
            } else {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [TradeTheme.softPurple.opacity(0.70), Color(red: 0.99, green: 0.58, blue: 0.90)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 46, height: 46)
                    .overlay {
                        Text("S")
                            .font(.headline.weight(.black))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 70, alignment: .leading)
            }

            Spacer()
            VStack(spacing: 8) {
                Text("Seek")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(TradeTheme.ink)
            }
            Spacer()

            Image(systemName: showBackHint ? "magnifyingglass" : "bubble.right")
                .font(.system(size: 28, weight: .regular))
                .foregroundStyle(TradeTheme.ink)
                .frame(width: 70, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 18)
        .background(TradeTheme.paper)
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(TradeTheme.muted)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(TradeTheme.muted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct TraderAvatar: View {
    let profile: TraderProfile
    var size: CGFloat = 38

    var body: some View {
        Text(profile.initials)
            .font(.system(size: size * 0.34, weight: .black))
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(
                LinearGradient(
                    colors: [TradeTheme.softPurple, Color(red: 0.20, green: 0.55, blue: 0.95)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(Circle())
    }
}

struct MetricPill: View {
    let title: String
    let value: String
    var tint: Color = TradeTheme.ink

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(TradeTheme.muted)
            Text(value)
                .font(.subheadline.monospacedDigit().weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(TradeTheme.tile)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(TradeTheme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct TradeIdeaCard: View {
    let post: TradeIdea
    let author: TraderProfile
    let stock: StockInstrument
    var stats: ProfileStats?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                TraderAvatar(profile: author, size: 42)
                VStack(alignment: .leading, spacing: 10) {
                    authorLine
                }
            }
            tradeActivityLine
            postCopy
            TradeTicketView(post: post, stock: stock, author: author)
            actionRow
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 26)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TradeTheme.line)
                .frame(height: 1)
        }
    }

    private var authorLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(author.handle.replacingOccurrences(of: "@", with: ""))
                .font(.headline.weight(.bold))
                .foregroundStyle(TradeTheme.ink)
                .lineLimit(1)
            if let stats {
                Text("Winrate: \(winRateText(stats.winRate))")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(TradeTheme.gain)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            Text(post.postedAgo)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TradeTheme.muted)
            Spacer(minLength: 0)
        }
    }

    private var tradeActivityLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text(actionVerb)
            Text(positionSize)
                .fontWeight(.bold)
            Text("of")
            Text("$\(stock.symbol)")
                .fontWeight(.bold)
        }
        .font(.title3)
        .foregroundStyle(TradeTheme.ink)
        .lineLimit(2)
    }

    private var postCopy: some View {
        Text("\(post.title). \(post.thesis)")
            .font(.body)
            .lineSpacing(3)
            .foregroundStyle(TradeTheme.ink.opacity(0.84))
            .lineLimit(4)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var actionVerb: String {
        post.direction == .long ? "bought" : "shorted"
    }

    private var positionSize: String {
        let notional = post.entry * 10
        if stock.region == .india {
            return "Rs \(notional.cleanPrice)"
        }
        return "$\(notional.cleanPrice)"
    }

    private var actionRow: some View {
        HStack(spacing: 28) {
            Label("\(post.votes)", systemImage: "plus.square.on.square")
            Label("4", systemImage: "bookmark")
            Label("\(post.comments)", systemImage: "bubble")
            Label("16", systemImage: "heart")
            Spacer(minLength: 0)
            Image(systemName: "ellipsis")
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(TradeTheme.muted)
    }

    private func winRateText(_ winRate: Int) -> String {
        String(format: "%.1f%%", Double(winRate))
    }
}

struct TradeTicketView: View {
    let post: TradeIdea
    let stock: StockInstrument
    let author: TraderProfile

    private var accent: Color {
        switch post.status {
        case .stoppedOut: TradeTheme.loss
        case .thesisChanged: TradeTheme.gold
        default: post.direction == .long ? TradeTheme.gain : TradeTheme.loss
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                HStack(spacing: 12) {
                    Circle()
                        .fill(TradeTheme.softPurple.opacity(0.22))
                        .frame(width: 54, height: 54)
                        .overlay {
                            Text(String(stock.symbol.prefix(1)))
                                .font(.title2.weight(.black))
                                .foregroundStyle(TradeTheme.softPurple)
                        }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(stock.name)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(TradeTheme.ink)
                            .lineLimit(1)
                            .minimumScaleFactor(0.70)
                        Text(stock.symbol)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(TradeTheme.muted)
                    }
                }
                Spacer()
                Text(orderLine)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(TradeTheme.muted)
                    .lineLimit(2)
                    .multilineTextAlignment(.trailing)
            }

            TradeTicketChart(values: stock.priceHistory, entry: post.entry, positive: post.direction == .long, author: author)
                .frame(height: 150)

            HStack(spacing: 0) {
                ticketMetric(title: "Price", value: priceText)
                Divider().background(TradeTheme.line)
                ticketMetric(title: "PnL", value: stock.changePercent.percentText, tint: stock.changePercent >= 0 ? TradeTheme.gain : TradeTheme.loss)
                Divider().background(TradeTheme.line)
                ticketMetric(title: "Entry", value: entryText)
            }
        }
        .padding(20)
        .background(TradeTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: Color.black.opacity(0.04), radius: 14, y: 8)
    }

    private var orderLine: String {
        let currency = stock.region == .india ? "Rs " : "$"
        switch post.direction {
        case .long:
            return "Buy @ \(currency)\(post.entry.cleanPrice)"
        case .short:
            return "Short @ \(currency)\(post.entry.cleanPrice)"
        }
    }

    private var priceText: String {
        "\(stock.region == .india ? "Rs " : "$")\(stock.price.cleanPrice)"
    }

    private var entryText: String {
        "\(stock.region == .india ? "Rs " : "$")\(post.entry.cleanPrice)"
    }

    private func ticketMetric(title: String, value: String, tint: Color = TradeTheme.ink) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(TradeTheme.muted)
            Text(value)
                .font(.headline.monospacedDigit().weight(.bold))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.68)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DirectionBadge: View {
    let direction: TradeDirection
    let status: TradeStatus

    private var color: Color {
        switch status {
        case .stoppedOut: TradeTheme.loss
        case .hitTarget: TradeTheme.gain
        case .active: direction == .long ? TradeTheme.gain : TradeTheme.loss
        case .thesisChanged: TradeTheme.gold
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: direction.symbolName)
            Text(status == .active ? direction.rawValue : status.rawValue)
        }
        .font(.caption2.weight(.bold))
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(color.opacity(0.16))
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct QuoteChip: View {
    let stock: StockInstrument

    var body: some View {
        HStack(spacing: 6) {
            Text(stock.symbol)
                .font(.caption.weight(.bold))
            Text(stock.changePercent.percentText)
                .font(.caption2.monospacedDigit().weight(.bold))
                .foregroundStyle(stock.changePercent >= 0 ? TradeTheme.gain : TradeTheme.loss)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(TradeTheme.tile)
        .foregroundStyle(TradeTheme.ink)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }
}

struct TradeTicketChart: View {
    let values: [Double]
    let entry: Double
    let positive: Bool
    let author: TraderProfile

    var body: some View {
        GeometryReader { proxy in
            let minValue = min(values.min() ?? entry, entry)
            let maxValue = max(values.max() ?? entry, entry)
            let range = max(maxValue - minValue, 1)
            let markerX = proxy.size.width * 0.78
            let yRatio = (entry - minValue) / range
            let markerY = proxy.size.height - (proxy.size.height * CGFloat(yRatio))

            ZStack(alignment: .topLeading) {
                MiniLineChart(values: values, positive: positive)

                Circle()
                    .fill(positive ? TradeTheme.gain : TradeTheme.loss)
                    .frame(width: 13, height: 13)
                    .overlay {
                        Circle()
                            .stroke(.white, lineWidth: 3)
                    }
                    .position(x: markerX, y: clampedY(markerY, height: proxy.size.height))

                TraderAvatar(profile: author, size: 42)
                    .overlay(alignment: .bottomTrailing) {
                        Circle()
                            .fill(positive ? TradeTheme.gain : TradeTheme.loss)
                            .frame(width: 13, height: 13)
                            .overlay {
                                Circle().stroke(.white, lineWidth: 2)
                            }
                    }
                    .position(x: min(markerX + 18, proxy.size.width - 24), y: max(clampedY(markerY, height: proxy.size.height) - 26, 24))
            }
        }
    }

    private func clampedY(_ y: CGFloat, height: CGFloat) -> CGFloat {
        min(max(y, 18), height - 18)
    }
}

struct MiniLineChart: View {
    let values: [Double]
    let positive: Bool

    var body: some View {
        GeometryReader { proxy in
            let minValue = values.min() ?? 0
            let maxValue = values.max() ?? 1
            let range = max(maxValue - minValue, 1)
            Path { path in
                for index in values.indices {
                    let x = proxy.size.width * CGFloat(index) / CGFloat(max(values.count - 1, 1))
                    let yRatio = (values[index] - minValue) / range
                    let y = proxy.size.height - (proxy.size.height * CGFloat(yRatio))
                    if index == values.startIndex {
                        path.move(to: CGPoint(x: x, y: proxy.size.height))
                        path.addLine(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                path.addLine(to: CGPoint(x: proxy.size.width, y: proxy.size.height))
                path.closeSubpath()
            }
            .fill((positive ? TradeTheme.chartBlue : TradeTheme.loss).opacity(0.24))

            Path { path in
                for index in values.indices {
                    let x = proxy.size.width * CGFloat(index) / CGFloat(max(values.count - 1, 1))
                    let yRatio = (values[index] - minValue) / range
                    let y = proxy.size.height - (proxy.size.height * CGFloat(yRatio))
                    if index == values.startIndex {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(positive ? TradeTheme.chartBlue : TradeTheme.loss, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}

struct SegmentedRangeControl: View {
    let selected: String
    private let ranges = ["1D", "5D", "1M", "3M", "YTD", "1Y", "5Y"]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ranges, id: \.self) { range in
                Text(range)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(TradeTheme.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 9)
                    .background(range == selected ? TradeTheme.line : Color.clear)
                    .overlay(alignment: .trailing) {
                        if range != ranges.last {
                            Rectangle()
                                .fill(TradeTheme.line)
                                .frame(width: 1)
                        }
                    }
            }
        }
        .background(TradeTheme.panel)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(TradeTheme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

extension Double {
    var percentText: String {
        "\(self >= 0 ? "+" : "")\(String(format: "%.2f", self))%"
    }

    var cleanPrice: String {
        String(format: "%.2f", self)
    }
}
