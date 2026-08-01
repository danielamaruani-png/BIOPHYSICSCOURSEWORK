import FirebaseFirestore

/// Denormalized, friend-readable summary at `publicProfiles/{uid}`.
/// Any signed-in user can read this — it's deliberately thin (name,
/// streak, today's ✅/⭕), not a feed. Seeing someone's actual proof
/// photos requires a separate, mutual accountability-partner request
/// (see PartnerRequest) — following alone never unlocks that.
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

extension PublicProfile: Hashable {
    static func == (lhs: PublicProfile, rhs: PublicProfile) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
