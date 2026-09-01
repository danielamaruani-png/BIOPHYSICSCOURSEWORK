import FirebaseAuth
import Foundation

/// Root source of truth for "who's signed in and what do they have."
/// RootView switches between auth / onboarding / main app based on
/// this object's published state.
@MainActor
final class SessionViewModel: ObservableObject {
    @Published var userId: String?
    @Published var profile: UserProfile?
    @Published var myCrews: [Crew] = []
    /// This user's own membership doc (streak, doneToday, …) in each of
    /// `myCrews`, keyed by crew id — fetched alongside `myCrews` since a
    /// crew doc itself doesn't carry a per-member streak.
    @Published var myMemberships: [String: CrewMember] = [:]
    @Published var partnerProfiles: [PublicProfile] = []
    @Published var isLoading = true
    @Published var errorMessage: String?

    /// Set by CommitedApp's `onOpenURL` handler when the widget's "post
    /// proof" button deep-links in (`commited://capture?crewId=...`).
    /// RootView/CommunitiesView observes this to auto-present Capture
    /// for that crew, then clears it back to nil once handled.
    @Published var pendingCaptureCrewId: String?

    var totalStreak: Int { myMemberships.values.map(\.streak).reduce(0, +) }

    private var authHandle: AuthStateDidChangeListenerHandle?

    init() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.userId = user?.uid
                if let user {
                    await self?.loadUserData(uid: user.uid, displayName: user.displayName)
                } else {
                    self?.profile = nil
                    self?.myCrews = []
                    self?.myMemberships = [:]
                }
                self?.isLoading = false
            }
        }
    }

    deinit {
        if let authHandle {
            Auth.auth().removeStateDidChangeListener(authHandle)
        }
    }

    func signInWithApple() async {
        await run { try await AuthService.shared.signInWithApple() }
    }

    func signInWithGoogle() async {
        await run { try await AuthService.shared.signInWithGoogle() }
    }

    func signOut() {
        do {
            try AuthService.shared.signOut()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshCrews() async {
        guard let userId else { return }
        do {
            myCrews = try await FirestoreService.shared.fetchMyCrews(uid: userId)
            myMemberships = await fetchMemberships(userId: userId)
            await refreshPartners()
            await updatePublicProfileStats(userId: userId)
            syncWidgetSnapshot()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Fetches this user's membership doc from every crew in
    /// `myCrews` in parallel, rather than one crew at a time.
    private func fetchMemberships(userId: String) async -> [String: CrewMember] {
        await withTaskGroup(of: (String, CrewMember?).self) { group in
            for crew in myCrews {
                guard let crewId = crew.id else { continue }
                group.addTask {
                    let member = try? await FirestoreService.shared.fetchMyCrewMembership(crewId: crewId, uid: userId)
                    return (crewId, member)
                }
            }
            var result: [String: CrewMember] = [:]
            for await (crewId, member) in group {
                if let member { result[crewId] = member }
            }
            return result
        }
    }

    /// Accepted accountability partners only — never plain followers.
    func refreshPartners() async {
        guard let userId else { return }
        do {
            let partnerIds = try await FirestoreService.shared.fetchAcceptedPartnerIds(uid: userId)
            partnerProfiles = try await FirestoreService.shared.fetchPublicProfiles(uids: partnerIds)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Keeps `publicProfiles/{uid}` in sync so Friends search and
    /// results show current totals.
    private func updatePublicProfileStats(userId: String) async {
        try? await FirestoreService.shared.refreshPublicProfileStats(
            uid: userId, totalStreak: totalStreak, crewCount: myCrews.count
        )
    }

    /// Recomputes the shared widget snapshot from in-memory state so
    /// the home screen widget stays fresh right after this device
    /// changes something, without waiting on a background refresh.
    /// Picks whichever crew has the highest streak as the widget's
    /// featured crew — see WidgetDataBridge.swift for why that's
    /// automatic rather than user-choosable for now.
    func syncWidgetSnapshot() {
        guard let userId else { return }
        guard let featured = myCrews.max(by: { (myMemberships[$0.id ?? ""]?.streak ?? 0) < (myMemberships[$1.id ?? ""]?.streak ?? 0) }),
              let crewId = featured.id
        else { return }

        Task {
            let members = (try? await FirestoreService.shared.fetchCrewMembers(crewId: crewId)) ?? []
            let checkedInToday = members.filter(\.doneToday).count
            let spotlight = members.first { $0.doneToday && $0.uid != userId } ?? members.first { $0.doneToday }

            WidgetSnapshot(
                myUid: userId,
                totalStreak: totalStreak,
                selectedCrewId: crewId,
                selectedCrewName: featured.name,
                selectedCrewColorHex: featured.colorHex,
                myStreakInSelectedCrew: myMemberships[crewId]?.streak ?? 0,
                crewCheckedInToday: checkedInToday,
                crewSize: featured.memberCount,
                spotlightMemberUid: spotlight?.uid,
                spotlightMemberName: spotlight?.name,
                spotlightDoneToday: spotlight?.doneToday ?? false,
                updatedAt: Date()
            ).save()
        }
    }

    private func run(_ action: @escaping () async throws -> Void) async {
        do {
            try await action()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func run(_ action: @escaping () async throws -> AuthDataResult) async {
        do {
            _ = try await action()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadUserData(uid: String, displayName: String?) async {
        do {
            try await FirestoreService.shared.createUserProfileIfNeeded(
                uid: uid,
                name: displayName ?? "New user",
                photoURL: nil
            )
            profile = try await FirestoreService.shared.fetchUserProfile(uid: uid)
            await refreshCrews()
            // Best-effort: a declined permission prompt just means this
            // device never gets the "partner completed today" nudge.
            PushNotificationService.shared.requestAuthorizationAndRegister()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
