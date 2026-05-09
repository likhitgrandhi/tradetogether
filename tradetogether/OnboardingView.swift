//
//  OnboardingView.swift
//  tradetogether
//
//  Created by Codex on 09/05/26.
//

import SwiftUI
import UIKit

struct GrowHouseSplashView: View {
    var body: some View {
        ZStack {
            TradeTheme.spotifyBlack.ignoresSafeArea()
            GrowHouseMark(size: 156, foreground: TradeTheme.paper, background: TradeTheme.spotifyGreen)
                .shadow(color: TradeTheme.spotifyGreen.opacity(0.22), radius: 28, x: 0, y: 16)
        }
        .preferredColorScheme(.dark)
    }
}

struct OnboardingView: View {
    @StateObject private var settings = SeekAPISettings.shared
    @State private var step: OnboardingStep
    @State private var email: String
    @State private var password = ""
    @State private var isCreatingAccount = false
    @State private var isLoading = false
    @State private var statusText: String?
    @State private var connections: [SeekBrokerageConnection] = []
    @State private var accounts: [SeekBrokerageAccount] = []
    @State private var syncedTrades: [SeekTradeCandidate] = []
    @Environment(\.openURL) private var openURL

    init() {
        let settings = SeekAPISettings.shared
        _email = State(initialValue: settings.authEmail)
        if settings.isAuthenticated {
            _step = State(initialValue: .connectBrokerage)
        } else {
            _step = State(initialValue: .email)
        }
    }

    private var api: SeekAPIClient {
        SeekAPIClient(settings: settings)
    }

    var body: some View {
        ZStack {
            onboardingBackground
            VStack(spacing: 0) {
                onboardingHeader
                Spacer(minLength: 24)
                currentStep
                    .padding(.horizontal, 24)
                Spacer(minLength: 32)
                bottomStatus
            }
            .padding(.top, 8)
        }
        .contentShape(Rectangle())
        .dismissKeyboardOnBackgroundTap()
        .onOpenURL { _ in
            guard step == .connectBrokerage else { return }
            Task {
                await syncAfterPortalReturn()
            }
        }
        .task {
            await primeMobileConfiguration()
            await loadExistingBrokerageState()
        }
        .preferredColorScheme(.light)
    }

    private var onboardingBackground: some View {
        ZStack {
            TradeTheme.paper
                .ignoresSafeArea()
            DottedBackground()
                .opacity(0.45)
                .ignoresSafeArea()
        }
    }

    private var onboardingHeader: some View {
        HStack {
            Button {
                settings.signOut()
                step = .email
                password = ""
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(TradeTheme.ink)
                    .frame(width: 56, height: 56)
                    .background(TradeTheme.elevated)
                    .clipShape(Circle())
                    .shadow(color: TradeTheme.shadowSoft, radius: 18, x: 0, y: 10)
            }
            .buttonStyle(.plain)
            .opacity(settings.isAuthenticated ? 1 : 0)

            Spacer()

            Text("GrowHouse")
                .font(.seek(size: 18, weight: .bold))
                .foregroundStyle(TradeTheme.ink)

            Spacer()

            Color.clear
                .frame(width: 56, height: 56)
        }
        .padding(.horizontal, 24)
        .padding(.top, 6)
    }

    @ViewBuilder
    private var currentStep: some View {
        VStack(spacing: 28) {
            GrowHouseMark(size: 78, foreground: TradeTheme.paper, background: TradeTheme.ink)

            switch step {
            case .email:
                authIntro
            case .password:
                passwordStep
            case .connectBrokerage:
                brokerageStep
            }

        }
        .animation(.easeInOut(duration: 0.22), value: step)
    }

