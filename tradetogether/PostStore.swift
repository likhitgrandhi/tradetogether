import Combine
import Foundation

@MainActor
final class PostStore: ObservableObject {
    @Published var feedPosts: [GrowHousePost] = []
    @Published var myPosts: [GrowHousePost] = []
    @Published var isLoading = false
    @Published var isPosting = false
    @Published var errorText: String?
    @Published var postingErrorText: String?

    func loadFeed() async {
        isLoading = true
        defer { isLoading = false }

        do {
            feedPosts = try await SeekAPIClient(settings: SeekAPISettings.shared).feedPosts()
            errorText = nil
        } catch {
            errorText = cleanError(error)
        }
    }

    func loadMyPosts() async {
        let settings = SeekAPISettings.shared
        guard settings.isAuthenticated else {
            myPosts = []
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            myPosts = try await SeekAPIClient(settings: settings).myPosts()
            errorText = nil
        } catch {
            errorText = cleanError(error)
        }
    }

    func createGeneralPost(body: String) async -> GrowHousePost? {
        await createPost(body: body, verifiedTradeCandidateId: nil)
    }

    func createVerifiedTradePost(candidateId: String, body: String) async -> GrowHousePost? {
        await createPost(body: body, verifiedTradeCandidateId: candidateId)
    }

    func clearPostingError() {
        postingErrorText = nil
    }

    private func createPost(body: String, verifiedTradeCandidateId: String?) async -> GrowHousePost? {
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBody.isEmpty else {
            postingErrorText = "Write something before posting."
            return nil
        }

        isPosting = true
        defer { isPosting = false }

        do {
            let post = try await SeekAPIClient(settings: SeekAPISettings.shared).createPost(
                body: trimmedBody,
                verifiedTradeCandidateId: verifiedTradeCandidateId
            )
            upsert(post)
            postingErrorText = nil
            return post
        } catch {
            postingErrorText = cleanPostingError(error)
            return nil
        }
    }

    private func upsert(_ post: GrowHousePost) {
        feedPosts.removeAll { $0.id == post.id }
        feedPosts.insert(post, at: 0)

        myPosts.removeAll { $0.id == post.id }
        myPosts.insert(post, at: 0)
    }

    private func cleanError(_ error: Error) -> String {
        let text = error.localizedDescription
        if text.localizedCaseInsensitiveContains("bearer") ||
            text.localizedCaseInsensitiveContains("401") ||
            text.localizedCaseInsensitiveContains("session") {
            return "Sign in again, then try posting."
        }
        if text.count > 120 {
            return "Something went wrong. Check your connection and try again."
        }
        return text
    }

    private func cleanPostingError(_ error: Error) -> String {
        if let apiError = error as? SeekAPIError {
            switch apiError {
            case .authenticationExpired, .missingAccessToken:
                return "Your session expired. Sign in again, then try posting."
            case let .httpStatus(status, body):
                return cleanPostHTTPError(status: status, body: body)
            case .invalidURL, .invalidResponse:
                return "Could not read the posting response. Try again."
            case .missingSupabaseAnonKey, .missingAuthSession:
                return "Sign in is not ready. Try signing in again."
            }
        }

        let text = error.localizedDescription
        if text.localizedCaseInsensitiveContains("network") ||
            text.localizedCaseInsensitiveContains("internet") ||
            text.localizedCaseInsensitiveContains("timed out") {
            return "Could not reach the server. Check your connection and try again."
        }
        if text.localizedCaseInsensitiveContains("bearer") ||
            text.localizedCaseInsensitiveContains("401") ||
            text.localizedCaseInsensitiveContains("session") {
            return "Your session expired. Sign in again, then try posting."
        }
        return "Could not publish this post. Try again."
    }

    private func cleanPostHTTPError(status: Int, body: String?) -> String {
        let serverMessage = extractServerError(from: body)

        if status == 400 {
            if serverMessage.localizedCaseInsensitiveContains("open verified trades") {
                return "Only open verified trades can be posted. Sync trades and choose an active position."
            }
            if serverMessage.localizedCaseInsensitiveContains("invalid post body") {
                return "Write something before posting."
            }
            return "Check the post details and try again."
        }
        if status == 401 || status == 403 {
            return "Your session expired. Sign in again, then try posting."
        }
        if status == 404 {
            return "That trade is no longer available. Sync trades and choose it again."
        }
        if status >= 500 {
            return "Posting is temporarily unavailable. Try again in a moment."
        }

        return serverMessage.isEmpty ? "Could not publish this post. Try again." : serverMessage
    }

    private func extractServerError(from body: String?) -> String {
        guard
            let body,
            let data = body.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return body ?? ""
        }
        return (object["error"] as? String) ?? (object["message"] as? String) ?? ""
    }
}
