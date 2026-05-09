//
//  SeekAPIClient.swift
//  tradetogether
//
//  Created by Codex on 09/05/26.
//

import Combine
import Foundation

private enum GrowHouseAPIConstants {
    static let defaultBaseURL = "https://growhouse-api.onrender.com/"
    static let defaultSupabaseURL = ""
    static let defaultSupabaseAnonKey = ""

    static func resolvedBaseURL(from storedValue: String?) -> String {
        let trimmed = storedValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else { return defaultBaseURL }

        let lowercase = trimmed.lowercased()
        if lowercase.contains("localhost") || lowercase.contains("127.0.0.1") || lowercase.contains("0.0.0.0") {
            return defaultBaseURL
        }

        return trimmed
    }
}

struct SeekAPIHealth: Decodable {
    struct Status: Decodable {
        let online: Bool
    }

    let api: Status
    let snaptrade: Status?
}

struct SeekAuthSession: Decodable {
    let accessToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
    }
}

struct SeekPortalLink: Decodable {
    let redirectURI: String
    let sessionId: String?
    let snapTradeUserId: String
}

struct GrowHouseMobileConfig: Decodable {
    let apiBaseURL: String
    let supabaseURL: String
    let supabaseAnonKey: String
    let iosDeepLinkScheme: String
    let authConfigured: Bool
}

struct SeekBrokerageConnection: Decodable, Identifiable {
    let id: String
    let brokerageName: String?
    let brokerageSlug: String?
    let disabled: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case brokerageName = "brokerage_name"
        case brokerageSlug = "brokerage_slug"
        case disabled
    }
}

struct SeekBrokerageAccount: Decodable, Identifiable {
    let id: String
    let accountName: String?
    let accountType: String?
    let currencyCode: String?

    enum CodingKeys: String, CodingKey {
        case id
        case accountName = "account_name"
        case accountType = "account_type"
        case currencyCode = "currency_code"
    }
}

struct SeekTradeCandidate: Decodable, Identifiable {
    let id: String
    let symbol: String?
    let instrumentName: String?
    let side: String
    let status: String
    let quantity: Double?
    let entryPrice: Double?
    let markPrice: Double?
    let exitPrice: Double?
    let realizedPnl: Double?
    let unrealizedPnl: Double?
    let returnPercent: Double?
    let providerSourceType: String

    enum CodingKeys: String, CodingKey {
        case id
        case symbol
        case instrumentName = "instrument_name"
        case side
        case status
        case quantity
        case entryPrice = "entry_price"
        case markPrice = "mark_price"
        case exitPrice = "exit_price"
        case realizedPnl = "realized_pnl"
        case unrealizedPnl = "unrealized_pnl"
        case returnPercent = "return_percent"
        case providerSourceType = "provider_source_type"
    }
}

@MainActor
final class SeekAPISettings: ObservableObject {
    static let shared = SeekAPISettings()

    @Published var apiBaseURL: String {
        didSet { UserDefaults.standard.set(apiBaseURL, forKey: Keys.apiBaseURL) }
    }

    @Published var accessToken: String {
        didSet { UserDefaults.standard.set(accessToken, forKey: Keys.accessToken) }
    }

    @Published var supabaseURL: String {
        didSet { UserDefaults.standard.set(supabaseURL, forKey: Keys.supabaseURL) }
    }

    @Published var supabaseAnonKey: String {
        didSet { UserDefaults.standard.set(supabaseAnonKey, forKey: Keys.supabaseAnonKey) }
    }

    @Published var authEmail: String {
        didSet { UserDefaults.standard.set(authEmail, forKey: Keys.authEmail) }
    }

    @Published var onboardingCompleted: Bool {
        didSet { UserDefaults.standard.set(onboardingCompleted, forKey: Keys.onboardingCompleted) }
    }

    @Published var brokerageConnected: Bool {
        didSet { UserDefaults.standard.set(brokerageConnected, forKey: Keys.brokerageConnected) }
    }

    private init() {
        apiBaseURL = GrowHouseAPIConstants.resolvedBaseURL(
            from: UserDefaults.standard.string(forKey: Keys.apiBaseURL)
        )
        accessToken = UserDefaults.standard.string(forKey: Keys.accessToken) ?? ""
        supabaseURL = UserDefaults.standard.string(forKey: Keys.supabaseURL) ?? GrowHouseAPIConstants.defaultSupabaseURL
        supabaseAnonKey = UserDefaults.standard.string(forKey: Keys.supabaseAnonKey) ?? GrowHouseAPIConstants.defaultSupabaseAnonKey
        authEmail = UserDefaults.standard.string(forKey: Keys.authEmail) ?? ""
        onboardingCompleted = UserDefaults.standard.bool(forKey: Keys.onboardingCompleted)
        brokerageConnected = UserDefaults.standard.bool(forKey: Keys.brokerageConnected)
    }

    var isAuthenticated: Bool {
        !accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasAuthConfiguration: Bool {
        !supabaseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !supabaseAnonKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func signOut() {
        accessToken = ""
        onboardingCompleted = false
        brokerageConnected = false
    }

    func apply(mobileConfig: GrowHouseMobileConfig) {
        if !mobileConfig.apiBaseURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            apiBaseURL = mobileConfig.apiBaseURL
        }
        supabaseURL = mobileConfig.supabaseURL
        supabaseAnonKey = mobileConfig.supabaseAnonKey
    }

    private enum Keys {
        static let apiBaseURL = "seek.apiBaseURL"
        static let accessToken = "seek.accessToken"
        static let supabaseURL = "seek.supabaseURL"
        static let supabaseAnonKey = "seek.supabaseAnonKey"
        static let authEmail = "seek.authEmail"
        static let onboardingCompleted = "growhouse.onboardingCompleted"
        static let brokerageConnected = "growhouse.brokerageConnected"
    }
}

struct SeekSupabaseAuthClient {
    let settings: SeekAPISettings

