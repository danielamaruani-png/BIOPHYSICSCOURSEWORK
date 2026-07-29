import Foundation

@MainActor
final class ProgressViewModel: ObservableObject {
    @Published var proofs: [DailyProof] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load(uid: String, resolution: Resolution) async {
        guard let resolutionId = resolution.id else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            proofs = try await FirestoreService.shared.fetchAllProofs(uid: uid, resolutionId: resolutionId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Lifetime completion % relative to how many days have elapsed
    /// since the resolution's start date — a rough but honest measure
    /// for Phase 1 (it doesn't yet account for weekday/timesPerWeek
    /// targets being less demanding than "daily").
    func completionPercentage(resolution: Resolution) -> Double {
        let daysElapsed = max(1, Calendar.current.dateComponents(
            [.day], from: resolution.startDate, to: Date()
        ).day ?? 1)
        return min(1.0, Double(resolution.totalProofs) / Double(daysElapsed))
    }

    var proofDates: Set<DateComponents> {
        let calendar = Calendar.current
        return Set(proofs.compactMap { proof in
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            guard let date = formatter.date(from: proof.dateString) else { return nil }
            return calendar.dateComponents([.year, .month, .day], from: date)
        })
    }
}
