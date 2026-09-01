import FirebaseFirestore

/// Global milestone reward (e.g. "🍳 New non-stick pan" at a 30-day
/// streak), at `rewards/{id}`. Readable by any signed-in user; only
/// writable by creators (`UserProfile.isCreator`) via Creator Tools —
/// see firestore.rules.
struct Reward: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var days: Int
    var icon: String // emoji
    var label: String
}
