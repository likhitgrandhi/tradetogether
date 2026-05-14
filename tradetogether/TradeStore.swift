import Combine
import Foundation

@MainActor
final class TradeStore: ObservableObject {
    @Published var trades: [SeekTradeCandidate] = []
    @Published var isLoading = false
    @Published var statusText: String?
    @Published var errorText: String?
    @Published var lastSyncedAt: Date?

    private var lastFetched: Date?
    private let staleInterval: TimeInterval = 120

    private var isStale: Bool {
        guard let lastFetched else { return true }
        return Date().timeIntervalSince(lastFetched) > staleInterval
    }

    func load(force: Bool = false) async {
        guard isStale || force else { return }
        let settings = SeekAPISettings.shared
        guard settings.isAuthenticated else {
            clear()
            return
        }

        isLoading = true
        defer { isLoading = false }

        let api = SeekAPIClient(settings: settings)
        do {
            let fresh = try await api.tradeCandidates()
            update(with: fresh)
        } catch {
            if let apiError = error as? SeekAPIError, case .authenticationExpired = apiError {
                clear()
                return
            }
            errorText = error.localizedDescription
            statusText = error.localizedDescription
        }
    }

    func syncAllAccounts() async -> (
        connections: [SeekBrokerageConnection],
        accounts: [SeekBrokerageAccount]
    )? {
        let settings = SeekAPISettings.shared
        guard settings.isAuthenticated else {
            clear()
            return nil
        }

        isLoading = true
        defer { isLoading = false }

        let api = SeekAPIClient(settings: settings)
        do {
            let result = try await api.syncAllAccounts()
            settings.brokerageConnected = !result.0.isEmpty
            update(with: result.2)
            return (result.0, result.1)
        } catch {
            if let apiError = error as? SeekAPIError, case .authenticationExpired = apiError {
                clear()
                return nil
            }
            errorText = error.localizedDescription
            statusText = error.localizedDescription
            return nil
        }
    }

    func update(with freshTrades: [SeekTradeCandidate]) {
        let uniqueTrades = deduplicated(freshTrades)
        trades = uniqueTrades
        let now = Date()
        lastFetched = now
        lastSyncedAt = now
        errorText = nil
        statusText = uniqueTrades.isEmpty ? "No synced trades found" : "\(uniqueTrades.count) synced trades"
    }

    func clear() {
        trades = []
        lastFetched = nil
        lastSyncedAt = nil
        statusText = nil
        errorText = nil
    }

    private func deduplicated(_ candidates: [SeekTradeCandidate]) -> [SeekTradeCandidate] {
        var seenOpenPositions = Set<String>()
        var uniqueCandidates: [SeekTradeCandidate] = []

        for candidate in candidates {
            guard candidate.status.lowercased() == "open",
                  ["position", "option_position"].contains(candidate.providerSourceType),
                  let symbol = candidate.symbol?.normalizedTradeSymbol,
                  !symbol.isEmpty else {
                uniqueCandidates.append(candidate)
                continue
            }

            let key = "\(candidate.providerSourceType):\(symbol)"
            if seenOpenPositions.insert(key).inserted {
                uniqueCandidates.append(candidate)
            }
        }

        return uniqueCandidates
    }
}

private extension String {
    var normalizedTradeSymbol: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
            .filter { !$0.isWhitespace }
    }
}
