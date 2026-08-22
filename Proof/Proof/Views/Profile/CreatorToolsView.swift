import SwiftUI

/// Only ever reachable from Profile when `UserProfile.isCreator ==
/// true` — see ProfileView. Lets creators edit the global Rewards
/// ladder and stand up boosted public communities.
struct CreatorToolsView: View {
    let city: String

    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AdminViewModel()

    @State private var editingReward: Reward?
    @State private var showNewReward = false
    @State private var showCreateBoosted = false

    var body: some View {
        NavigationStack {
            List {
                Text("Only visible to app creators — manage global rewards and promote official communities.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Section {
                    ForEach(viewModel.rewards) { reward in
                        Button {
                            editingReward = reward
                        } label: {
                            HStack {
                                Text(reward.icon)
                                VStack(alignment: .leading) {
                                    Text(reward.label).font(.subheadline.bold())
                                    Text("🔥 \(reward.days)-day streak").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                            }
                        }
                        .foregroundStyle(.primary)
                    }
                } header: {
                    HStack {
                        Text("Rewards")
                        Spacer()
                        Button("+ Add") { showNewReward = true }
                    }
                }

                Section {
                    if viewModel.boostedCrews.isEmpty {
                        Text("No boosted communities yet.").foregroundStyle(.secondary)
                    }
                    ForEach(viewModel.boostedCrews) { crew in
                        HStack {
                            Image(systemName: crew.iconName).foregroundStyle(Color(hex: crew.colorHex))
                            VStack(alignment: .leading) {
                                Text(crew.name).font(.subheadline.bold())
                                Text("\(crew.memberCount) members").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Remove", role: .destructive) {
                                Task { await viewModel.removeBoostedCrew(crew) }
                            }
                            .font(.caption)
                        }
                    }
                    Button {
                        showCreateBoosted = true
                    } label: {
                        Label("Create boosted community", systemImage: "arrow.up.forward.app.fill")
                    }
                } header: {
                    Text("Boosted communities")
                } footer: {
                    Text("Official public communities, pinned and highlighted in Local discovery.")
                }
            }
            .navigationTitle("Creator Tools")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .task { await viewModel.load(city: city) }
            .sheet(item: $editingReward) { reward in
                EditRewardView(
                    reward: reward,
                    onSave: { updated in Task { await save(updated) } },
                    onDelete: { toDelete in Task { await viewModel.deleteReward(toDelete) } }
                )
            }
            .sheet(isPresented: $showNewReward) {
                EditRewardView(
                    reward: nil,
                    onSave: { new in Task { await save(new) } },
                    onDelete: { _ in }
                )
            }
            .sheet(isPresented: $showCreateBoosted) {
                CreateBoostedCommunityView(city: city) {
                    Task { await viewModel.load(city: city) }
                }
            }
        }
    }

    private func save(_ reward: Reward) async {
        if await viewModel.saveReward(reward) {
            await viewModel.load(city: city)
        }
    }
}
