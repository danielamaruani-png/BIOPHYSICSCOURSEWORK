import SwiftUI

struct ProfileSetupView: View {
    @EnvironmentObject var session: SessionViewModel
    let isOnboarding: Bool

    @State private var name: String = ""
    @State private var bio: String = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Your name") {
                    TextField("Name", text: $name)
                }
                Section("Bio (optional)") {
                    TextField("A short line about your goals", text: $bio, axis: .vertical)
                }
            }
            .navigationTitle("Set up profile")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save") {
                        Task { await save() }
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .onAppear {
                name = session.profile?.name ?? ""
                bio = session.profile?.bio ?? ""
            }
        }
    }

    private func save() async {
        guard let uid = session.userId else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            try await FirestoreService.shared.updateProfile(
                uid: uid, name: name, bio: bio.isEmpty ? nil : bio, photoURL: nil
            )
            session.profile = try await FirestoreService.shared.fetchUserProfile(uid: uid)
        } catch {
            session.errorMessage = error.localizedDescription
        }
    }
}
