import FirebaseFirestore

/// Per-crew membership + streak, at `crews/{crewId}/members/{uid}`.
/// Streaks are scoped to the crew — the same person can have a 12-day
/// streak in one crew and a 0-day streak in another.
struct CrewMember: Codable, Identifiable {
    @DocumentID var id: String? // uid
    var name: String
    var colorHex: String
    var streak: Int = 0
    var longestStreak: Int = 0
    var doneToday: Bool = false
    var lastProofDate: String? // yyyy-MM-dd
    var joinedAt: Date = Date()

    var uid: String { id ?? "" }
}
