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
                .frame(width: 56, alignment: .leading)
            } else {
                Circle()
                    .fill(AvatarColor.color(for: "seek"))
                    .frame(width: 34, height: 34)
                    .overlay {
                        Text("S")
                            .font(.headline.weight(.black))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 56, alignment: .leading)
            }

            Spacer()
            VStack(spacing: 8) {
                Text("Seek")
                    .font(.tradeScreenTitle)
                    .foregroundStyle(TradeTheme.ink)
            }
            Spacer()

            Image(systemName: showBackHint ? "magnifyingglass" : "bubble.right")
                .font(.system(size: 24, weight: .regular))
                .foregroundStyle(TradeTheme.ink)
                .frame(width: 56, alignment: .trailing)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 10)
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
        ZStack {
            Circle()
                .fill(AvatarColor.color(for: profile.id))
            Circle()
                .fill(.white.opacity(0.14))
                .frame(width: size * 0.58, height: size * 0.58)
                .offset(x: size * 0.18, y: -size * 0.16)
            Text(profile.initials)
                .font(.system(size: size * 0.34, weight: .black))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
}

struct TradeActionButton: View {
    let icon: String
    let count: Int?
    var tint: Color = TradeTheme.muted
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .regular))
                if let count, count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .regular))
                        .monospacedDigit()
                }
            }
            .foregroundStyle(tint)
            .frame(minWidth: 36, minHeight: 36, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(TradePressableStyle())
    }
}

struct TradePostPill: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.tradeButton)
                .foregroundStyle(TradeTheme.paper)
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
                .background(Capsule().fill(TradeTheme.ink))
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.3)
        .buttonStyle(TradePressableStyle())
    }
}

enum AvatarColor {
    private static let palette: [Color] = [
        TradeTheme.brandBlue,
        TradeTheme.verified,
        TradeTheme.loss,
        TradeTheme.gain,
        TradeTheme.gold,
        TradeTheme.tertiary
    ]

    static func color(for key: String) -> Color {
        let value = abs(key.unicodeScalars.reduce(0) { ($0 * 31) + Int($1.value) })
        return palette[value % palette.count]
    }
}

struct TradeComposerView: View {
    let author: TraderProfile
    let stocks: [StockInstrument]
    @State private var drafts: [String] = [""]
    @State private var selectedStockID: StockInstrument.ID
    @State private var direction: TradeDirection = .long
    @State private var product: TradeProduct = .equity
    @State private var timeframe = "2-4 weeks"

    init(author: TraderProfile, stocks: [StockInstrument]) {
        self.author = author
        self.stocks = stocks
        _selectedStockID = State(initialValue: stocks.first?.id ?? "")
    }

    private var selectedStock: StockInstrument? {
        stocks.first { $0.id == selectedStockID }
    }

