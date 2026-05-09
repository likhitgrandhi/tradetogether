//
//  BrokerageConnectionView.swift
//  tradetogether
//
//  Created by Codex on 09/05/26.
//

import SwiftUI

struct BrokerageConnectionView: View {
    @StateObject private var settings = SeekAPISettings.shared
    @State private var statusText = "Ready to sync verified trades"
    @State private var isLoading = false
    @State private var connections: [SeekBrokerageConnection] = []
    @State private var accounts: [SeekBrokerageAccount] = []
    @State private var candidates: [SeekTradeCandidate] = []
    @Environment(\.openURL) private var openURL

    private var api: SeekAPIClient {
        SeekAPIClient(settings: settings)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Connected Brokerage")
                        .font(.seek(size: 15, weight: .bold))
                        .foregroundStyle(TradeTheme.ink)
                    Text(statusText)
                        .font(.seek(size: 13, weight: .regular))
                        .foregroundStyle(TradeTheme.muted)
                        .lineLimit(2)
                }
                Spacer()
                if isLoading {
                    ProgressView()
                        .tint(TradeTheme.ink)
                }
            }

            if let connection = connections.first {
                connectionCard(connection)
            }

            HStack(spacing: 8) {
                if connections.isEmpty {
                    brokerageButton("Connect") {
                        try await connectBroker()
                    }
                } else {
                    brokerageButton("Sync") {
                        try await syncAccounts()
                    }
                    brokerageButton("Remove") {
                        try await removeConnection()
                    }
                }
                brokerageButton("Sign Out") {
                    settings.signOut()
                    connections = []
                    accounts = []
                    candidates = []
                    statusText = "Signed out"
                }
            }

            if !accounts.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Accounts")
                        .font(.seek(size: 13, weight: .semibold))
                        .foregroundStyle(TradeTheme.muted)
                    ForEach(accounts) { account in
                        accountRow(account)
                    }
                }
            }

            if !candidates.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Verified Trades")
                        .font(.seek(size: 13, weight: .semibold))
                        .foregroundStyle(TradeTheme.muted)
                    ForEach(candidates.prefix(3)) { candidate in
                        candidateRow(candidate)
                    }
                }
            }
        }
        .padding(14)
        .background(TradeTheme.panel)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(TradeTheme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .task {
            await loadConnectedAccounts()
        }
    }

    private func brokerageButton(_ title: String, action: @escaping () async throws -> Void) -> some View {
        Button {
            Task {
                await perform(action)
            }
        } label: {
            Text(title)
                .font(.seek(size: 13, weight: .bold))
                .foregroundStyle(TradeTheme.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(TradeTheme.tile)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
    }

    private func connectionCard(_ connection: SeekBrokerageConnection) -> some View {
        HStack(spacing: 12) {
            Text(connectionInitials(connection))
                .font(.seek(size: 15, weight: .black))
                .foregroundStyle(TradeTheme.paper)
                .frame(width: 42, height: 42)
                .background(connection.disabled ? TradeTheme.muted : TradeTheme.spotifyGreen)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(connection.brokerageName ?? "Brokerage connected")
                    .font(.seek(size: 14, weight: .bold))
                    .foregroundStyle(TradeTheme.ink)
                Text(connection.disabled ? "Needs reconnection" : "\(accounts.count) account\(accounts.count == 1 ? "" : "s") connected")
                    .font(.seek(size: 12, weight: .regular))
                    .foregroundStyle(TradeTheme.muted)
            }

            Spacer()

            Text(connection.disabled ? "Action needed" : "Connected")
                .font(.seek(size: 12, weight: .bold))
                .foregroundStyle(connection.disabled ? TradeTheme.loss : TradeTheme.gain)
        }
        .padding(10)
        .background(TradeTheme.tile)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func accountRow(_ account: SeekBrokerageAccount) -> some View {
        Button {
            Task {
                await perform {
                    try await api.syncAccount(id: account.id)
                    candidates = try await api.tradeCandidates()
                    statusText = "Synced \(account.accountName ?? "account") trades"
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(account.accountName ?? "Brokerage account")
                        .font(.seek(size: 14, weight: .semibold))
                        .foregroundStyle(TradeTheme.ink)
                    Text([account.accountType, account.currencyCode].compactMap { $0 }.joined(separator: " - "))
                        .font(.seek(size: 12, weight: .regular))
                        .foregroundStyle(TradeTheme.muted)
                }
                Spacer()
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(TradeTheme.muted)
            }
            .padding(10)
            .background(TradeTheme.tile)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private func candidateRow(_ candidate: SeekTradeCandidate) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(candidate.status.capitalized) \(candidate.side.capitalized)")
                    .font(.seek(size: 14, weight: .semibold))
                    .foregroundStyle(TradeTheme.ink)
                Text(candidate.providerSourceType.replacingOccurrences(of: "_", with: " "))
                    .font(.seek(size: 12, weight: .regular))
                    .foregroundStyle(TradeTheme.muted)
            }
            Spacer()
            Text(candidate.returnPercent?.percentText ?? "Verified")
                .font(.seek(size: 14, weight: .bold))
                .foregroundStyle((candidate.returnPercent ?? 0) >= 0 ? TradeTheme.gain : TradeTheme.loss)
        }
        .padding(10)
        .background(TradeTheme.tile)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func perform(_ action: () async throws -> Void) async {
        isLoading = true
        defer { isLoading = false }
        do {
            try await action()
        } catch {
            statusText = error.localizedDescription
        }
    }

    private func checkHealth() async throws {
        let health = try await api.health()
        statusText = health.api.online ? "API online" : "API offline"
    }

    private func connectBroker() async throws {
        settings.resetAPIBaseURLToHostedDefault()
        try await api.registerSnapTradeUser()
        let portal = try await api.createPortalLink()
        guard let url = URL(string: portal.redirectURI) else {
            throw SeekAPIError.invalidURL
        }
        statusText = "Opening SnapTrade portal"
        openURL(url)
    }

    private func syncAccounts() async throws {
        settings.resetAPIBaseURLToHostedDefault()
        let result = try await api.syncAllAccounts()
        connections = result.0
        accounts = result.1
        candidates = result.2
        settings.brokerageConnected = !connections.isEmpty
        statusText = "Synced \(result.0.count) connections, \(result.1.count) accounts, and \(candidates.count) trades"
    }

    private func loadConnectedAccounts() async {
        guard settings.isAuthenticated else { return }
        do {
            async let loadedConnections = api.connections()
            async let loadedAccounts = api.accounts()
            async let loadedCandidates = api.tradeCandidates()
            connections = try await loadedConnections
            accounts = try await loadedAccounts
            candidates = try await loadedCandidates
            settings.brokerageConnected = !connections.isEmpty
            if !connections.isEmpty {
                statusText = "\(connections.count) brokerage connected, \(accounts.count) accounts, \(candidates.count) trades synced"
            }
        } catch {
            statusText = error.localizedDescription
        }
    }

    private func removeConnection() async throws {
        guard let connection = connections.first else { return }
        try await api.removeConnection(id: connection.id)
        connections = []
        accounts = []
        candidates = []
        settings.brokerageConnected = false
        statusText = "Brokerage connection removed"
    }

    private func connectionInitials(_ connection: SeekBrokerageConnection) -> String {
        let source = connection.brokerageName ?? connection.brokerageSlug ?? "GH"
        let pieces = source.split(separator: " ")
        if pieces.count > 1 {
            return pieces.prefix(2).compactMap { $0.first }.map(String.init).joined().uppercased()
        }
        return String(source.prefix(2)).uppercased()
    }
}
