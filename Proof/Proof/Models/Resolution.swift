import FirebaseFirestore
import SwiftUI

enum TargetFrequency: Codable, Equatable {
    case daily
    case weekdays
    case timesPerWeek(Int)

    var label: String {
        switch self {
        case .daily: return "Every day"
        case .weekdays: return "Weekdays"
        case .timesPerWeek(let n): return "\(n)x / week"
        }
    }

    // Manual Codable so we can store as a simple string in Firestore
    // (e.g. "daily", "weekdays", "times:3") instead of a nested object.
    private enum CodingKeys: String, CodingKey { case raw }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        if raw == "daily" {
            self = .daily
        } else if raw == "weekdays" {
            self = .weekdays
        } else if raw.hasPrefix("times:"), let n = Int(raw.dropFirst(6)) {
            self = .timesPerWeek(n)
        } else {
            self = .daily
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .daily: try container.encode("daily")
        case .weekdays: try container.encode("weekdays")
        case .timesPerWeek(let n): try container.encode("times:\(n)")
        }
    }
}

enum ResolutionCategory: String, Codable, CaseIterable, Hashable {
    case fitness, reading, learning, coding, mindfulness, other

    var defaultIcon: String {
        switch self {
        case .fitness: return "figure.run"
        case .reading: return "book.fill"
        case .learning: return "graduationcap.fill"
        case .coding: return "chevron.left.forwardslash.chevron.right"
        case .mindfulness: return "leaf.fill"
        case .other: return "star.fill"
        }
    }
}

/// A goal the user commits to, stored at `users/{uid}/resolutions/{id}`.
struct Resolution: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var category: ResolutionCategory
    var startDate: Date
    var targetFrequency: TargetFrequency
    var colorHex: String
    var icon: String
    var createdAt: Date

    // Denormalized counters, updated transactionally by StreakEngine
    // whenever a proof is recorded, so the UI never needs to recompute
    // them from the full proof history.
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    var totalProofs: Int = 0
    var lastProofDate: String? // yyyy-MM-dd

    var color: Color { Color(hex: colorHex) }
}

extension Resolution: Hashable {
    // Identity is the Firestore document ID — two Resolution values
    // representing the same document should be equal even if one is a
    // slightly staler snapshot than the other.
    static func == (lhs: Resolution, rhs: Resolution) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
