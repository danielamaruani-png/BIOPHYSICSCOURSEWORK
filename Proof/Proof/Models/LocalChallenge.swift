import FirebaseFirestore

/// A community-wide challenge for a city, at `localChallenges/{id}` —
/// the Local counterpart of `CrewChallenge`.
struct LocalChallenge: Codable, Identifiable {
    @DocumentID var id: String?
    var city: String
    var title: String
    var from: String
    var progress: Int
    var total: Int
    var colorHex: String
    var createdAt: Date = Date()
}
