import Combine
import Foundation

@MainActor
final class PostStore: ObservableObject {
    @Published var feedPosts: [GrowHousePost] = []
    @Published var myPosts: [GrowHousePost] = []
    @Published var isLoading = false
    @Published var isPosting = false
    @Published var errorText: String?

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

    private func createPost(body: String, verifiedTradeCandidateId: String?) async -> GrowHousePost? {
        let trimmedBody = body.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBody.isEmpty else { return nil }

        isPosting = true
        defer { isPosting = false }

        do {
            let post = try await SeekAPIClient(settings: SeekAPISettings.shared).createPost(
                body: trimmedBody,
                verifiedTradeCandidateId: verifiedTradeCandidateId
            )
            upsert(post)
            errorText = nil
            return post
        } catch {
            errorText = cleanError(error)
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
}
