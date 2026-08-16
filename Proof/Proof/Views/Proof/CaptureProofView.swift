import SwiftUI

/// Post today's proof to a specific crew. Camera-only — there is no
/// "choose from library" option anywhere in this screen, matching the
/// live-camera-only anti-cheat rule (see ImagePicker.swift).
struct CaptureProofView: View {
    let crew: Crew

    @EnvironmentObject var session: SessionViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CaptureProofViewModel()

    @State private var image: UIImage?
    @State private var showCamera = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.secondarySystemBackground))
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "camera.fill").font(.system(size: 36))
                            Text("Take today's photo").foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(height: 320)
                .clipped()
                .onTapGesture { showCamera = true }

                Text("📸 Live camera only — proof can't be imported from your gallery.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Take photo") { showCamera = true }
                    .buttonStyle(.bordered)

                TextField("Caption (optional)", text: $viewModel.caption, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                Text("\(viewModel.caption.count)/\(CaptureProofViewModel.captionLimit)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage).foregroundStyle(.red).font(.footnote)
                }

                Spacer()

                PrimaryButton(
                    title: "Post proof",
                    systemImage: "checkmark",
                    isLoading: viewModel.isSubmitting
                ) {
                    Task { await submit() }
                }
                .disabled(image == nil)
            }
            .padding()
            .navigationTitle("Post to \(crew.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                ImagePicker(image: $image)
                    .ignoresSafeArea()
            }
        }
    }

    private func submit() async {
        guard let uid = session.userId, let crewId = crew.id, let image, let profile = session.profile else { return }
        let ok = await viewModel.submit(
            uid: uid, crewId: crewId, authorName: profile.name, colorHex: "#D9713C", image: image
        )
        if ok {
            await session.refreshCrews()
            dismiss()
        }
    }
}