    private var canPost: Bool {
        drafts.contains { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                composerHeader
                tradeControls
                draftThread
                addThreadButton
            }
        }
        .background(TradeTheme.paper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var composerHeader: some View {
        HStack {
            Text("New Trade Idea")
                .font(.tradeScreenTitle)
                .foregroundStyle(TradeTheme.ink)
            Spacer()
            TradePostPill(title: "Post", isEnabled: canPost) {}
        }
        .padding(.horizontal, 18)
        .padding(.top, 12)
        .padding(.bottom, 14)
        .background(TradeTheme.paper)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TradeTheme.line)
                .frame(height: 1)
        }
    }

    private var tradeControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Setup", subtitle: selectedStock?.displaySymbol ?? "Choose an instrument")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(stocks) { stock in
                        Button {
                            withAnimation(.snappy) {
                                selectedStockID = stock.id
                            }
                        } label: {
                            Text(stock.symbol)
                                .font(.tradeFilterChip)
                                .foregroundStyle(selectedStockID == stock.id ? TradeTheme.paper : TradeTheme.ink)
                                .padding(.horizontal, 16)
                                .frame(minHeight: 36)
                                .background(Capsule().fill(selectedStockID == stock.id ? TradeTheme.ink : Color.clear))
                                .overlay {
                                    Capsule().stroke(selectedStockID == stock.id ? Color.clear : TradeTheme.line, lineWidth: 1)
                                }
                        }
                        .buttonStyle(TradePressableStyle())
                    }
                }
            }

            HStack(spacing: 8) {
                Picker("Direction", selection: $direction) {
                    Text("Long").tag(TradeDirection.long)
                    Text("Short").tag(TradeDirection.short)
                }
                .pickerStyle(.segmented)
                Picker("Product", selection: $product) {
                    ForEach(TradeProduct.allCases, id: \.self) { item in
                        Text(item.rawValue).tag(item)
                    }
                }
                .pickerStyle(.segmented)
            }

            TextField("Timeframe", text: $timeframe)
                .font(.tradePostBody)
                .foregroundStyle(TradeTheme.ink)
                .tint(TradeTheme.ink)
                .padding(12)
                .background(TradeTheme.tile)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(16)
        .background(TradeTheme.panel)
    }

    private var draftThread: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(drafts.indices, id: \.self) { index in
                HStack(alignment: .top, spacing: 12) {
                    VStack(spacing: 0) {
                        if index == 0 {
                            TraderAvatar(profile: author, size: 36)
                        } else {
                            Circle()
                                .strokeBorder(TradeTheme.line, lineWidth: 1)
                                .frame(width: 20, height: 20)
                                .padding(.top, 8)
                        }

                        Rectangle()
                            .fill(TradeTheme.line)
                            .frame(width: 1)
                            .frame(maxHeight: .infinity)
                            .padding(.top, 5)
                            .accessibilityHidden(true)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        if index == 0 {
                            Text(author.handle.replacingOccurrences(of: "@", with: ""))
                                .font(.tradeDisplayName)
                                .foregroundStyle(TradeTheme.ink)
                        }
                        TextField(index == 0 ? "Share the trade thesis..." : "Add more context...", text: $drafts[index], axis: .vertical)
                            .font(.tradePostBody)
                            .foregroundStyle(TradeTheme.ink)
                            .tint(TradeTheme.ink)
                            .lineLimit(3...12)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
        .background(TradeTheme.paper)
    }

    private var addThreadButton: some View {
        Button {
            withAnimation(.snappy) {
                drafts.append("")
            }
        } label: {
            HStack(spacing: 12) {
                Circle()
                    .strokeBorder(TradeTheme.line, lineWidth: 1)
                    .frame(width: 20, height: 20)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(TradeTheme.muted)
                    }
                    .padding(.leading, 24)
                Text("Add to thread")
                    .font(.tradeHandle)
                    .foregroundStyle(TradeTheme.muted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 16)
        }
        .buttonStyle(TradePressableStyle())
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
    @State private var isLiked = false
    @State private var isReposted = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 9) {
                HStack(alignment: .center, spacing: 12) {
                    TraderAvatar(profile: author, size: 36)
                    authorLine
                }

                tradeActivityLine
                postCopy
                TradeTicketView(post: post, stock: stock)
                    .frame(maxWidth: .infinity, alignment: .leading)
                actionRow
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)

            Rectangle()
                .fill(TradeTheme.line)
                .frame(height: 1)
        }
        .background(TradeTheme.paper)
        .accessibilityElement(children: .contain)
    }

    private var authorLine: some View {
        HStack(alignment: .center, spacing: 6) {
            Text(author.handle)
                .font(.tradeDisplayName)
                .foregroundStyle(TradeTheme.ink)
                .lineLimit(1)
            if let stats {
                Text("(WR: \(winRateText(stats.winRate)))")
                    .font(.tradeActionCount.weight(.semibold))
                    .foregroundStyle(TradeTheme.gain)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }
            Text(post.postedAgo)
                .font(.tradeHandle)
                .foregroundStyle(TradeTheme.muted)
            Spacer(minLength: 0)
            Image(systemName: "ellipsis")
                .font(.system(size: 18))
                .foregroundStyle(TradeTheme.muted)
        }
    }

    private var tradeActivityLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            Text(tradeStatusPhrase)
            Text(stock.symbol)
                .fontWeight(.semibold)
        }
        .font(.tradePostBody.weight(.semibold))
        .foregroundStyle(TradeTheme.ink)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var postCopy: some View {
        Text("\(post.title). \(post.thesis)")
            .font(.tradePostBody)
            .lineSpacing(5)
            .foregroundStyle(TradeTheme.ink)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var tradeStatusPhrase: String {
        if post.status.isClosed {
            return "\(post.status.rawValue) \(post.direction.rawValue.lowercased()) \(productName.lowercased()) in"
        }
        return "Opened \(post.direction.rawValue.lowercased()) \(productName.lowercased()) in"
    }

    private var productName: String {
        switch post.product {
        case .equity: "stock"
        case .futures: "future"
        case .options: "option"
        }
    }

    private var actionRow: some View {
        HStack(spacing: 14) {
            TradeActionButton(
                icon: isLiked ? "heart.fill" : "heart",
                count: post.votes + (isLiked ? 1 : 0),
                tint: isLiked ? TradeTheme.loss : TradeTheme.muted
            ) {
                withOptionalSpring {
                    isLiked.toggle()
                }
            }
            TradeActionButton(icon: "bubble.left", count: post.comments) {}
            TradeActionButton(
                icon: isReposted ? "arrow.2.squarepath.circle.fill" : "arrow.2.squarepath",
                count: nil
            ) {
                withOptionalSpring {
                    isReposted.toggle()
                }
            }
            TradeActionButton(icon: "paperplane", count: nil) {}
            Spacer(minLength: 0)
        }
        .padding(.top, 1)
    }

    private func withOptionalSpring(_ updates: @escaping () -> Void) {
        if reduceMotion {
            updates()
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.72), updates)
        }
    }

    private func winRateText(_ winRate: Int) -> String {
        String(format: "%.1f%%", Double(winRate))
    }
}

