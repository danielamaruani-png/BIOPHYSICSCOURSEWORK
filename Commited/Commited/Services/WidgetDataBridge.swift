import Foundation
import WidgetKit

/// Snapshot of just enough state for the home-screen widget, written by
/// the main app into the shared App Group container after every crew
/// refresh or proof post. The widget itself never talks to Firestore
/// directly — it just reads this file, which keeps the extension
/// simple and avoids giving it its own auth session.
///
/// `spotlightMemberUid`/`spotlightMemberName` describe whichever crew
/// member the small "spotlight" photo tile shows — a random member who
/// already checked in today, same as the interactive mockup's
/// `widgetSpotlight`. There's currently no way to manually pick which
/// crew the widget features (it auto-picks the one with the highest
/// `myStreakInSelectedCrew`); making that user-choosable would need an
/// `AppIntent`-backed interactive widget control (iOS 17+) — worth
/// adding as a follow-up, called out here rather than half-built.
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

    static let appGroupId = "group.com.commitedapp.shared"
    private static let key = "widgetSnapshot"

    static func load() -> WidgetSnapshot? {
        guard let defaults = UserDefaults(suiteName: appGroupId),
              let data = defaults.data(forKey: key)
        else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    func save() {
        guard let defaults = UserDefaults(suiteName: Self.appGroupId),
              let data = try? JSONEncoder().encode(self)
        else { return }
        defaults.set(data, forKey: Self.key)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