    func signIn(email: String, password: String) async throws -> SeekAuthSession {
        try await authenticate(path: "/auth/v1/token?grant_type=password", email: email, password: password)
    }

    func signUp(email: String, password: String) async throws -> SeekAuthSession {
        try await authenticate(path: "/auth/v1/signup", email: email, password: password)
    }

    private func authenticate(path: String, email: String, password: String) async throws -> SeekAuthSession {
        guard let baseURL = URL(string: settings.supabaseURL.trimmingCharacters(in: .whitespacesAndNewlines)),
              let url = URL(string: path, relativeTo: baseURL) else {
            throw SeekAPIError.invalidURL
        }
        guard !settings.supabaseAnonKey.isEmpty else {
            throw SeekAPIError.missingSupabaseAnonKey
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(settings.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(settings.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["email": email, "password": password])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SeekAPIError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw SeekAPIError.httpStatus(httpResponse.statusCode, String(data: data, encoding: .utf8))
        }

        do {
            return try JSONDecoder().decode(SeekAuthSession.self, from: data)
        } catch {
            throw SeekAPIError.missingAuthSession
        }
    }
}

struct SeekAPIClient {
    let settings: SeekAPISettings

    func health() async throws -> SeekAPIHealth {
        try await send(path: "/health", method: "GET", authenticated: false)
    }

    func mobileConfig() async throws -> GrowHouseMobileConfig {
        try await send(path: "/config/mobile", method: "GET", authenticated: false)
    }

    func registerSnapTradeUser() async throws {
        let _: EmptyResponse = try await send(path: "/snaptrade/users", method: "POST")
    }

    func createPortalLink() async throws -> SeekPortalLink {
        try await send(path: "/snaptrade/portal-link", method: "POST")
    }

    func syncConnections() async throws -> ([SeekBrokerageConnection], [SeekBrokerageAccount]) {
        let response: SyncConnectionsResponse = try await send(path: "/brokerage/connections/sync", method: "POST")
        return (response.connections, response.accounts)
    }

    func accounts() async throws -> [SeekBrokerageAccount] {
        let response: AccountsResponse = try await send(path: "/brokerage/accounts", method: "GET")
        return response.accounts
    }

    func syncAllAccounts() async throws -> ([SeekBrokerageConnection], [SeekBrokerageAccount], [SeekTradeCandidate]) {
        let result = try await syncConnections()
        for account in result.1 {
            try await syncAccount(id: account.id)
        }
        let candidates = try await tradeCandidates()
        return (result.0, result.1, candidates)
    }

    func syncAccount(id: String) async throws {
        let _: EmptyResponse = try await send(path: "/brokerage/accounts/\(id)/sync", method: "POST")
    }

    func tradeCandidates() async throws -> [SeekTradeCandidate] {
        let response: CandidatesResponse = try await send(path: "/trade-candidates", method: "GET")
        return response.candidates
    }

    private func send<Response: Decodable>(
        path: String,
        method: String,
        authenticated: Bool = true
    ) async throws -> Response {
        guard let url = URL(string: path, relativeTo: normalizedBaseURL) else {
            throw SeekAPIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if authenticated {
            guard !settings.accessToken.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw SeekAPIError.missingAccessToken
            }
            request.setValue("Bearer \(settings.accessToken)", forHTTPHeaderField: "Authorization")
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SeekAPIError.invalidResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw SeekAPIError.httpStatus(httpResponse.statusCode, String(data: data, encoding: .utf8))
        }
        if data.isEmpty {
            return EmptyResponse() as! Response
        }
        return try JSONDecoder().decode(Response.self, from: data)
    }

    private var normalizedBaseURL: URL {
        let text = settings.apiBaseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        return URL(string: text.hasSuffix("/") ? text : "\(text)/") ?? URL(string: GrowHouseAPIConstants.defaultBaseURL)!
    }
}

private struct EmptyResponse: Decodable {}

private struct SyncConnectionsResponse: Decodable {
    let connections: [SeekBrokerageConnection]
    let accounts: [SeekBrokerageAccount]
}

private struct AccountsResponse: Decodable {
    let accounts: [SeekBrokerageAccount]
}

private struct CandidatesResponse: Decodable {
    let candidates: [SeekTradeCandidate]
}

enum SeekAPIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case missingAccessToken
    case missingSupabaseAnonKey
    case missingAuthSession
    case httpStatus(Int, String?)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "The API URL is invalid."
        case .invalidResponse:
            "The server response was not readable."
        case .missingAccessToken:
            "Paste a Supabase access token before calling protected endpoints."
        case .missingSupabaseAnonKey:
            "GrowHouse sign in is not configured yet. Add SUPABASE_ANON_KEY to the backend environment."
        case .missingAuthSession:
            "Supabase did not return a session. Check whether email confirmation is required."
        case let .httpStatus(status, body):
            "Request failed with status \(status). \(body ?? "")"
        }
    }
}
