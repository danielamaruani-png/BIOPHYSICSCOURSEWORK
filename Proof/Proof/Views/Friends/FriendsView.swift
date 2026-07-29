import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var session: SessionViewModel
    @StateObject private var viewModel = FriendsViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Search by name", text: $viewModel.searchText)
                        .onChange(of: viewModel.searchText) { _, _ in
                            Task { await viewModel.search() }
                        }
                }

                if !viewModel.searchResults.isEmpty {
                    Section("Results") {
                        ForEach(viewModel.searchResults) { profile in
                            friendRow(profile)
                        }
                    }
                }

                Section("Friends") {
                    if viewModel.friends.isEmpty {
                        Text("Follow people working on similar goals to see their daily status here.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(viewModel.friends) { profile in
                        friendRow(profile)
                    }
                }
            }
            .navigationTitle("Friends")
            .task {
                guard let uid = session.userId else { return }
                await viewModel.loadFriends(uid: uid)
            }
        }
    }

    private func friendRow(_ profile: PublicProfile) -> some View {
        HStack(spacing: 12) {
            AvatarView(photoURL: profile.photoURL, size: 40)
            VStack(alignment: .leading) {
                Text(profile.name).font(.headline)
                Text(profile.todayCompleted ? "Completed today ✅" : "Not completed yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if profile.bestCurrentStreak > 0 {
                StreakBadge(streak: profile.bestCurrentStreak)
            }
            Button(viewModel.isFollowing(profile) ? "Following" : "Follow") {
                Task {
                    guard let uid = session.userId else { return }
                    await viewModel.toggleFollow(uid: uid, target: profile)
                }
            }
            .buttonStyle(.bordered)
            .font(.footnote)
        }
    }
}
