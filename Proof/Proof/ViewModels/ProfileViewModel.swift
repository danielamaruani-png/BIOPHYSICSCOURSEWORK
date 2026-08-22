import Foundation

/// Backs the Profile tab: the global Rewards ladder, and the two
/// settings rows (Local city, Public feed toggle) that write straight
/// through to `UserProfile` via FirestoreService.
@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var rewards: [Reward] = []
    @Published var localEvents: [LocalEvent] = []
    @Published var localChallenges: [LocalChallenge] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadRewards() async {
        isLoading = true
        defer { isLoading = false }
        do {
            rewards = try await FirestoreService.shared.fetchRewards()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Feeds Profile's "My next events" and "Challenges" sections, which
    /// combine each crew's own event/challenge with the city-wide Local
    /// ones — same aggregation the mockup's `renderProfile` does.
    func loadLocalContext(city: String) async {
        do {
            async let eventsTask = FirestoreService.shared.fetchLocalEvents(city: city)
            async let challengesTask = FirestoreService.shared.fetchLocalChallenges(city: city)
            (localEvents, localChallenges) = try await (eventsTask, challengesTask)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// The next reward the user hasn't unlocked yet, given their
    /// current total streak — used for the "N days to go" subtitle.
    func nextReward(totalStreak: Int) -> Reward? {
        rewards.first { $0.days > totalStreak }
    }

    func updateLocalCity(uid: String, city: String) async -> Bool {
        do {
            try await FirestoreService.shared.updateLocalCity(uid: uid, city: city)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func updatePublicFeedOptIn(uid: String, optedIn: Bool) async {
        do {
            try await FirestoreService.shared.updatePublicFeedOptIn(uid: uid, optedIn: optedIn)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
