import SwiftUI

/// Add or edit one milestone reward. `reward == nil` means "new" (no
/// delete button); otherwise pre-fills the form and offers Delete.
struct EditRewardView: View {
    var reward: Reward?
    let onSave: (Reward) -> Void
    let onDelete: (Reward) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var days = 7
    @State private var icon = "🎁"
    @State private var label = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Streak needed (days)") {
                    Stepper("\(days) days", value: $days, in: 1...365)
                }
                Section("Icon (emoji)") {
                    TextField("🎁", text: $icon)
                }
                Section("Reward") {
                    TextField("e.g. 1 month HelloFresh at -10%", text: $label)
                }
                if let reward {
                    Section {
                        Button("Delete reward", role: .destructive) {
                            onDelete(reward)
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle(reward == nil ? "New reward" : "Edit reward")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        var saved = reward ?? Reward(days: days, icon: icon, label: label)
                        saved.days = days
                        saved.icon = icon.isEmpty ? "🎁" : icon
                        saved.label = label
                        onSave(saved)
                        dismiss()
                    }
                    .disabled(label.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                if let reward {
                    days = reward.days
                    icon = reward.icon
                    label = reward.label
                }
            }
        }
    }
}
