import SwiftUI

private let swatches = ["FF6B35", "2EC4B6", "6A4C93", "1982C4", "E71D36", "FFB703"]

struct CreateResolutionView: View {
    @EnvironmentObject var session: SessionViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var form = ResolutionFormViewModel()

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    TextField("e.g. Run 5km", text: $form.name)
                    Picker("Category", selection: $form.category) {
                        ForEach(ResolutionCategory.allCases, id: \.self) { category in
                            Text(category.rawValue.capitalized).tag(category)
                        }
                    }
                }

                Section("Schedule") {
                    DatePicker("Start date", selection: $form.startDate, displayedComponents: .date)
                    Picker("Frequency", selection: $form.frequencyKind) {
                        Text("Every day").tag(ResolutionFormViewModel.FrequencyKind.daily)
                        Text("Weekdays").tag(ResolutionFormViewModel.FrequencyKind.weekdays)
                        Text("X times / week").tag(ResolutionFormViewModel.FrequencyKind.timesPerWeek)
                    }
                    if form.frequencyKind == .timesPerWeek {
                        Stepper("\(form.timesPerWeek)x per week", value: $form.timesPerWeek, in: 1...7)
                    }
                }

                Section("Color") {
                    HStack {
                        ForEach(swatches, id: \.self) { hex in
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle().stroke(Color.primary, lineWidth: form.colorHex == hex ? 2 : 0)
                                )
                                .onTapGesture { form.colorHex = hex }
                        }
                    }
                }

                if let errorMessage = form.errorMessage {
                    Text(errorMessage).foregroundStyle(.red)
                }
            }
            .navigationTitle("New resolution")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(form.isSaving ? "Saving..." : "Save") {
                        Task {
                            guard let uid = session.userId else { return }
                            if await form.save(uid: uid) {
                                await session.refreshResolutions()
                                dismiss()
                            }
                        }
                    }
                    .disabled(!form.isValid || form.isSaving)
                }
            }
        }
    }
}
