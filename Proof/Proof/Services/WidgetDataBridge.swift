import Foundation
import WidgetKit

/// A friend's streak, only ever included here if they're an *accepted*
/// accountability partner — following alone doesn't surface anyone in
/// the widget, since the whole point of the widget is a quick glance
/// at proof, and unconsented proof-adjacent data has no place in it.
struct PartnerStreakSummary: Codable, Identifiable {
    var id: String // partner's uid
    var name: String
    var streak: Int
    var completedToday: Bool
}

/// Snapshot of just enough state for the home-screen widget, written
/// by the main app into the shared App Group container. The widget
/// itself never talks to Firestore directly — it just reads this file,
/// which keeps the extension simple and avoids giving it its own auth
/// session.
struct WidgetSnapshot: Codable {
    var bestCurrentStreak: Int
    var totalResolutions: Int
    var completedToday: Int
    var updatedAt: Date
    var partnerStreaks: [PartnerStreakSummary] = []

    static let appGroupId = "group.com.proofapp.shared"
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
