import SwiftUI

/// A single crew's chat: a "checked in today" banner (whoever posted
/// already) above a feed of proof photos and messages, plus a camera
/// button that opens Capture scoped to this crew. The message input is
/// intentionally disabled — same as the interactive mockup, chat
/// messages aren't composable from the client yet (see
/// `CrewFeedItem.swift`'s doc-comment).
struct CrewChatView: View {
    let crew: Crew

    @EnvironmentObject var session: SessionViewModel
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = CrewChatViewModel()
    @State private var showCapture = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !viewModel.checkedInToday.isEmpty {
                    checkedInBanner
                }
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if viewModel.feed.isEmpty && !viewModel.isLoading {
                            Text("No posts yet — be the first to show up!")
                                .foregroundStyle(.secondary)
                                .padding(.top, 40)
                        }
                        ForEach(viewModel.feed) { item in
                            FeedItemRow(item: item)
                        }
                    }
                    .padding()
                }
                HStack {
                    TextField("Message the crew…", text: .constant(""))
                        .disabled(true)
                        .textFieldStyle(.roundedBorder)
                    Image(systemName: "paperplane.fill").foregroundStyle(.secondary)
                }
                .padding()
            }
            .navigationTitle(crew.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Back") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    Button { showCapture = true } label: { Image(systemName: "camera.fill") }
                }
            }
            .task { await load() }
            .sheet(isPresented: $showCapture, onDismiss: { Task { await load() } }) {
                CaptureProofView(crew: crew)
            }
            .onChange(of: session.pendingCaptureCrewId) { _, crewId in
                guard crewId == crew.id else { return }
                showCapture = true
                session.pendingCaptureCrewId = nil
            }
            .onAppear {
                if session.pendingCaptureCrewId == crew.id {
                    showCapture = true
                    session.pendingCaptureCrewId = nil
                }
            }
        }
    }

    private var checkedInBanner: some View {
        HStack(spacing: 10) {
            HStack(spacing: -8) {
                ForEach(viewModel.checkedInToday.prefix(5)) { member in
                    InitialAvatarView(name: member.name, colorHex: member.colorHex, size: 24)
                        .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 2))
                }
            }
            Text("🔥 \(viewModel.checkedInToday.count) people showed up today")
                .font(.caption.bold())
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.12))
    }

    private func load() async {
        guard let crewId = crew.id else { return }
        await viewModel.load(crewId: crewId)
    }
}

private struct FeedItemRow: View {
    let item: CrewFeedItem

    var body: some View {
        if item.type == .proof {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    InitialAvatarView(name: item.authorName, colorHex: item.colorHex, size: 26)
                    Text(item.authorName).font(.caption.bold())
                    Spacer()
                    Text(item.createdAt, style: .relative).font(.caption2).foregroundStyle(.secondary)
                }
                if let urlString = item.photoURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Color(.secondarySystemBackground)
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                if let caption = item.caption {
                    Text(caption).font(.subheadline)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        } else {
            HStack(alignment: .top, spacing: 8) {
                InitialAvatarView(name: item.authorName, colorHex: item.colorHex, size: 26)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.authorName).font(.caption2.bold()).foregroundStyle(.secondary)
                    Text(item.text ?? "").font(.subheadline)
                }
                .padding(10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
        }
    }
}
