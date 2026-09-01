import SwiftUI

/// New Event sheet — the "For" picker chooses between "Local · {city}"
/// (a city-wide `LocalEvent`) or one of the user's private crews (sets
/// that crew's single `CrewEvent`, replacing any existing one).
struct CreateEventView: View {
    let defaultToLocal: Bool
    let city: String
    let myCrews: [Crew]
    let onCreated: () -> Void

    @EnvironmentObject var session: SessionViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CommunitiesViewModel()

    @State private var targetCrew: Crew?
    @State private var title = ""
    @State private var when = ""
    @State private var streakBonus = 3
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section("For") {
                    forPicker
                }
                Section("Event title") {
                    TextField("e.g. Sunday Potluck", text: $title)
                }
                Section("When") {
                    TextField("e.g. Sun · 6:00 PM", text: $when)
                }
                Section("Streak bonus") {
                    Stepper("+\(streakBonus) days", value: $streakBonus, in: 1...10)
                }
            }
            .navigationTitle("New event")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") { Task { await save() } }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty || when.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
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
        guard let uid = session.userId else { return }
        isSaving = true
        defer { isSaving = false }
        let ok = await viewModel.createEvent(targetCrew: targetCrew, title: title, when: when, streakBonus: streakBonus, ownerUid: uid, city: city)
        if ok {
            onCreated()
            dismiss()
        } else {
            session.errorMessage = viewModel.errorMessage
        }
    }
}
