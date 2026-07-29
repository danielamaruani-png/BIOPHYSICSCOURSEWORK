import Foundation
import WidgetKit

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
