import Foundation

/// Backs Creator Tools — only ever shown to a user whose
/// `UserProfile.isCreator == true` (gated in ProfileView, and again
/// server-side by firestore.rules for every write this triggers).
/// Lets creators edit the global Rewards ladder and stand up "boosted"
/// public crews that get pinned at the top of Local discovery.
@MainActor
final class AdminViewModel: ObservableObject {
    @Published var rewards: [Reward] = []
    @Published var boostedCrews: [Crew] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func load(city: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let rewardsTask = FirestoreService.shared.fetchRewards()
            async let crewsTask = FirestoreService.shared.fetchLocalCrews(city: city)
            let (fetchedRewards, crews) = try await (rewardsTask, crewsTask)
            rewards = fetchedRewards
            boostedCrews = crews.filter(\.boosted)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func saveReward(_ reward: Reward) async -> Bool {
        do {
            try await FirestoreService.shared.saveReward(reward)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func deleteReward(_ reward: Reward) async {
        guard let id = reward.id else { return }
        do {
            try await FirestoreService.shared.deleteReward(id: id)
            rewards.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @discardableResult
    func createBoostedCrew(
        name: String, vibe: String, iconName: String, colorHex: String,
        city: String, ownerUid: String, ownerName: String, ownerColorHex: String
    ) async -> Bool {
        let crew = Crew(
            name: name, iconName: iconName, colorHex: colorHex, vibe: vibe,
            isPrivate: false, boosted: true, city: city, ownerUid: ownerUid
        )
        do {
            try await FirestoreService.shared.createCrew(crew, ownerName: ownerName, ownerColorHex: ownerColorHex)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func removeBoostedCrew(_ crew: Crew) async {
        guard let id = crew.id else { return }
        do {
            try await FirestoreService.shared.deleteCrew(crewId: id)
            boostedCrews.removeAll { $0.id == id }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
