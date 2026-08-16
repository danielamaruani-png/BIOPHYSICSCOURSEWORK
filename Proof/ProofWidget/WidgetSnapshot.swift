import Foundation

/// Mirrors Proof/Services/WidgetDataBridge.swift's `WidgetSnapshot`.
/// Duplicated rather than shared across targets to keep the widget
/// extension a single-file-group drop-in; if this grows, promote both
/// copies to a shared local Swift package instead.
struct WidgetSnapshot: Codable {
    var myUid: String
    var totalStreak: Int
    var selectedCrewId: String
    var selectedCrewName: String
    var selectedCrewColorHex: String
    var myStreakInSelectedCrew: Int
    var crewCheckedInToday: Int
    var crewSize: Int
    var spotlightMemberUid: String?
    var spotlightMemberName: String?
    var spotlightDoneToday: Bool
    var updatedAt: Date

    static let appGroupId = "group.com.proofapp.shared"
    private static let key = "widgetSnapshot"

    static func load() -> WidgetSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let data = defaults.data(forKey: key)
        else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }
}
