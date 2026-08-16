import Foundation

/// A single upcoming event, embedded directly on a `Crew` doc (or, when
/// created "for Local", on a `LocalEvent` doc instead). A crew holds at
/// most one at a time — creating a new one for the same crew replaces
/// it, matching the simple "For: crew or Local" picker in Create Event.
struct CrewEvent: Codable, Hashable {
    var title: String
    var when: String // free-text, e.g. "Sat · 8:00 AM"
    var streakBonus: Int
    var goingUids: [String]
}
