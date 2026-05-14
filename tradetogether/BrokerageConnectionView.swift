//
//  BrokerageConnectionView.swift
//  tradetogether
//
//  Created by Codex on 09/05/26.
//

import SwiftUI

struct BrokerageConnectionView: View {
    var showsSignOut = true
    @StateObject private var settings = SeekAPISettings.shared
    @State private var statusText = "Ready to sync verified trades"
    @State private var isLoading = false
    @State private var connections: [SeekBrokerageConnection] = []
    @State private var accounts: [SeekBrokerageAccount] = []
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var tradeStore: TradeStore

    private var api: SeekAPIClient {
        SeekAPIClient(settings: settings)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brokerageSummary

            if !visibleConnections.isEmpty {
                Divider().background(TradeTheme.line)
                brokeragesList
            }

            Divider().background(TradeTheme.line)
            actionBar
        }
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

    private var brokerageSummary: some View {
        HStack(alignment: .top, spacing: 12) {
            summaryIcon

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text("Brokerage Accounts")
                        .font(.seek(size: 15, weight: .bold))
                        .foregroundStyle(TradeTheme.ink)
                        .lineLimit(1)
                    statusBadge
                }

                Text(summaryText)
                    .font(.seek(size: 12, weight: .regular))
                    .foregroundStyle(TradeTheme.muted)
                    .lineLimit(2)

                if let errorText = tradeStore.errorText {
                    Text(errorText)
                        .font(.seek(size: 12, weight: .regular))
                        .foregroundStyle(TradeTheme.loss)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: 10)

            if isLoading || tradeStore.isLoading {
                ProgressView()
                    .controlSize(.mini)
                    .tint(TradeTheme.ink)
                    .padding(.top, 2)
            }
        }
        .padding(14)
    }

    private var summaryIcon: some View {
        ZStack {
            Circle()
                .fill(visibleConnections.isEmpty ? TradeTheme.tile : TradeTheme.spotifyGreen)
                .frame(width: 38, height: 38)
            Image(systemName: visibleConnections.isEmpty ? "link" : "building.columns")
                .font(.seek(size: 14, weight: .semibold))
                .foregroundStyle(visibleConnections.isEmpty ? TradeTheme.muted : TradeTheme.paper)
        }
    }

    private var statusBadge: some View {
        Text(statusBadgeText)
            .font(.seek(size: 10, weight: .bold))
            .foregroundStyle(statusTint)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(TradeTheme.tile)
            .clipShape(RoundedRectangle(cornerRadius: 5))
    }

    private var brokeragesList: some View {
        VStack(spacing: 0) {
            ForEach(visibleConnections) { connection in
                brokerageRow(connection)
                if connection.id != visibleConnections.last?.id {
                    Divider().background(TradeTheme.line).padding(.leading, 66)
                }
            }
        }
    }

    private func brokerageRow(_ connection: SeekBrokerageConnection) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(connection.disabled ? TradeTheme.tile : TradeTheme.spotifyGreen)
                    .frame(width: 38, height: 38)
                Text(connectionInitials(connection))
                    .font(.seek(size: 13, weight: .black))
                    .foregroundStyle(connection.disabled ? TradeTheme.muted : TradeTheme.paper)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(connection.brokerageName ?? "Brokerage")
                    .font(.seek(size: 13, weight: .bold))
                    .foregroundStyle(TradeTheme.ink)
                    .lineLimit(1)
                Text(brokerageDetailText(for: connection))
                    .font(.seek(size: 11, weight: .regular))
                    .foregroundStyle(TradeTheme.muted)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            Button {
                Task {
                    await perform {
                        try await removeConnection(connection)
                    }
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(TradeTheme.loss)
                    .frame(width: 30, height: 30)
                    .background(TradeTheme.tile)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(isLoading || tradeStore.isLoading)
        }
        .padding(.horizontal, 14)
        .frame(height: 62)
    }

    private var actionBar: some View {
        HStack(spacing: 8) {
            brokerageButton(visibleConnections.isEmpty ? "Connect Brokerage" : "Add Brokerage", icon: "plus") {
                try await connectBroker()
            }

            if !visibleConnections.isEmpty {
                brokerageButton("Sync", icon: "arrow.clockwise") {
                    try await syncAccounts()
                }
            }

            if showsSignOut {
                brokerageButton("Sign Out", icon: "rectangle.portrait.and.arrow.right", tint: TradeTheme.loss) {
                    settings.signOut()
                    connections = []
                    accounts = []
                    tradeStore.clear()
                    statusText = "Signed out"
                }
            }
        }
        .padding(10)
    }

    private func brokerageButton(
        _ title: String,
        icon: String,
        tint: Color = TradeTheme.ink,
        action: @escaping () async throws -> Void
    ) -> some View {
        Button {
            Task {
                await perform(action)
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(.seek(size: 12, weight: .bold))
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .frame(height: 34)
            .background(TradeTheme.tile)
            .clipShape(RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
        .disabled(isLoading || tradeStore.isLoading)
    }

    private var summaryText: String {
        if visibleConnections.isEmpty {
            return "Connect a brokerage to sync verified positions."
        }
        if visibleConnections.contains(where: \.disabled) {
            return "One brokerage needs attention before new trades can sync."
        }
        if let lastSyncedAt = tradeStore.lastSyncedAt {
            return "\(visibleConnections.count) brokerage\(visibleConnections.count == 1 ? "" : "s"), \(accounts.count) account\(accounts.count == 1 ? "" : "s") - updated \(lastSyncedAt.relativeSyncText)"
        }
        return "\(visibleConnections.count) brokerage\(visibleConnections.count == 1 ? "" : "s"), \(accounts.count) account\(accounts.count == 1 ? "" : "s") connected"
    }

    private var statusBadgeText: String {
        if visibleConnections.isEmpty { return "Not connected" }
        if visibleConnections.contains(where: \.disabled) { return "Reconnect" }
        if tradeStore.errorText != nil { return "Error" }
        return "Live"
    }

    private var statusTint: Color {
        if visibleConnections.isEmpty { return TradeTheme.muted }
        if visibleConnections.contains(where: \.disabled) || tradeStore.errorText != nil { return TradeTheme.loss }
        return TradeTheme.gain
    }

    private var visibleConnections: [SeekBrokerageConnection] {
        deduplicatedConnections(connections)
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
        guard let result = await tradeStore.syncAllAccounts() else {
            statusText = tradeStore.statusText ?? "Sync failed"
            return
        }
        connections = deduplicatedConnections(result.connections)
        accounts = result.accounts
        statusText = "Synced \(visibleConnections.count) brokerages and \(accounts.count) accounts"
    }

    private func loadConnectedAccounts() async {
        guard settings.isAuthenticated else { return }
        do {
            async let loadedConnections = api.connections()
            async let loadedAccounts = api.accounts()
            connections = deduplicatedConnections(try await loadedConnections)
            accounts = try await loadedAccounts
            settings.brokerageConnected = !visibleConnections.isEmpty
            if !visibleConnections.isEmpty {
                statusText = "\(visibleConnections.count) brokerage connected, \(accounts.count) accounts ready"
            }
        } catch {
            statusText = error.localizedDescription
        }
    }

    private func removeConnection(_ connection: SeekBrokerageConnection) async throws {
        try await api.removeConnection(id: connection.id)
        connections.removeAll { $0.id == connection.id || connectionKey($0) == connectionKey(connection) }
        accounts.removeAll { $0.brokerageConnectionId == connection.id }
        tradeStore.clear()
        settings.brokerageConnected = !visibleConnections.isEmpty
        statusText = "Removed \(connection.brokerageName ?? "brokerage")"
    }

    private func brokerageDetailText(for connection: SeekBrokerageConnection) -> String {
        if connection.disabled {
            return "Needs reconnection"
        }

        let accountCount = accounts.filter { account in
            guard let brokerageConnectionId = account.brokerageConnectionId else { return false }
            return brokerageConnectionId == connection.id
        }.count
        if accountCount > 0 {
            return "\(accountCount) account\(accountCount == 1 ? "" : "s") connected"
        }
        return "Connected"
    }

    private func connectionInitials(_ connection: SeekBrokerageConnection?) -> String {
        let source = connection?.brokerageName ?? connection?.brokerageSlug ?? "GH"
        let pieces = source.split(separator: " ")
        if pieces.count > 1 {
            return pieces.prefix(2).compactMap { $0.first }.map(String.init).joined().uppercased()
        }
        return String(source.prefix(2)).uppercased()
    }

    private func deduplicatedConnections(_ source: [SeekBrokerageConnection]) -> [SeekBrokerageConnection] {
        var chosen: [String: SeekBrokerageConnection] = [:]
        var order: [String] = []

        for connection in source {
            let key = connectionKey(connection)
            if let existing = chosen[key] {
                if existing.disabled && !connection.disabled {
                    chosen[key] = connection
                }
            } else {
                chosen[key] = connection
                order.append(key)
            }
        }

        return order.compactMap { chosen[$0] }
    }

    private func connectionKey(_ connection: SeekBrokerageConnection) -> String {
        let raw = connection.brokerageSlug ?? connection.brokerageName ?? connection.id
        return raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}

private extension Date {
    var relativeSyncText: String {
        let elapsed = max(0, Int(Date().timeIntervalSince(self)))
        if elapsed < 60 {
            return "just now"
        }
        let minutes = elapsed / 60
        if minutes < 60 {
            return "\(minutes)m ago"
        }
        let hours = minutes / 60
        if hours < 24 {
            return "\(hours)h ago"
        }
        let days = hours / 24
        return "\(days)d ago"
    }
}
