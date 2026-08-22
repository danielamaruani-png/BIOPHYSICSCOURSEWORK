import SwiftUI

/// New Challenge sheet — same "For" picker as Create Event, targeting
/// either "Local · {city}" (`LocalChallenge`) or a private crew's single
/// `CrewChallenge`.
struct CreateChallengeView: View {
    let defaultToLocal: Bool
    let city: String
    let myCrews: [Crew]
    let onCreated: () -> Void

    @EnvironmentObject var session: SessionViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CommunitiesViewModel()

    @State private var targetCrew: Crew?
    @State private var title = ""
    @State private var totalDays = 7
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("For") {
                    forPicker
                }
                Section("Challenge title") {
                    TextField("e.g. 7-day veggie challenge", text: $title)
                }
                Section("Duration") {
                    Stepper("\(totalDays) days", value: $totalDays, in: 1...60)
                }
            }
            .navigationTitle("New challenge")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") { Task { await save() } }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                }
            }
            .onAppear {
                if !defaultToLocal { targetCrew = myCrews.first }
            }
        }
    }

    private var forPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                forChip(label: "Local · \(city)", isSelected: targetCrew == nil) { targetCrew = nil }
                ForEach(myCrews) { crew in
                    forChip(label: crew.name, isSelected: targetCrew?.id == crew.id) { targetCrew = crew }
                }
            }
        }
    }

    private func forChip(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.caption.bold())
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.secondarySystemBackground), in: Capsule())
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }
        let ok = await viewModel.createChallenge(targetCrew: targetCrew, title: title, totalDays: totalDays, city: city)
        if ok {
            onCreated()
            dismiss()
        } else {
            session.errorMessage = viewModel.errorMessage
        }
    }
}
