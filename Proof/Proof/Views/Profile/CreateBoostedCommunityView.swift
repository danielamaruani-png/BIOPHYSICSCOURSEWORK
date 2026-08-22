import SwiftUI

/// Creator Tools → Create boosted community. Always public and pinned
/// at the top of Local discovery for `city` — see
/// `AdminViewModel.createBoostedCrew` and firestore.rules, which is the
/// thing that actually enforces "only creators can set boosted: true"
/// server-side, not just this screen being hard to reach.
struct CreateBoostedCommunityView: View {
    let city: String
    let onCreated: () -> Void

    @EnvironmentObject var session: SessionViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AdminViewModel()

    @State private var name = ""
    @State private var vibe = ""
    @State private var iconName = CrewIcons.defaultIcon
    @State private var colorHex = CrewSwatches.options[0]
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Proof Official Runners", text: $name)
                }
                Section("Vibe") {
                    TextField("e.g. Official crew, curated events every week", text: $vibe, axis: .vertical)
                }
                Section("Icon") {
                    CrewIconGrid(selectedIcon: $iconName, colorHex: colorHex)
                }
                Section("Colour") {
                    CrewColorSwatchRow(selectedColorHex: $colorHex)
                }
                Text("🚀 Boosted communities are public and pinned at the top of Local discovery.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Boosted community")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") { Task { await save() } }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
        }
    }

    private func save() async {
        guard let uid = session.userId, let profile = session.profile else { return }
        isSaving = true
        defer { isSaving = false }
        let ok = await viewModel.createBoostedCrew(
            name: name, vibe: vibe.isEmpty ? "Official Proof community" : vibe, iconName: iconName, colorHex: colorHex,
            city: city, ownerUid: uid, ownerName: profile.name, ownerColorHex: "#D9713C"
        )
        if ok {
            onCreated()
            dismiss()
        } else {
            session.errorMessage = viewModel.errorMessage
        }
    }
}
