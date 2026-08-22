import FirebaseFirestore

/// A community-wide event for a city, at `localEvents/{id}` — distinct
/// from `CrewEvent`, which belongs to a single crew. Scoped by `city`
/// so `FirestoreService.fetchLocalEvents` can query just the current
/// user's `UserProfile.localCity`.
struct LocalEvent: Codable, Identifiable {
    @DocumentID var id: String?
    var city: String
    var title: String
    var when: String
    var streakBonus: Int
    var goingUids: [String]
    var createdAt: Date = Date()
}
