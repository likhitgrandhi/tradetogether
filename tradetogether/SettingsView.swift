//
//  SettingsView.swift
//  tradetogether
//
//  Created by Codex on 10/05/26.
//

import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = SeekAPISettings.shared
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var tradeStore: TradeStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                settingsHeader

                SettingsSection(title: "Trading Accounts", subtitle: "Brokerage connections and verified trade sync") {
                    BrokerageConnectionView(showsSignOut: false)
                }

                SettingsSection(title: "App", subtitle: "GrowHouse preferences") {
                    VStack(spacing: 0) {
                        settingsRow(icon: "bell", title: "Notifications", value: "Off")
                        Divider().background(TradeTheme.line)
                        settingsRow(icon: "shield", title: "Privacy", value: "Standard")
                        Divider().background(TradeTheme.line)
                        settingsRow(icon: "paintpalette", title: "Appearance", value: "System")
                    }
                    .background(TradeTheme.panel)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(TradeTheme.line, lineWidth: 1)
                    )
                }

                SettingsSection(title: "Account", subtitle: settings.authEmail.isEmpty ? "Signed in" : settings.authEmail) {
                    Button {
                        settings.signOut()
                        tradeStore.clear()
                        dismiss()
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.seek(size: 18, weight: .semibold))
                                .foregroundStyle(TradeTheme.loss)
                                .frame(width: 28)
                            Text("Log out")
                                .font(.seek(size: 15, weight: .bold))
                                .foregroundStyle(TradeTheme.loss)
                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 52)
                        .background(TradeTheme.panel)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(TradeTheme.line, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(TradeTheme.paper.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var settingsHeader: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.seek(size: 22, weight: .semibold))
                        .foregroundStyle(TradeTheme.ink)
                        .frame(width: 44, height: 44)
                        .background(TradeTheme.tile)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Spacer()

                UpDownLogo()

                Spacer()

                Color.clear
                    .frame(width: 44, height: 44)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Settings")
                    .font(.seek(size: 28, weight: .bold))
                    .foregroundStyle(TradeTheme.ink)
                Text("Manage brokerage sync, account access, and app preferences.")
                    .font(.seek(size: 14, weight: .regular))
                    .foregroundStyle(TradeTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 6)
    }

    private func settingsRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.seek(size: 17, weight: .semibold))
                .foregroundStyle(TradeTheme.ink)
                .frame(width: 28)
            Text(title)
                .font(.seek(size: 15, weight: .semibold))
                .foregroundStyle(TradeTheme.ink)
            Spacer()
            Text(value)
                .font(.seek(size: 14, weight: .regular))
                .foregroundStyle(TradeTheme.muted)
            Image(systemName: "chevron.right")
                .font(.seek(size: 13, weight: .semibold))
                .foregroundStyle(TradeTheme.tertiary)
        }
        .padding(.horizontal, 14)
        .frame(height: 52)
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.seek(size: 15, weight: .bold))
                    .foregroundStyle(TradeTheme.ink)
                Text(subtitle)
                    .font(.seek(size: 13, weight: .regular))
                    .foregroundStyle(TradeTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            content
        }
    }
}