struct TradeTicketView: View {
    let post: TradeIdea
    let stock: StockInstrument
    @State private var pulseOpenDot = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                HStack(spacing: 8) {
                    Text(String(stock.symbol.prefix(1)))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(AvatarColor.color(for: stock.id))
                        .clipShape(RoundedRectangle(cornerRadius: 5))

                    Text(instrumentTitle)
                        .font(.tradeDisplayName.weight(.semibold))
                        .foregroundStyle(TradeTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.58)

                    Text(productLabel)
                        .font(.tradeActionCount)
                        .foregroundStyle(TradeTheme.ink)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(TradeTheme.paper)
                    .overlay {
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(TradeTheme.line, lineWidth: 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                Spacer(minLength: 8)
                HStack(spacing: 5) {
                    if post.status == .active {
                        OpenTradePulseDot(isPulsing: pulseOpenDot)
                    }
                    Text(statusLabel)
                        .font(.tradeHandle)
                        .foregroundStyle(TradeTheme.ink)
                }
                .padding(.top, 2)
            }

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(pnlTitle)
                        .font(.tradeActionCount)
                        .foregroundStyle(TradeTheme.muted)
                    Text(returnText)
                        .font(.system(size: 22, weight: .regular).monospacedDigit())
                        .foregroundStyle(pnlColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.66)
                    Text(pnlValue)
                        .font(.system(size: 12, weight: .semibold).monospacedDigit())
                        .foregroundStyle(pnlColor)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                TradeReceiptSparkline(
                    values: stock.priceHistory,
                    positive: pnlIsPositive,
                    entrySide: post.direction,
                    closed: post.status.isClosed
                )
                .frame(width: 104, height: 58)
            }

            VStack(spacing: 9) {
                HStack(alignment: .top, spacing: 12) {
                    receiptMetric(title: "Entry Price", value: entryText)
                    receiptMetric(title: post.status.isClosed ? "Avg. Close Price" : "Mark Price", value: post.status.isClosed ? exitText : markText)
                }

                HStack(alignment: .top, spacing: 12) {
                    receiptMetric(title: post.status.isClosed ? "Close Time" : "Target", value: post.status.isClosed ? closeTimeText : targetText, tint: post.status.isClosed ? TradeTheme.muted : TradeTheme.gain)
                    receiptMetric(title: post.status.isClosed ? "Closed By" : "Stop", value: post.status.isClosed ? exitReason : stopText, tint: post.status.isClosed ? TradeTheme.muted : TradeTheme.loss)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(TradeTheme.panel)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .onAppear {
            guard post.status == .active else { return }
            withAnimation(.easeInOut(duration: 1.05).repeatForever(autoreverses: true)) {
                pulseOpenDot = true
            }
        }
    }

    private var pnlTitle: String {
        switch post.product {
        case .equity:
            return "PNL(Stock)"
        case .futures:
            return "PNL(Futures)"
        case .options:
            return "PNL(Options)"
        }
    }

    private var pnlValue: String {
        if let returnPercent = post.returnPercent {
            return currency(returnPercent * notional / 100)
        }
        return currency(stock.changePercent * notional / 100)
    }

    private var pnlColor: Color {
        let value = post.returnPercent ?? stock.changePercent
        return value >= 0 ? TradeTheme.gain : TradeTheme.loss
    }

    private var pnlIsPositive: Bool {
        let value = post.returnPercent ?? stock.changePercent
        return value >= 0
    }

    private var roiText: String {
        if let returnPercent = post.returnPercent {
            return returnPercent.percentText
        }
        return stock.changePercent.percentText
    }

    private var returnText: String {
        roiText
    }

    private var notional: Double {
        post.entry * quantity
    }

    private var quantity: Double {
        switch post.product {
        case .equity: 10
        case .futures: 75
        case .options: 100
        }
    }

    private var positionSize: String {
        switch post.product {
        case .equity: "\(Int(quantity)) sh"
        case .futures: "\(Int(quantity)) fut"
        case .options: "\(Int(quantity)) opt"
        }
    }

    private var entryText: String {
        currency(post.entry)
    }

    private var markText: String {
        currency(stock.price)
    }

    private var targetText: String {
        currency(post.target)
    }

    private var stopText: String {
        currency(post.stop)
    }

    private var exitText: String {
        switch post.status {
        case .hitTarget:
            return currency(post.target)
        case .stoppedOut:
            return currency(post.stop)
        case .thesisChanged:
            return currency(stock.price)
        case .active:
            return markText
        }
    }

    private var exitReason: String {
        switch post.status {
        case .hitTarget: "Target hit"
        case .stoppedOut: "Stop hit"
        case .thesisChanged: "Thesis changed"
        case .active: "Open"
        }
    }

    private var resultLabel: String {
        switch post.status {
        case .hitTarget: "Win"
        case .stoppedOut: "Loss"
        case .thesisChanged: "Closed"
        case .active: "Open"
        }
    }

    private var statusLabel: String {
        post.status == .active ? "Open" : "Closed"
    }

    private var statusColor: Color {
        switch post.status {
        case .active:
            return post.direction == .long ? TradeTheme.gain : TradeTheme.loss
        case .hitTarget:
            return TradeTheme.gain
        case .stoppedOut:
            return TradeTheme.loss
        case .thesisChanged:
            return TradeTheme.gold
        }
    }

    private var tradeSummary: String {
        let side = post.direction.rawValue.lowercased()
        if post.status.isClosed {
            return "Closed \(side) at \(exitText) from \(entryText)"
        }
        return "Open \(side) from \(entryText), mark \(markText)"
    }

    private var productLabel: String {
        switch post.product {
        case .equity:
            return "Stock"
        case .futures:
            return "Future"
        case .options:
            return post.direction == .long ? "Call" : "Put"
        }
    }

    private var instrumentTitle: String {
        switch post.product {
        case .equity:
            return stock.symbol
        case .futures:
            return "\(stock.symbol) Future Exp: May 06"
        case .options:
            return "\(stock.symbol) \(post.direction == .long ? "Call" : "Put") \(strikeText) Exp: May 06"
        }
    }

    private var strikeText: String {
        let strike = post.direction == .long ? post.target : post.stop
        return String(format: "%.2f", strike)
    }

    private var closeTimeText: String {
        switch post.status {
        case .hitTarget:
            return "2026-05-06 15:45"
        case .stoppedOut:
            return "2026-05-06 10:20"
        case .thesisChanged:
            return "2026-05-06 13:10"
        case .active:
            return "Open"
        }
    }

    private func currency(_ value: Double) -> String {
        "\(stock.region == .india ? "Rs " : "$")\(value.cleanPrice)"
    }

    private func receiptMetric(title: String, value: String, tint: Color = TradeTheme.ink) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .font(.system(size: 12, weight: .regular))
                .foregroundStyle(TradeTheme.muted)
            Text(value)
                .font(.system(size: 13, weight: .regular).monospacedDigit())
                .foregroundStyle(tint)
                .lineLimit(2)
                .minimumScaleFactor(0.60)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct OpenTradePulseDot: View {
    let isPulsing: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(TradeTheme.gain.opacity(isPulsing ? 0.16 : 0.36))
                .frame(width: isPulsing ? 14 : 8, height: isPulsing ? 14 : 8)
            Circle()
                .fill(TradeTheme.gain)
                .frame(width: 6, height: 6)
        }
        .frame(width: 14, height: 14)
    }
}

struct TradeReceiptSparkline: View {
    let values: [Double]
    let positive: Bool
    let entrySide: TradeDirection
    let closed: Bool

