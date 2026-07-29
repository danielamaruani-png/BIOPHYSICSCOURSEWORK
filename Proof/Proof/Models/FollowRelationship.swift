import FirebaseFirestore

/// Join record at `follows/{followerUid}_{followingUid}`.
/// One-directional: following someone doesn't require them to follow back.
struct FollowRelationship: Codable, Identifiable {
    @DocumentID var id: String?
    var followerId: String
    var followingId: String
    var createdAt: Date

    static func documentId(follower: String, following: String) -> String {
        "\(follower)_\(following)"
    }
}
