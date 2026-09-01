import Foundation

/// Backs the BeReal-style public Feed tab: random posts from anyone
/// with `UserProfile.publicFeedOptIn == true` (not just friends or
/// crew-mates), reactions, and comments.
@MainActor
final class FeedViewModel: ObservableObject {
    @Published var posts: [PublicFeedPost] = []
    @Published var comments: [FeedComment] = []
    /// "{postId}:{emoji}" pairs this device has reacted with this
    /// session — the view checks this to highlight a reaction pill as
    /// "mine", same as the mockup's `post.myReactions`.
    @Published var myReactions: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            posts = try await FirestoreService.shared.fetchPublicFeed()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func hasReacted(postId: String, emoji: String) -> Bool {
        myReactions.contains("\(postId):\(emoji)")
    }

    /// Tapping an emoji already reacted with removes just that one;
    /// tapping a different emoji adds it alongside any others — see
    /// `FeedReaction`'s doc-comment. The ViewModel is the one flipping
    /// the toggle, so it already knows which direction the change went
    /// and updates the local count instantly instead of re-fetching.
    func react(postId: String, uid: String, emoji: String) async {
        let key = "\(postId):\(emoji)"
        do {
            try await FirestoreService.shared.toggleReaction(postId: postId, uid: uid, emoji: emoji)
            guard let idx = posts.firstIndex(where: { $0.id == postId }) else { return }
            let current = posts[idx].reactionCounts[emoji] ?? 0
            if myReactions.contains(key) {
                myReactions.remove(key)
                posts[idx].reactionCounts[emoji] = max(0, current - 1)
            } else {
                myReactions.insert(key)
                posts[idx].reactionCounts[emoji] = current + 1
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadComments(postId: String) async {
        do {
            comments = try await FirestoreService.shared.fetchComments(postId: postId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addComment(postId: String, authorUid: String, authorName: String, text: String) async {
        do {
            try await FirestoreService.shared.addComment(postId: postId, authorUid: authorUid, authorName: authorName, text: text)
            await loadComments(postId: postId)
            if let idx = posts.firstIndex(where: { $0.id == postId }) {
                posts[idx].commentCount += 1
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