    private var authIntro: some View {
        VStack(spacing: 20) {
            Text("What is your email address?")
                .font(.seek(size: 25, weight: .semibold))
                .foregroundStyle(TradeTheme.ink.opacity(0.86))
                .multilineTextAlignment(.center)

            VStack(spacing: 14) {
                onboardingTextField("Enter your email address", text: $email, keyboard: .emailAddress)
                primaryButton("Continue with email") {
                    settings.authEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                    step = .password
                }
                .disabled(email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Button {
                    isCreatingAccount.toggle()
                } label: {
                    Text(isCreatingAccount ? "Create account mode" : "Already have an account")
                        .font(.seek(size: 15, weight: .regular))
                        .foregroundStyle(TradeTheme.ink.opacity(0.72))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var passwordStep: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text(isCreatingAccount ? "Create your password" : "Welcome back")
                    .font(.seek(size: 25, weight: .semibold))
                    .foregroundStyle(TradeTheme.ink.opacity(0.86))
                Text(email)
                    .font(.seek(size: 14, weight: .regular))
                    .foregroundStyle(TradeTheme.ink.opacity(0.54))
                    .lineLimit(1)
            }

            VStack(spacing: 14) {
                SecureField("Password", text: $password)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.seek(size: 16, weight: .regular))
                    .foregroundStyle(TradeTheme.ink)
                    .padding(.horizontal, 16)
                    .frame(height: 56)
                    .background(TradeTheme.elevated.opacity(0.78))
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(TradeTheme.line, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 9))

                primaryButton(isCreatingAccount ? "Create account" : "Sign in") {
                    Task {
                        await authenticate()
                    }
                }
                .disabled(password.count < 6 || isLoading)

                Button {
                    step = .email
                    password = ""
                } label: {
                    Text("Use a different email")
                        .font(.seek(size: 15, weight: .regular))
                        .foregroundStyle(TradeTheme.ink.opacity(0.72))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var brokerageStep: some View {
        VStack(spacing: 24) {
            ConnectedServicePair()

            Text("Connect your brokerage")
                .font(.seek(size: 27, weight: .semibold))
                .foregroundStyle(TradeTheme.ink.opacity(0.88))
                .multilineTextAlignment(.center)

            Text("GrowHouse uses SnapTrade to verify trades from your accounts. You choose what to connect, and you can sync again anytime.")
                .font(.seek(size: 15, weight: .regular))
                .foregroundStyle(TradeTheme.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 4)

            if let connection = connections.first {
                connectedBrokerageCard(connection)
            } else {
                VStack(alignment: .leading, spacing: 18) {
                    trustRow(icon: "link", title: "Connect once", body: "Open SnapTrade, pick a brokerage, and return to GrowHouse.")
                    trustRow(icon: "lock.shield", title: "You stay in control", body: "We use verified account data to build your private trade history.")
                }
                .padding(18)
                .background(TradeTheme.elevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(TradeTheme.line, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: TradeTheme.shadowSoft, radius: 22, x: 0, y: 12)
            }

            VStack(spacing: 12) {
                primaryButton(connections.isEmpty ? "Connect brokerage" : "Continue") {
                    Task {
                        if connections.isEmpty {
                            await connectBrokerage()
                        } else {
                            finishOnboarding()
                        }
                    }
                }
                .disabled(isLoading)

                Button {
                    Task {
                        await syncAfterPortalReturn()
                    }
                } label: {
                    Text(connections.isEmpty ? "I connected, sync now" : "Refresh connection")
                        .font(.seek(size: 15, weight: .semibold))
                        .foregroundStyle(TradeTheme.ink.opacity(0.76))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                }
                .buttonStyle(.plain)
                .disabled(isLoading)

                Button {
                    finishOnboarding()
                } label: {
                    Text("Skip for now")
                        .font(.seek(size: 14, weight: .regular))
                        .foregroundStyle(TradeTheme.ink.opacity(0.52))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var bottomStatus: some View {
        VStack(spacing: 10) {
            if isLoading {
                ProgressView()
                    .tint(TradeTheme.ink)
            }

            if let statusText {
                Text(statusText)
                    .font(.seek(size: 13, weight: .regular))
                    .foregroundStyle(TradeTheme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
        }
        .frame(minHeight: 54)
        .padding(.bottom, 18)
    }

    private func onboardingTextField(
        _ placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType
    ) -> some View {
        TextField(placeholder, text: text)
            .textInputAutocapitalization(.never)
            .keyboardType(keyboard)
            .autocorrectionDisabled()
            .font(.seek(size: 16, weight: .regular))
            .foregroundStyle(TradeTheme.ink)
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(TradeTheme.elevated.opacity(0.78))
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(TradeTheme.line, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 9))
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.seek(size: 18, weight: .bold))
                .foregroundStyle(TradeTheme.paper)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(TradeTheme.ink)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func trustRow(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(TradeTheme.ink)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.seek(size: 16, weight: .bold))
                    .foregroundStyle(TradeTheme.ink)
                Text(body)
                    .font(.seek(size: 15, weight: .regular))
                    .foregroundStyle(TradeTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func connectedBrokerageCard(_ connection: SeekBrokerageConnection) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Text(connectionInitials(connection))
                    .font(.seek(size: 16, weight: .black))
                    .foregroundStyle(TradeTheme.paper)
                    .frame(width: 46, height: 46)
                    .background(connection.disabled ? TradeTheme.muted : TradeTheme.spotifyGreen)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(connection.brokerageName ?? "Brokerage connected")
                        .font(.seek(size: 16, weight: .bold))
                        .foregroundStyle(TradeTheme.ink)
                    Text(connection.disabled ? "Needs reconnection" : "\(accounts.count) account\(accounts.count == 1 ? "" : "s") ready")
                        .font(.seek(size: 13, weight: .regular))
                        .foregroundStyle(TradeTheme.muted)
                }
                Spacer()
            }

            Button {
                Task {
                    await removeConnection(connection)
                }
            } label: {
                Text("Remove connection")
                    .font(.seek(size: 13, weight: .bold))
                    .foregroundStyle(TradeTheme.loss)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(TradeTheme.tile)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
        }
        .padding(16)
        .background(TradeTheme.elevated)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(TradeTheme.line, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: TradeTheme.shadowSoft, radius: 22, x: 0, y: 12)
    }

    private func authenticate() async {
        isLoading = true
        statusText = "Preparing secure sign in"
        defer { isLoading = false }

        do {
            try await loadMobileConfigIfNeeded()
            statusText = isCreatingAccount ? "Creating your GrowHouse account" : "Signing in"
            let auth = SeekSupabaseAuthClient(settings: settings)
            let session = isCreatingAccount
                ? try await auth.signUp(email: email, password: password)
                : try await auth.signIn(email: email, password: password)

            settings.authEmail = email
            settings.accessToken = session.accessToken
            statusText = "Signed in"
            await loadExistingBrokerageState()
            if connections.isEmpty {
                step = .connectBrokerage
            } else {
                finishOnboarding()
            }
        } catch {
            statusText = error.localizedDescription
        }
    }

    private func loadMobileConfigIfNeeded() async throws {
        settings.resetAPIBaseURLToHostedDefault()
        let config = try await api.mobileConfig()
        settings.apply(mobileConfig: config)
        guard config.authConfigured else {
            throw SeekAPIError.missingSupabaseAnonKey
        }
    }

    private func primeMobileConfiguration() async {
        settings.resetAPIBaseURLToHostedDefault()
        do {
            let config = try await api.mobileConfig()
            settings.apply(mobileConfig: config)
            statusText = config.authConfigured ? nil : "GrowHouse sign in is not configured yet."
        } catch {
            statusText = "Could not reach GrowHouse services. Check your connection and try again."
        }
    }

    private func connectBrokerage() async {
        isLoading = true
        statusText = "Preparing secure SnapTrade connection"
        defer { isLoading = false }

        do {
            try await api.registerSnapTradeUser()
            let portal = try await api.createPortalLink()
            guard let url = URL(string: portal.redirectURI) else {
                throw SeekAPIError.invalidURL
            }
            statusText = "Opening SnapTrade"
            openURL(url)
        } catch {
            statusText = error.localizedDescription
        }
    }

    private func syncAfterPortalReturn() async {
        isLoading = true
        statusText = "Checking connected accounts"
        defer { isLoading = false }

        do {
            let result = try await api.syncAllAccounts()
            connections = result.0
            accounts = result.1
            syncedTrades = result.2
            settings.brokerageConnected = !connections.isEmpty
            statusText = connections.isEmpty
                ? "No brokerage account found yet. Finish SnapTrade connection, then sync again."
                : "Synced \(accounts.count) accounts and \(syncedTrades.count) trades"

            if !connections.isEmpty {
                finishOnboarding()
            }
        } catch {
            statusText = error.localizedDescription
        }
    }

    private func loadExistingBrokerageState() async {
        guard settings.isAuthenticated else { return }
        do {
            async let loadedConnections = api.connections()
            async let loadedAccounts = api.accounts()
            connections = try await loadedConnections
            accounts = try await loadedAccounts
            settings.brokerageConnected = !connections.isEmpty
        } catch {
            statusText = error.localizedDescription
        }
    }

    private func removeConnection(_ connection: SeekBrokerageConnection) async {
        isLoading = true
        statusText = "Removing brokerage connection"
        defer { isLoading = false }

        do {
            try await api.removeConnection(id: connection.id)
            connections.removeAll { $0.id == connection.id }
            accounts = []
            syncedTrades = []
            settings.brokerageConnected = false
            statusText = "Connection removed"
        } catch {
            statusText = error.localizedDescription
        }
    }

    private func finishOnboarding() {
        settings.onboardingCompleted = true
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

private enum OnboardingStep {
    case email
    case password
    case connectBrokerage
}

private struct GrowHouseMark: View {
    let size: CGFloat
    let foreground: Color
    let background: Color

    var body: some View {
        ZStack {
            Circle()
                .fill(background)
            Image("UpDownLogo")
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(foreground)
                .scaledToFit()
                .frame(width: size * 0.56, height: size * 0.56)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("GrowHouse")
    }
}

private struct ConnectedServicePair: View {
    var body: some View {
        HStack(spacing: -10) {
            serviceAvatar(
                background: TradeTheme.spotifyGreen,
                imageName: "UpDownLogo",
                renderingMode: .template,
                foreground: TradeTheme.paper,
                scale: 0.54
            )
            serviceAvatar(
                background: TradeTheme.ink,
                imageName: "SnapTradeLogo",
                renderingMode: .original,
                foreground: TradeTheme.paper,
                scale: 0.68
            )
        }
        .accessibilityLabel("GrowHouse connects with SnapTrade")
    }

    private func serviceAvatar(
        background: Color,
        imageName: String,
        renderingMode: Image.TemplateRenderingMode,
        foreground: Color,
        scale: CGFloat
    ) -> some View {
        ZStack {
            Circle()
                .fill(background)
            Image(imageName)
                .resizable()
                .renderingMode(renderingMode)
                .foregroundStyle(foreground)
                .scaledToFit()
                .frame(width: 62 * scale, height: 62 * scale)
        }
        .frame(width: 62, height: 62)
        .overlay(
            Circle()
                .stroke(TradeTheme.paper, lineWidth: 4)
        )
        .shadow(color: TradeTheme.shadowSoft, radius: 14, x: 0, y: 8)
    }
}

private struct DottedBackground: View {
    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                let spacing: CGFloat = 30
                let radius: CGFloat = 1.7
                var x: CGFloat = 10
                while x < size.width {
                    var y: CGFloat = 10
                    while y < size.height {
                        let rect = CGRect(x: x, y: y, width: radius * 2, height: radius * 2)
                        context.fill(Path(ellipseIn: rect), with: .color(TradeTheme.ink.opacity(0.08)))
                        y += spacing
                    }
                    x += spacing
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}
