import FirebaseFirestore

/// Denormalized, friend-readable summary at `publicProfiles/{uid}`.
/// Kept intentionally thin: friends see today's status and streak,
/// never a full feed of someone else's history.
struct PublicProfile: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var photoURL: String?
    var bestCurrentStreak: Int
    var todayCompleted: Bool
    var todayDate: String // yyyy-MM-dd, lets readers detect staleness
    var activeResolutionsCount: Int

    var uid: String { id ?? "" }
}
