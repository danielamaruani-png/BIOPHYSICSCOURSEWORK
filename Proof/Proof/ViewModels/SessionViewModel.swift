import FirebaseAuth
import Foundation

/// Root source of truth for "who's signed in and what do they have."
/// RootView switches between auth / onboarding / main app based on
/// this object's published state.
@MainActor
final class SessionViewModel: ObservableObject {
    @Published var userId: String?
    @Published var profile: UserProfile?
    @Published var resolutions: [Resolution] = []
    @Published var partnerProfiles: [PublicProfile] = []
    @Published var isLoading = true
    @Published var errorMessage: String?

    private var authHandle: AuthStateDidChangeListenerHandle?

    init() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.userId = user?.uid
                if let user {
                    await self?.loadUserData(uid: user.uid, displayName: user.displayName)
                } else {
                    self?.profile = nil
                    self?.resolutions = []
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

    func refreshResolutions() async {
        guard let userId else { return }
        do {
            resolutions = try await FirestoreService.shared.fetchResolutions(uid: userId)
            await refreshPartners()
            syncWidgetSnapshot()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Accepted accountability partners only — never plain followers.
    /// Called after resolutions so the widget snapshot below always has
    /// both halves of its data ready at once.
    func refreshPartners() async {
        guard let userId else { return }
        do {
            let partnerIds = try await FirestoreService.shared.fetchAcceptedPartnerIds(uid: userId)
            partnerProfiles = try await FirestoreService.shared.fetchPublicProfiles(uids: partnerIds)
            await cachePartnerPhotosForWidget()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Pulls down today's proof photo for each accepted partner who has
    /// one, so the widget can show it without ever talking to Storage
    /// itself. Skipped entirely for anyone who hasn't posted today —
    /// that's also what keeps a stale, previously-cached photo from
    /// ever being mistaken for today's: the widget only renders a
    /// partner's cached photo when `completedToday` says it's fresh.
    private func cachePartnerPhotosForWidget() async {
        let today = FirestoreService.dayString()
        for partner in partnerProfiles where partner.todayCompleted {
            guard let partnerResolutions = try? await FirestoreService.shared.fetchResolutions(uid: partner.uid),
                  let completed = partnerResolutions.first(where: { $0.lastProofDate == today }),
                  let resolutionId = completed.id,
                  let proof = try? await FirestoreService.shared.fetchProof(
                      uid: partner.uid, resolutionId: resolutionId, day: today
                  ),
                  let url = URL(string: proof.photoURL)
            else { continue }
            await WidgetPhotoCache.downloadAndSave(from: url, forUid: partner.uid)
        }
    }

    /// Recomputes the shared widget snapshot from in-memory state so the
    /// home screen widget stays fresh right after this device changes
    /// something, without waiting on a background refresh.
    func syncWidgetSnapshot() {
        let today = FirestoreService.dayString()
        let completedToday = resolutions.filter { $0.lastProofDate == today }.count
        let bestStreak = resolutions.map(\.currentStreak).max() ?? 0
        let partnerStreaks = partnerProfiles.map {
            PartnerStreakSummary(id: $0.uid, name: $0.name, streak: $0.bestCurrentStreak, completedToday: $0.todayCompleted)
        }
        WidgetSnapshot(
            myUid: userId ?? "",
            bestCurrentStreak: bestStreak,
            totalResolutions: resolutions.count,
            completedToday: completedToday,
            updatedAt: Date(),
            partnerStreaks: partnerStreaks
        ).save()
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
            await refreshResolutions()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
