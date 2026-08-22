import Foundation

/// Backs the Communities tab's Local half: every public crew in the
/// user's `UserProfile.localCity`, split client-side into "already
/// joined" (Local → Chats) vs. "not yet joined" (→ Discover more
/// nearby) — same partition the interactive mockup does between
/// `local.chats` and `local.discover`. My Crews (private) live on
/// `SessionViewModel.myCrews` instead, since that list also feeds the
/// total-streak/widget calculations.
@MainActor
final class CommunitiesViewModel: ObservableObject {
    @Published var localCrews: [Crew] = []
    @Published var localEvents: [LocalEvent] = []
    @Published var localChallenges: [LocalChallenge] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadLocal(city: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let crewsTask = FirestoreService.shared.fetchLocalCrews(city: city)
            async let eventsTask = FirestoreService.shared.fetchLocalEvents(city: city)
            async let challengesTask = FirestoreService.shared.fetchLocalChallenges(city: city)
            (localCrews, localEvents, localChallenges) = try await (crewsTask, eventsTask, challengesTask)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func joinedCrews(uid: String) -> [Crew] { localCrews.filter { $0.memberUids.contains(uid) } }
    func discoverableCrews(uid: String) -> [Crew] { localCrews.filter { !$0.memberUids.contains(uid) } }

    /// Creates a crew. Visibility is automatic, not a manual toggle:
    /// crews created from My Crews are private (`city == nil`, invite
    /// who's in); crews created from Local are public so anyone nearby
    /// can find and join them. `boosted` should only ever be true when
    /// called from Creator Tools — firestore.rules enforces that
    /// server-side regardless of what the client sends.
    @discardableResult
    func createCrew(
        name: String, vibe: String, iconName: String, colorHex: String,
        isPrivate: Bool, boosted: Bool = false, city: String?,
        ownerUid: String, ownerName: String, ownerColorHex: String,
        invitedMembers: [(uid: String, name: String, colorHex: String)] = []
    ) async -> Bool {
        let crew = Crew(
            name: name, iconName: iconName, colorHex: colorHex, vibe: vibe,
            isPrivate: isPrivate, boosted: boosted, city: isPrivate ? nil : city, ownerUid: ownerUid
        )
        do {
            try await FirestoreService.shared.createCrew(
                crew, ownerName: ownerName, ownerColorHex: ownerColorHex, invitedMembers: invitedMembers
            )
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func joinCrew(_ crew: Crew, uid: String, name: String, colorHex: String) async -> Bool {
        guard let crewId = crew.id else { return false }
        do {
            try await FirestoreService.shared.joinCrew(crewId: crewId, uid: uid, name: name, colorHex: colorHex)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    /// `targetCrew == nil` means "For: Local" — same "For" picker the
    /// mockup's New Event/New Challenge sheets use (a chip row of "Local
    /// · {city}" plus each of the user's private crews).
    @discardableResult
    func createEvent(targetCrew: Crew?, title: String, when: String, streakBonus: Int, ownerUid: String, city: String) async -> Bool {
        do {
            if let crew = targetCrew, let crewId = crew.id {
                try await FirestoreService.shared.setCrewEvent(
                    crewId: crewId,
                    event: CrewEvent(title: title, when: when, streakBonus: streakBonus, goingUids: [ownerUid])
                )
            } else {
                try await FirestoreService.shared.createLocalEvent(
                    LocalEvent(city: city, title: title, when: when, streakBonus: streakBonus, goingUids: [ownerUid])
                )
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    @discardableResult
    func createChallenge(targetCrew: Crew?, title: String, totalDays: Int, city: String) async -> Bool {
        do {
            if let crew = targetCrew, let crewId = crew.id {
                try await FirestoreService.shared.setCrewChallenge(
                    crewId: crewId,
                    challenge: CrewChallenge(title: title, from: "You started this challenge", progress: 0, total: totalDays, colorHex: crew.colorHex)
                )
            } else {
                try await FirestoreService.shared.createLocalChallenge(
                    LocalChallenge(city: city, title: title, from: "Community challenge · 1 joined", progress: 0, total: totalDays, colorHex: "#D9713C")
                )
            }
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
