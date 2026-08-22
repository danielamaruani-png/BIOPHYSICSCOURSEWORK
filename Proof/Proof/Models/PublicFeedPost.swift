import FirebaseFirestore

/// A BeReal-style public post at `publicFeed/{postId}` — visible to
/// every signed-in user, not just friends or crew-mates. Only ever
/// created for an author whose `UserProfile.publicFeedOptIn == true`;
/// see `FirestoreService.postToPublicFeedIfOptedIn`.
///
/// `reactionCounts` and `commentCount` are denormalized for cheap list
/// rendering; the source of truth for *who* reacted with *what* lives
/// in the `reactions` subcollection (one doc per uid, so toggling a
/// reaction is just an upsert/delete), and comments live in their own
/// subcollection.
struct PublicFeedPost: Codable, Identifiable {
    @DocumentID var id: String?
    var authorUid: String
    var authorName: String
    var colorHex: String
    var photoURL: String
    var caption: String
    var createdAt: Date = Date()
    var reactionCounts: [String: Int] = [:]
    var commentCount: Int = 0
}

/// `publicFeed/{postId}/reactions/{uid}_{emoji}` — a reactor can pick
/// several different emoji on the same post at once (matching the
/// interactive mockup's RealMoji-style row), so the doc ID is the pair
/// rather than just the uid: tapping the same emoji twice removes it,
/// tapping a different one adds another reaction alongside it.
struct FeedReaction: Codable, Identifiable {
    @DocumentID var id: String? // "{uid}_{emoji}"
    var uid: String
    var emoji: String

    static func docId(uid: String, emoji: String) -> String { "\(uid)_\(emoji)" }
}

/// `publicFeed/{postId}/comments/{commentId}`.
struct FeedComment: Codable, Identifiable {
    @DocumentID var id: String?
    var authorUid: String
    var authorName: String
    var text: String
    var createdAt: Date = Date()
}
