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
            Color.black.ignoresSafeArea()
            GrowHouseMark(size: 150, foreground: .black, background: TradeTheme.gain)
                .shadow(color: TradeTheme.gain.opacity(0.20), radius: 28, x: 0, y: 16)
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
        .onOpenURL { _ in
            guard step == .connectBrokerage else { return }
            Task {
                await syncAfterPortalReturn()
            }
        }
        .task {
            await primeMobileConfiguration()
        }
        .preferredColorScheme(.light)
    }

    private var onboardingBackground: some View {
        ZStack {
            Color(red: 0.985, green: 0.982, blue: 0.988)
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
                    .foregroundStyle(Color.black)
                    .frame(width: 56, height: 56)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.06), radius: 18, x: 0, y: 10)
            }
            .buttonStyle(.plain)
            .opacity(settings.isAuthenticated ? 1 : 0)

            Spacer()

            Text("GrowHouse")
                .font(.seek(size: 18, weight: .bold))
                .foregroundStyle(Color.black)

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
            GrowHouseMark(size: 78, foreground: .white, background: .black)

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
                .foregroundStyle(Color.black.opacity(0.86))
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
                        .foregroundStyle(Color.black.opacity(0.72))
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
                    .foregroundStyle(Color.black.opacity(0.86))
                Text(email)
                    .font(.seek(size: 14, weight: .regular))
                    .foregroundStyle(Color.black.opacity(0.54))
                    .lineLimit(1)
            }

            VStack(spacing: 14) {
                SecureField("Password", text: $password)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(.seek(size: 16, weight: .regular))
                    .foregroundStyle(Color.black)
                    .padding(.horizontal, 16)
                    .frame(height: 56)
                    .background(Color.white.opacity(0.78))
                    .overlay(
                        RoundedRectangle(cornerRadius: 9)
                            .stroke(Color.black.opacity(0.13), lineWidth: 1)
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
                        .foregroundStyle(Color.black.opacity(0.72))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var brokerageStep: some View {
        VStack(spacing: 24) {
            Text("Connect your brokerage")
                .font(.seek(size: 27, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.88))
                .multilineTextAlignment(.center)

            Text("GrowHouse uses SnapTrade to verify trades from your accounts. You choose what to connect, and you can sync again anytime.")
                .font(.seek(size: 15, weight: .regular))
                .foregroundStyle(Color.black.opacity(0.62))
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 18) {
                trustRow(icon: "link", title: "Connect once", body: "Open SnapTrade, pick a brokerage, and return to GrowHouse.")
                trustRow(icon: "lock.shield", title: "You stay in control", body: "We use verified account data to build your private trade history.")
            }
            .padding(18)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.black.opacity(0.08), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.04), radius: 22, x: 0, y: 12)

            VStack(spacing: 12) {
                primaryButton(accounts.isEmpty ? "Connect brokerage" : "Continue") {
                    Task {
                        if accounts.isEmpty {
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
                    Text("I connected, sync now")
                        .font(.seek(size: 15, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.76))
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
                        .foregroundStyle(Color.black.opacity(0.52))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var bottomStatus: some View {
        VStack(spacing: 10) {
            if isLoading {
                ProgressView()
                    .tint(Color.black)
            }

            if let statusText {
                Text(statusText)
                    .font(.seek(size: 13, weight: .regular))
                    .foregroundStyle(Color.black.opacity(0.58))
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
            .foregroundStyle(Color.black)
            .padding(.horizontal, 16)
            .frame(height: 56)
            .background(Color.white.opacity(0.78))
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(Color.black.opacity(0.13), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 9))
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.seek(size: 18, weight: .bold))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(Color.black)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    private func trustRow(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.black)
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.seek(size: 16, weight: .bold))
                    .foregroundStyle(Color.black)
                Text(body)
                    .font(.seek(size: 15, weight: .regular))
                    .foregroundStyle(Color.black.opacity(0.58))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
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
            step = .connectBrokerage
        } catch {
            statusText = error.localizedDescription
        }
    }

    private func loadMobileConfigIfNeeded() async throws {
        if settings.hasAuthConfiguration { return }
        let config = try await api.mobileConfig()
        settings.apply(mobileConfig: config)
        guard config.authConfigured else {
            throw SeekAPIError.missingSupabaseAnonKey
        }
    }

    private func primeMobileConfiguration() async {
        guard !settings.hasAuthConfiguration else { return }
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
            accounts = result.1
            syncedTrades = result.2
            settings.brokerageConnected = !accounts.isEmpty
            statusText = accounts.isEmpty
                ? "No brokerage account found yet. Finish SnapTrade connection, then sync again."
                : "Synced \(accounts.count) accounts and \(syncedTrades.count) trades"

            if !accounts.isEmpty {
                finishOnboarding()
            }
        } catch {
            statusText = error.localizedDescription
        }
    }

    private func finishOnboarding() {
        settings.onboardingCompleted = true
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
            Image(systemName: "leaf.fill")
                .font(.system(size: size * 0.42, weight: .black))
                .foregroundStyle(foreground)
                .rotationEffect(.degrees(-20))
                .offset(x: -size * 0.04, y: size * 0.02)
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: size * 0.30, weight: .bold))
                .foregroundStyle(foreground)
                .offset(x: size * 0.08, y: size * 0.08)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("GrowHouse")
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
                        context.fill(Path(ellipseIn: rect), with: .color(.black.opacity(0.08)))
                        y += spacing
                    }
                    x += spacing
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }
}
