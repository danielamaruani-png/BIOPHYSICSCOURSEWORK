import FirebaseFirestore

/// Denormalized, friend-readable summary at `publicProfiles/{uid}`.
/// Any signed-in user can read this — it's deliberately thin (name,
/// total streak, crew count), not a feed of actual proof photos.
/// Seeing someone's real crew activity requires either sharing a crew
/// with them, or a mutual accountability-partner request (see
/// PartnerRequest) — following alone never unlocks either.
struct PublicProfile: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var photoURL: String?
    var totalStreak: Int
    var crewCount: Int

    var uid: String { id ?? "" }
}

extension PublicProfile: Hashable {
    static func == (lhs: PublicProfile, rhs: PublicProfile) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
