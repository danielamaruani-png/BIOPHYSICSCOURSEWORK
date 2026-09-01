import SwiftUI

struct RootView: View {
    @EnvironmentObject var session: SessionViewModel

    var body: some View {
        Group {
            if session.isLoading {
                ProgressIndicatorView()
            } else if session.userId == nil {
                SignInView()
            } else if session.profile?.onboardingCompleted == false {
                // First-ever login: nudge through a one-time profile touch
                // before dropping them into an empty home screen.
                ProfileSetupView(isOnboarding: true)
            } else {
                MainTabView()
            }
        }
    }
}

private struct ProgressIndicatorView: View {
    var body: some View {
        ProgressView()
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            CommunitiesView()
                .tabItem { Label("Communities", systemImage: "person.3.fill") }
            FeedView()
                .tabItem { Label("Feed", systemImage: "bolt.fill") }
            FriendsView()
                .tabItem { Label("Friends", systemImage: "person.2") }
            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.crop.circle") }
        }
    }
}
