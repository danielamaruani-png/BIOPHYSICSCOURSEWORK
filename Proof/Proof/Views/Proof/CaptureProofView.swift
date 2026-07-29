import SwiftUI

struct CaptureProofView: View {
    let resolution: Resolution

    @EnvironmentObject var session: SessionViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CaptureProofViewModel()

    @State private var image: UIImage?
    @State private var showCamera = false
    @State private var showLibrary = false

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
                            Text("Add today's photo").foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(height: 320)
                .onTapGesture { showCamera = true }

                HStack(spacing: 12) {
                    Button("Take photo") { showCamera = true }
                    Button("Choose from library") { showLibrary = true }
                }
                .font(.subheadline)

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
            .navigationTitle(resolution.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showCamera) {
                ImagePicker(source: .camera, image: $image)
            }
            .sheet(isPresented: $showLibrary) {
                ImagePicker(source: .library, image: $image)
            }
        }
    }

    private func submit() async {
        guard let uid = session.userId, let image else { return }
        if await viewModel.submit(uid: uid, resolution: resolution, image: image) {
            await session.refreshResolutions()
            dismiss()
        }
    }
}
