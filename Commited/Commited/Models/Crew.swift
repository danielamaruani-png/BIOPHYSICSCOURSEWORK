import FirebaseFirestore
import SwiftUI

/// A crew is the app's only "goal" — there's no solo objective anymore,
/// joining or creating a crew *is* the objective. Private crews ("My
/// Crews") are invite-only; public crews are discoverable in Local and
/// joinable by anyone in the same city. `boosted` marks an official,
/// creator-curated public crew pinned at the top of Local discovery.
///
/// `memberUids` is a denormalized array (alongside the `members`
/// subcollection, which holds per-member streak detail) purely so "my
/// crews" can be queried with a single `array-contains` — Firestore
/// can't query "does this subcollection contain doc X" across many
/// parent docs without a collection-group index per field, which would
/// be overkill here.
struct Crew: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var name: String
    var iconName: String // SF Symbol name
    var colorHex: String
    var vibe: String
    var isPrivate: Bool
    var boosted: Bool = false
    var city: String? // set for public/local crews; nil for private crews
    var ownerUid: String
    var memberUids: [String] = []
    var memberCount: Int = 0
    var createdAt: Date = Date()
    var event: CrewEvent?
    var challenge: CrewChallenge?

    var color: Color { Color(hex: colorHex) }

    static func == (lhs: Crew, rhs: Crew) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
