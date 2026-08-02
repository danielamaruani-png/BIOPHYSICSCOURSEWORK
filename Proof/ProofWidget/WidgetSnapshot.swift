import Foundation

/// Mirrors Proof/Services/WidgetDataBridge.swift's `WidgetSnapshot`.
/// Duplicated rather than shared across targets to keep the widget
/// extension a single-file-group drop-in for Phase 1; if this grows,
/// promote both copies to a shared local Swift package instead.
struct PartnerStreakSummary: Codable, Identifiable {
    var id: String
    var name: String
    var streak: Int
    var completedToday: Bool
}

struct WidgetSnapshot: Codable {
    var myUid: String
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
}
