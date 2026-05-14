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
                            .font(.seek(size: 9, weight: .bold))
                            .foregroundStyle(TradeTheme.muted)
                        Text(stock.symbol)
                            .font(.seek(size: 12, weight: .bold))
                            .foregroundStyle(TradeTheme.ink)
                            .lineLimit(1)
                        HStack(spacing: 4) {
                            Text(stock.changePercent.percentText)
                                .font(.seek(size: 11, weight: .bold).monospacedDigit())
                            Image(systemName: stock.changePercent >= 0 ? "triangle.fill" : "triangle.fill")
                                .font(.seek(size: 8, weight: .bold))
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

struct UpDownLogo: View {
    var pullProgress: CGFloat = 0
    var isRefreshing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clampedProgress: CGFloat {
        min(max(pullProgress, 0), 1)
    }

    var body: some View {
        let progress = clampedProgress

        ZStack {
            UpArrowShape()
                .fill(TradeTheme.ink.opacity(1 - Double(progress) * 0.36))
            DownArrowShape()
                .fill(TradeTheme.ink.opacity(1 - Double(progress) * 0.36))

            UpArrowShape()
                .fill(TradeTheme.gain)
                .mask(alignment: .bottom) {
                    Rectangle()
                        .frame(height: 34 * progress)
                }
                .opacity(progress)

            DownArrowShape()
                .fill(TradeTheme.loss)
                .mask(alignment: .top) {
                    Rectangle()
                        .frame(height: 34 * progress)
                }
                .opacity(progress)
        }
        .frame(width: 25, height: 34)
        .rotationEffect(isRefreshing && !reduceMotion ? .degrees(360) : .zero)
        .scaleEffect(1 + progress * 0.08)
        .animation(.spring(response: 0.26, dampingFraction: 0.74), value: progress)
        .animation(isRefreshing && !reduceMotion ? .linear(duration: 0.95).repeatForever(autoreverses: false) : .default, value: isRefreshing)
        .accessibilityLabel("GrowHouse")
    }
}

private struct UpArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        LogoPathBuilder.path(in: rect) { path in
            path.move(to: CGPoint(x: 9.5, y: 27.3))
            path.addCurve(to: CGPoint(x: 35.0, y: 7.8), control1: CGPoint(x: 18.6, y: 21.4), control2: CGPoint(x: 27.4, y: 14.9))
            path.addCurve(to: CGPoint(x: 45.2, y: 2.3), control1: CGPoint(x: 38.3, y: 4.8), control2: CGPoint(x: 41.0, y: 1.9))
            path.addCurve(to: CGPoint(x: 52.1, y: 6.0), control1: CGPoint(x: 48.0, y: 2.5), control2: CGPoint(x: 50.3, y: 3.9))
            path.addCurve(to: CGPoint(x: 55.5, y: 11.8), control1: CGPoint(x: 53.6, y: 7.6), control2: CGPoint(x: 54.4, y: 9.9))
            path.addCurve(to: CGPoint(x: 66.9, y: 30.4), control1: CGPoint(x: 59.0, y: 18.4), control2: CGPoint(x: 62.7, y: 24.5))
            path.addCurve(to: CGPoint(x: 73.9, y: 40.0), control1: CGPoint(x: 69.2, y: 33.7), control2: CGPoint(x: 71.6, y: 37.2))
            path.addCurve(to: CGPoint(x: 75.8, y: 45.9), control1: CGPoint(x: 75.3, y: 41.8), control2: CGPoint(x: 76.0, y: 43.6))
            path.addCurve(to: CGPoint(x: 68.9, y: 52.0), control1: CGPoint(x: 75.4, y: 49.6), control2: CGPoint(x: 72.5, y: 52.1))
            path.addCurve(to: CGPoint(x: 58.7, y: 51.8), control1: CGPoint(x: 65.4, y: 51.9), control2: CGPoint(x: 61.9, y: 50.0))
            path.addCurve(to: CGPoint(x: 55.0, y: 58.7), control1: CGPoint(x: 56.1, y: 53.2), control2: CGPoint(x: 55.4, y: 56.0))
            path.addCurve(to: CGPoint(x: 50.9, y: 85.2), control1: CGPoint(x: 53.5, y: 67.1), control2: CGPoint(x: 54.2, y: 76.9))
            path.addCurve(to: CGPoint(x: 44.3, y: 93.2), control1: CGPoint(x: 49.5, y: 88.4), control2: CGPoint(x: 47.1, y: 91.3))
            path.addCurve(to: CGPoint(x: 24.3, y: 93.9), control1: CGPoint(x: 38.7, y: 97.1), control2: CGPoint(x: 30.0, y: 97.4))
            path.addCurve(to: CGPoint(x: 16.8, y: 68.7), control1: CGPoint(x: 15.3, y: 88.8), control2: CGPoint(x: 14.5, y: 78.6))
            path.addCurve(to: CGPoint(x: 19.7, y: 53.9), control1: CGPoint(x: 17.9, y: 63.9), control2: CGPoint(x: 19.1, y: 59.1))
            path.addCurve(to: CGPoint(x: 17.9, y: 46.2), control1: CGPoint(x: 20.0, y: 51.0), control2: CGPoint(x: 20.1, y: 48.4))
            path.addCurve(to: CGPoint(x: 9.5, y: 43.3), control1: CGPoint(x: 15.9, y: 44.0), control2: CGPoint(x: 12.6, y: 43.9))
            path.addCurve(to: CGPoint(x: 4.5, y: 31.7), control1: CGPoint(x: 3.5, y: 42.6), control2: CGPoint(x: 1.1, y: 36.2))
            path.addCurve(to: CGPoint(x: 9.5, y: 27.5), control1: CGPoint(x: 5.8, y: 30.0), control2: CGPoint(x: 7.6, y: 28.7))
            path.addLine(to: CGPoint(x: 9.5, y: 27.3))
            path.closeSubpath()
        }
    }
}

