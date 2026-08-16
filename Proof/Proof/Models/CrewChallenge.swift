import Foundation

/// A single active challenge, embedded on a `Crew` doc (or a
/// `LocalChallenge` doc for community-wide challenges). Same
/// one-at-a-time-per-crew shape as `CrewEvent`.
struct CrewChallenge: Codable, Hashable {
    var title: String
    var from: String // e.g. "Léa challenged you" or "Community challenge · 24 joined"
    var progress: Int
    var total: Int
    var colorHex: String
}