    var body: some View {
        GeometryReader { proxy in
            let points = sparklinePoints(in: proxy.size)
            let lineColor = positive ? TradeTheme.gain : TradeTheme.gold

            ZStack {
                Path { path in
                    guard let first = points.first else { return }
                    path.move(to: first)
                    for point in points.dropFirst() {
                        path.addLine(to: point)
                    }
                }
                .stroke(lineColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                if let first = points.first {
                    tradeMarker(label: entrySide == .long ? "B" : "S", color: entrySide == .long ? TradeTheme.gain : TradeTheme.loss)
                        .position(x: first.x, y: first.y)
                }

                if closed, let last = points.last {
                    tradeMarker(label: entrySide == .long ? "S" : "B", color: entrySide == .long ? TradeTheme.loss : TradeTheme.gain)
                        .position(x: last.x, y: last.y)
                }
            }
        }
    }

    private func tradeMarker(label: String, color: Color) -> some View {
        Text(label)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 22, height: 22)
            .background(color)
            .clipShape(Circle())
            .overlay(alignment: .bottom) {
                Circle()
                    .fill(color)
                    .frame(width: 7, height: 7)
                    .offset(y: 6)
            }
    }

    private func sparklinePoints(in size: CGSize) -> [CGPoint] {
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 1
        let range = max(maxValue - minValue, 1)
        return values.enumerated().map { index, value in
            let x = size.width * CGFloat(index) / CGFloat(max(values.count - 1, 1))
            let yRatio = (value - minValue) / range
            let y = size.height - (size.height * CGFloat(yRatio))
            return CGPoint(x: x, y: min(max(y, 14), size.height - 14))
        }
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
