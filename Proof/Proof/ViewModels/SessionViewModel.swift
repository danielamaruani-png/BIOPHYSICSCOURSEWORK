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
            syncWidgetSnapshot()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Recomputes the shared widget snapshot from in-memory state so the
    /// home screen widget stays fresh right after this device changes
    /// something, without waiting on a background refresh.
    func syncWidgetSnapshot() {
        let today = FirestoreService.dayString()
        let completedToday = resolutions.filter { $0.lastProofDate == today }.count
        let bestStreak = resolutions.map(\.currentStreak).max() ?? 0
        WidgetSnapshot(
            bestCurrentStreak: bestStreak,
            totalResolutions: resolutions.count,
            completedToday: completedToday,
            updatedAt: Date()
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
