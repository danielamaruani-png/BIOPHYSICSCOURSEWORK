import SwiftUI

/// Profile → Local. Free-text city/region — not a preset list — since
/// this is the same "let people type their own thing" preference
/// applied to crew "vibe".
struct ChangeLocalView: View {
    let currentCity: String
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var city = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("City or region") {
                    TextField("e.g. Paris, Brooklyn, Lisbon", text: $city)
                }
                Text("This is the local community you discover, search, and join people in.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Local")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = city.trimmingCharacters(in: .whitespaces)
                        guard !trimmed.isEmpty else { return }
                        onSave(trimmed)
                        dismiss()
                    }
                    .disabled(city.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { city = currentCity }
        }
    }
}