private struct DownArrowShape: Shape {
    func path(in rect: CGRect) -> Path {
        LogoPathBuilder.path(in: rect) { path in
            path.move(to: CGPoint(x: 113.0, y: 135.3))
            path.addCurve(to: CGPoint(x: 86.2, y: 152.7), control1: CGPoint(x: 103.8, y: 140.7), control2: CGPoint(x: 94.6, y: 146.0))
            path.addCurve(to: CGPoint(x: 72.0, y: 160.5), control1: CGPoint(x: 80.5, y: 157.1), control2: CGPoint(x: 77.8, y: 160.9))
            path.addCurve(to: CGPoint(x: 63.6, y: 154.4), control1: CGPoint(x: 68.1, y: 160.0), control2: CGPoint(x: 65.6, y: 158.6))
            path.addCurve(to: CGPoint(x: 46.4, y: 121.9), control1: CGPoint(x: 59.4, y: 145.2), control2: CGPoint(x: 53.5, y: 134.0))
            path.addCurve(to: CGPoint(x: 44.2, y: 114.9), control1: CGPoint(x: 44.9, y: 119.5), control2: CGPoint(x: 44.1, y: 117.6))
            path.addCurve(to: CGPoint(x: 51.4, y: 107.3), control1: CGPoint(x: 44.4, y: 111.4), control2: CGPoint(x: 47.1, y: 107.6))
            path.addCurve(to: CGPoint(x: 60.0, y: 108.7), control1: CGPoint(x: 54.7, y: 107.3), control2: CGPoint(x: 57.6, y: 108.9))
            path.addCurve(to: CGPoint(x: 65.0, y: 105.8), control1: CGPoint(x: 62.7, y: 108.5), control2: CGPoint(x: 64.4, y: 107.1))
            path.addCurve(to: CGPoint(x: 69.4, y: 84.6), control1: CGPoint(x: 66.9, y: 103.1), control2: CGPoint(x: 68.2, y: 93.3))
            path.addCurve(to: CGPoint(x: 86.9, y: 66.2), control1: CGPoint(x: 70.9, y: 75.3), control2: CGPoint(x: 76.5, y: 66.9))
            path.addCurve(to: CGPoint(x: 106.2, y: 78.0), control1: CGPoint(x: 96.6, y: 65.4), control2: CGPoint(x: 104.1, y: 71.0))
            path.addCurve(to: CGPoint(x: 101.7, y: 106.1), control1: CGPoint(x: 108.7, y: 86.2), control2: CGPoint(x: 104.9, y: 94.1))
            path.addCurve(to: CGPoint(x: 103.2, y: 117.5), control1: CGPoint(x: 100.6, y: 110.9), control2: CGPoint(x: 100.0, y: 114.5))
            path.addCurve(to: CGPoint(x: 110.9, y: 120.5), control1: CGPoint(x: 105.1, y: 119.1), control2: CGPoint(x: 107.8, y: 119.8))
            path.addCurve(to: CGPoint(x: 113.0, y: 133.3), control1: CGPoint(x: 117.6, y: 121.8), control2: CGPoint(x: 118.9, y: 129.4))
            path.addLine(to: CGPoint(x: 113.0, y: 135.3))
            path.closeSubpath()
        }
    }
}

