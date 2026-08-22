import SwiftUI

enum CrewCreationContext {
    case myCrews // → private, invite friends
    case local // → public, discoverable in Local
}

/// New Crew sheet. Visibility is automatic, not a manual toggle:
/// created from My Crews it's private (you add who's in); created from
/// Local it's public (anyone in the same city can find and join) —
/// matching the interactive mockup exactly.
struct CreateCrewView: View {
    let context: CrewCreationContext
    let city: String
    let onCreated: () -> Void

    @EnvironmentObject var session: SessionViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CommunitiesViewModel()

    @State private var name = ""
    @State private var vibe = ""
    @State private var iconName = CrewIcons.defaultIcon
    @State private var colorHex = CrewSwatches.options[0]
    @State private var inviteSearch = ""
    @State private var inviteResults: [PublicProfile] = []
    @State private var selectedInvitees: Set<String> = [] // uid
    @State private var selectedInviteeProfiles: [String: PublicProfile] = [:]
    @State private var isSaving = false

    private var isPrivate: Bool { context == .myCrews }

    var body: some View {
        NavigationStack {
            Form {
                Section("Crew name") {
                    TextField("e.g. Book Club", text: $name)
                }
                Section("Vibe") {
                    TextField("e.g. cozy Sunday dinners, spicy & bold, slow weeknight comfort", text: $vibe, axis: .vertical)
                }
                Section("Icon") {
                    CrewIconGrid(selectedIcon: $iconName, colorHex: colorHex)
                }
                Section("Colour") {
                    CrewColorSwatchRow(selectedColorHex: $colorHex)
                }
                Section("Visibility") {
                    Label(
                        isPrivate ? "Private — only people you add can join." : "Public — a Local community, anyone nearby can find and join.",
                        systemImage: isPrivate ? "lock.fill" : "globe"
                    )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                }
                if isPrivate {
                    Section("Add friends") {
                        TextField("Search friends…", text: $inviteSearch)
                            .onChange(of: inviteSearch) { _ in Task { await searchInvitees() } }
                        ForEach(inviteResults) { profile in
                            Button {
                                toggle(profile)
                            } label: {
                                HStack {
                                    InitialAvatarView(name: profile.name, colorHex: "#D9713C", size: 32)
                                    Text(profile.name)
                                    Spacer()
                                    if selectedInvitees.contains(profile.uid) {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.accentColor)
                                    }
                                }
                            }
                            .foregroundStyle(.primary)
                        }
                    }
                }
            }
            .navigationTitle("New crew")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") { Task { await save() } }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
        }
    }

    private func toggle(_ profile: PublicProfile) {
        if selectedInvitees.contains(profile.uid) {
            selectedInvitees.remove(profile.uid)
            selectedInviteeProfiles[profile.uid] = nil
        } else {
            selectedInvitees.insert(profile.uid)
            selectedInviteeProfiles[profile.uid] = profile
        }
    }

    private func searchInvitees() async {
        guard !inviteSearch.isEmpty else { inviteResults = []; return }
        inviteResults = (try? await FirestoreService.shared.searchPublicProfiles(nameStartingWith: inviteSearch)) ?? []
    }

    private func save() async {
        guard let uid = session.userId, let profile = session.profile else { return }
        isSaving = true
        defer { isSaving = false }

        let invited = selectedInviteeProfiles.values.map { (uid: $0.uid, name: $0.name, colorHex: "#D9713C") }
        let ok = await viewModel.createCrew(
            name: name, vibe: vibe.isEmpty ? "New crew" : vibe, iconName: iconName, colorHex: colorHex,
            isPrivate: isPrivate, city: city,
            ownerUid: uid, ownerName: profile.name, ownerColorHex: "#D9713C",
            invitedMembers: isPrivate ? invited : []
        )
        if ok {
            onCreated()
            dismiss()
        } else {
            session.errorMessage = viewModel.errorMessage
        }
    }
}
