import SwiftUI

struct FriendsView: View {
    @EnvironmentObject var session: SessionViewModel
    @StateObject private var viewModel = FriendsViewModel()

    private var uid: String { session.userId ?? "" }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    TextField("Search by name", text: $viewModel.searchText)
                        .onChange(of: viewModel.searchText) { _, _ in
                            Task { await viewModel.search() }
                        }
                }

                if !viewModel.incomingRequests.isEmpty {
                    Section("Proof-sharing requests") {
                        ForEach(viewModel.incomingRequests) { profile in
                            HStack(spacing: 12) {
                                AvatarView(photoURL: profile.photoURL, size: 36)
                                Text(profile.name).font(.headline)
                                Spacer()
                                Button("Decline") {
                                    Task { await viewModel.respondToPartnership(uid: uid, target: profile, accept: false) }
                                }
                                .buttonStyle(.bordered)
                                Button("Accept") {
                                    Task { await viewModel.respondToPartnership(uid: uid, target: profile, accept: true) }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .font(.footnote)
                        }
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
            .navigationDestination(for: PublicProfile.self) { profile in
                PartnerProofView(partner: profile)
            }
            .task { await viewModel.loadFriends(uid: uid) }
        }
    }

    private func friendRow(_ profile: PublicProfile) -> some View {
        let state = viewModel.partnerState(for: profile, uid: uid)
        return HStack(spacing: 12) {
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
                Task { await viewModel.toggleFollow(uid: uid, target: profile) }
            }
            .buttonStyle(.bordered)
            .font(.footnote)

            partnerControl(state: state, profile: profile)
        }
    }

    @ViewBuilder
    private func partnerControl(state: PartnerState, profile: PublicProfile) -> some View {
        switch state {
        case .none:
            Button("Share proofs") {
                Task { await viewModel.requestPartnership(uid: uid, target: profile) }
            }
            .buttonStyle(.bordered)
            .font(.footnote)
        case .requestSent:
            Text("Requested").font(.caption).foregroundStyle(.secondary)
        case .requestReceived:
            Text("Check requests above").font(.caption2).foregroundStyle(.secondary)
        case .accepted:
            NavigationLink(value: profile) {
                Label("Partners", systemImage: "checkmark.seal.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
        }
    }
}