private enum LogoPathBuilder {
    static func path(in rect: CGRect, build: (inout Path) -> Void) -> Path {
        let viewBox = CGSize(width: 120, height: 162.4)
        let scale = min(rect.width / viewBox.width, rect.height / viewBox.height)
        let xOffset = rect.midX - viewBox.width * scale / 2
        let yOffset = rect.midY - viewBox.height * scale / 2
        var source = Path()
        build(&source)
        return source.applying(
            CGAffineTransform(translationX: xOffset, y: yOffset)
                .scaledBy(x: scale, y: scale)
        )
    }
}

struct WSJMasthead: View {
    @Environment(\.dismiss) private var dismiss
    var showBackHint = false
    var logoPullProgress: CGFloat = 0
    var isRefreshing = false

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
                    .font(.seek(size: 20, weight: .regular))
                    .foregroundStyle(TradeTheme.ink)
                }
                    .buttonStyle(.plain)
                .frame(width: 56, alignment: .leading)
            } else {
                Color.clear
                    .frame(width: 56, height: 34)
            }

            Spacer()
            UpDownLogo(pullProgress: logoPullProgress, isRefreshing: isRefreshing)
            Spacer()

            Image(systemName: showBackHint ? "magnifyingglass" : "bubble.right")
                .font(.seek(size: 24, weight: .regular))
                .foregroundStyle(TradeTheme.ink)
                .frame(width: 56, height: 34, alignment: .trailing)
        }
        .frame(height: 52)
        .padding(.horizontal, 18)
        .background(TradeTheme.paper)
    }
}

