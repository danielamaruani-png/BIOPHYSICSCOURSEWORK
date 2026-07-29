import Foundation
import SwiftUI

@MainActor
final class ResolutionFormViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var category: ResolutionCategory = .other
    @Published var startDate: Date = Date()
    @Published var frequencyKind: FrequencyKind = .daily
    @Published var timesPerWeek: Int = 3
    @Published var colorHex: String = "FF6B35"
    @Published var isSaving = false
    @Published var errorMessage: String?

    enum FrequencyKind: String, CaseIterable, Hashable { case daily, weekdays, timesPerWeek }

    var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    private var targetFrequency: TargetFrequency {
        switch frequencyKind {
        case .daily: return .daily
        case .weekdays: return .weekdays
        case .timesPerWeek: return .timesPerWeek(timesPerWeek)
        }
    }

    func save(uid: String) async -> Bool {
        guard isValid else { return false }
        isSaving = true
        defer { isSaving = false }
        let resolution = Resolution(
            name: name.trimmingCharacters(in: .whitespaces),
            category: category,
            startDate: startDate,
            targetFrequency: targetFrequency,
            colorHex: colorHex,
            icon: category.defaultIcon,
            createdAt: Date()
        )
        do {
            try await FirestoreService.shared.createResolution(uid: uid, resolution)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