struct SectionHeader: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.seek(size: 12, weight: .bold))
                .tracking(1.2)
                .foregroundStyle(TradeTheme.muted)
            if let subtitle {
                Text(subtitle)
                    .font(.seek(size: 12, weight: .regular))
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
                .font(.seek(size: size * 0.34, weight: .black))
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
                    .font(.seek(size: 17, weight: .regular))
                if let count, count > 0 {
                    Text("\(count)")
                        .font(.seek(size: 12, weight: .regular))
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
    @EnvironmentObject private var tradeStore: TradeStore
    @EnvironmentObject private var postStore: PostStore
    @Environment(\.dismiss) private var dismiss
    @State private var mode: ComposerMode = .general
    @State private var bodyText = ""
    @State private var selectedTradeId: SeekTradeCandidate.ID?
    @FocusState private var isBodyFocused: Bool

    init(author: TraderProfile, stocks: [StockInstrument]) {
        self.author = author
        self.stocks = stocks
    }

    private var openTrades: [SeekTradeCandidate] {
        tradeStore.trades.filter { $0.status.lowercased() == "open" }
    }

    private var canPost: Bool {
        let hasBody = !bodyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        switch mode {
        case .general:
            return hasBody
        case .activeTrade:
            return hasBody && selectedTradeId != nil
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            composerHeader
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    modePicker
                    if mode == .activeTrade {
                        activeTradePicker
                    }
                    composerBody
                    if let errorText = postStore.errorText {
                        Text(errorText)
                            .font(.seek(size: 12, weight: .regular))
                            .foregroundStyle(TradeTheme.loss)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
            }
        }
        .interactiveKeyboardDismissal()
        .dismissKeyboardOnBackgroundTap()
        .background(TradeTheme.paper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await tradeStore.load()
            selectedTradeId = selectedTradeId ?? openTrades.first?.id
        }
    }

    private var composerHeader: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.seek(size: 13, weight: .bold))
                    .foregroundStyle(TradeTheme.ink)
                    .frame(width: 34, height: 34)
                    .background(TradeTheme.tile)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            Spacer()

            Text("Create Post")
                .font(.tradeScreenTitle)
                .foregroundStyle(TradeTheme.ink)

            Spacer()

            Button {
                Task { await submitPost() }
            } label: {
                if postStore.isPosting {
                    ProgressView()
                        .controlSize(.mini)
                        .tint(TradeTheme.paper)
                        .frame(width: 62, height: 34)
                        .background(TradeTheme.ink)
                        .clipShape(Capsule())
                } else {
                    Text("Post")
                        .font(.seek(size: 14, weight: .bold))
                        .foregroundStyle(canPost ? TradeTheme.paper : TradeTheme.muted)
                        .frame(width: 62, height: 34)
                        .background(canPost ? TradeTheme.ink : TradeTheme.tile)
                        .clipShape(Capsule())
                }
            }
            .disabled(!canPost || postStore.isPosting)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .background(TradeTheme.paper)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(TradeTheme.line)
                .frame(height: 1)
        }
    }

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Type")
                .font(.seek(size: 12, weight: .bold))
                .foregroundStyle(TradeTheme.muted)
                .textCase(.uppercase)
            HStack(spacing: 8) {
                ForEach(ComposerMode.allCases) { item in
                    Button {
                        withAnimation(.snappy) {
                            mode = item
                            selectedTradeId = selectedTradeId ?? openTrades.first?.id
                        }
                    } label: {
                        Text(item.title)
                            .font(.seek(size: 13, weight: .bold))
                            .foregroundStyle(mode == item ? TradeTheme.paper : TradeTheme.ink)
                            .frame(maxWidth: .infinity)
                            .frame(height: 38)
                            .background(mode == item ? TradeTheme.ink : TradeTheme.tile)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var activeTradePicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Active Trade")
                .font(.seek(size: 12, weight: .bold))
                .foregroundStyle(TradeTheme.muted)
                .textCase(.uppercase)

            if tradeStore.isLoading && openTrades.isEmpty {
                HStack(spacing: 10) {
                    ProgressView()
                        .tint(TradeTheme.ink)
                    Text("Loading verified trades")
                        .font(.seek(size: 13, weight: .regular))
                        .foregroundStyle(TradeTheme.muted)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(TradeTheme.panel)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if openTrades.isEmpty {
                Text("No open verified trades found. Sync a brokerage account first.")
                    .font(.seek(size: 13, weight: .regular))
                    .foregroundStyle(TradeTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(TradeTheme.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                VStack(spacing: 0) {
                    ForEach(openTrades) { trade in
                        Button {
                            selectedTradeId = trade.id
                        } label: {
                            verifiedTradeRow(trade)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(TradeTheme.panel)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(TradeTheme.line, lineWidth: 1)
                )
            }
        }
    }

    private var composerBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                TraderAvatar(profile: author, size: 36)
                VStack(alignment: .leading, spacing: 8) {
                    Text(author.handle.replacingOccurrences(of: "@", with: ""))
                        .font(.tradeDisplayName)
                        .foregroundStyle(TradeTheme.ink)
                    TextField(mode.placeholder, text: $bodyText, axis: .vertical)
                        .font(.tradePostBody)
                        .foregroundStyle(TradeTheme.ink)
                        .tint(TradeTheme.ink)
                        .lineLimit(4...12)
                        .focused($isBodyFocused)
                }
            }
            .padding(14)
            .background(TradeTheme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func verifiedTradeRow(_ trade: SeekTradeCandidate) -> some View {
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
                        .background(TradeTheme.tile)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                Text(trade.instrumentName ?? trade.providerSourceType.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.seek(size: 11, weight: .regular))
                    .foregroundStyle(TradeTheme.muted)
                    .lineLimit(1)
            }
            Spacer()
            if selectedTradeId == trade.id {
                Image(systemName: "checkmark.circle.fill")
                    .font(.seek(size: 18, weight: .semibold))
                    .foregroundStyle(TradeTheme.gain)
            } else {
                Circle()
                    .stroke(TradeTheme.line, lineWidth: 1)
                    .frame(width: 18, height: 18)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 58)
    }

    private func submitPost() async {
        let created: GrowHousePost?
        switch mode {
        case .general:
            created = await postStore.createGeneralPost(body: bodyText)
        case .activeTrade:
            guard let selectedTradeId else { return }
            created = await postStore.createVerifiedTradePost(candidateId: selectedTradeId, body: bodyText)
        }

        if created != nil {
            bodyText = ""
            dismiss()
        }
    }

    private func sideTint(_ trade: SeekTradeCandidate) -> Color {
        trade.side.lowercased() == "sell" || trade.side.lowercased() == "short" ? TradeTheme.loss : TradeTheme.gain
    }
}

private enum ComposerMode: String, CaseIterable, Identifiable {
    case general
    case activeTrade

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: "Post"
        case .activeTrade: "Active Trade"
        }
    }

    var placeholder: String {
        switch self {
        case .general:
            return "What are you watching?"
        case .activeTrade:
            return "Add context for this verified active trade..."
        }
    }
}

struct MetricPill: View {
    let title: String
    let value: String
    var tint: Color = TradeTheme.ink

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title.uppercased())
                .font(.seek(size: 10, weight: .bold))
                .foregroundStyle(TradeTheme.muted)
            Text(value)
                .font(.seek(size: 15, weight: .bold).monospacedDigit())
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
            HStack(alignment: .top, spacing: 10) {
                postAvatar

                VStack(alignment: .leading, spacing: 8) {
                    authorLine
                    postCopy
                    tradeContextLine
                    TradeTicketView(post: post, stock: stock)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    actionRow
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            Rectangle()
                .fill(TradeTheme.line)
                .frame(height: 1)
        }
        .background(TradeTheme.paper)
        .accessibilityElement(children: .contain)
    }

    private var postAvatar: some View {
        TraderAvatar(profile: author, size: 40)
            .overlay(alignment: .bottomTrailing) {
                Circle()
                    .fill(TradeTheme.ink)
                    .frame(width: 19, height: 19)
                    .overlay {
                        Image(systemName: "plus")
                            .font(.seek(size: 12, weight: .bold))
                            .foregroundStyle(TradeTheme.paper)
                    }
                    .overlay {
                        Circle()
                            .stroke(TradeTheme.paper, lineWidth: 2)
                    }
                    .offset(x: 4, y: 4)
            }
    }

    private var authorLine: some View {
        HStack(alignment: .center, spacing: 6) {
            Text(author.handle)
                .font(.seek(size: 14, weight: .bold))
                .foregroundStyle(TradeTheme.ink)
                .lineLimit(1)
            Text(post.postedAgo)
                .font(.seek(size: 13, weight: .regular))
                .foregroundStyle(TradeTheme.muted)
            Spacer(minLength: 0)
            Image(systemName: "ellipsis")
                .font(.seek(size: 18))
                .foregroundStyle(TradeTheme.muted)
        }
    }

    private var postCopy: some View {
        Text(postNarrative)
            .font(.seek(size: 14, weight: .regular))
            .lineSpacing(3)
            .foregroundStyle(TradeTheme.ink)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var tradeContextLine: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(tradeStatusPhrase)
                .font(.seek(size: 12, weight: .semibold))
                .foregroundStyle(TradeTheme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
            if let stats {
                Text("WR: \(winRateText(stats.winRate))")
                    .font(.seek(size: 11, weight: .bold))
                    .foregroundStyle(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(TradeTheme.gain))
            }
            Spacer(minLength: 0)
        }
    }

    private var postNarrative: String {
        "\(post.title)\n\(post.thesis)"
    }

    private var tradeStatusPhrase: String {
        if post.status.isClosed {
            return "\(post.status.rawValue) \(post.direction.rawValue.lowercased()) \(productName.lowercased()) in \(stock.symbol)"
        }
        return "Opened \(post.direction.rawValue.lowercased()) \(productName.lowercased()) in \(stock.symbol)"
    }

    private var productName: String {
        switch post.product {
        case .equity: "stock"
        case .futures: "future"
        case .options: "option"
        }
    }

    private var actionRow: some View {
        HStack(spacing: 26) {
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
                count: isReposted ? 1 : nil
            ) {
                withOptionalSpring {
                    isReposted.toggle()
                }
            }
            TradeActionButton(icon: "paperplane", count: shareCount) {}
            Spacer(minLength: 0)
        }
        .padding(.top, 2)
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

    private var shareCount: Int {
        max(1, post.comments / 2)
    }
}

struct TradeTicketView: View {
    let post: TradeIdea
    let stock: StockInstrument
    @State private var pulseOpenDot = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 8) {
                HStack(spacing: 8) {
                    Text(String(stock.symbol.prefix(1)))
                        .font(.seek(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(AvatarColor.color(for: stock.id))
                        .clipShape(RoundedRectangle(cornerRadius: 5))

                    Text(instrumentTitle)
                        .font(.seek(size: 14, weight: .semibold))
                        .foregroundStyle(TradeTheme.ink)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(2)

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
                        .layoutPriority(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Spacer(minLength: 6)
                HStack(spacing: 5) {
                    if post.status == .active {
                        OpenTradePulseDot(isPulsing: pulseOpenDot)
                    }
                    Text(statusLabel)
                        .font(.tradeHandle)
                        .foregroundStyle(TradeTheme.ink)
                }
                .padding(.top, 1)
            }

            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(pnlTitle)
                        .font(.tradeActionCount)
                        .foregroundStyle(TradeTheme.muted)
                    Text(returnText)
                        .font(.seek(size: 22, weight: .regular).monospacedDigit())
                        .foregroundStyle(pnlColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.66)
                    Text(pnlValue)
                        .font(.seek(size: 12, weight: .semibold).monospacedDigit())
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

            VStack(spacing: 8) {
                HStack(alignment: .top, spacing: 10) {
                    receiptMetric(title: "Entry Price", value: entryText)
                    receiptMetric(title: post.status.isClosed ? "Avg. Close Price" : "Mark Price", value: post.status.isClosed ? exitText : markText)
                }

                HStack(alignment: .top, spacing: 10) {
                    receiptMetric(title: post.status.isClosed ? "Close Time" : "Target", value: post.status.isClosed ? closeTimeText : targetText, tint: post.status.isClosed ? TradeTheme.muted : TradeTheme.gain)
                    receiptMetric(title: post.status.isClosed ? "Closed By" : "Stop", value: post.status.isClosed ? exitReason : stopText, tint: post.status.isClosed ? TradeTheme.muted : TradeTheme.loss)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(11)
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
                .font(.seek(size: 12, weight: .regular))
                .foregroundStyle(TradeTheme.muted)
            Text(value)
                .font(.seek(size: 13, weight: .regular).monospacedDigit())
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
            .font(.seek(size: 11, weight: .semibold))
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
        .font(.seek(size: 11, weight: .bold))
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
                .font(.seek(size: 12, weight: .bold))
            Text(stock.changePercent.percentText)
                .font(.seek(size: 11, weight: .bold).monospacedDigit())
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
                    .font(.seek(size: 15, weight: .semibold))
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

    var currencyText: String {
        "\(self < 0 ? "-" : "")$\(String(format: "%.2f", abs(self)))"
    }
}
