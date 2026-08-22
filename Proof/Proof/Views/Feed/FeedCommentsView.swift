import SwiftUI

/// Comments sheet for one Feed post. Posting a comment is live (unlike
/// crew chat's disabled message field) since the mockup's Feed comment
/// input is interactive.
struct FeedCommentsView: View {
    let post: PublicFeedPost
    @ObservedObject var viewModel: FeedViewModel
    let uid: String
    let name: String

    @Environment(\.dismiss) private var dismiss
    @State private var draft = ""
    @State private var isSending = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if viewModel.comments.isEmpty {
                            Text("No comments yet — be the first.")
                                .foregroundStyle(.secondary)
                                .padding(.top, 24)
                        }
                        ForEach(viewModel.comments) { comment in
                            HStack(alignment: .top, spacing: 8) {
                                InitialAvatarView(name: comment.authorName, colorHex: "#D9713C", size: 26)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(comment.authorName).font(.caption2.bold()).foregroundStyle(.secondary)
                                    Text(comment.text).font(.subheadline)
                                }
                                .padding(10)
                                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                            }
                        }
                    }
                    .padding()
                }
                HStack {
                    TextField("Add a comment…", text: $draft)
                        .textFieldStyle(.roundedBorder)
                    Button {
                        Task { await send() }
                    } label: {
                        Image(systemName: "paperplane.fill")
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty || isSending)
                }
                .padding()
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
            .task { await viewModel.loadComments(postId: post.id ?? "") }
        }
    }

    private func send() async {
        isSending = true
        defer { isSending = false }
        await viewModel.addComment(postId: post.id ?? "", authorUid: uid, authorName: name, text: draft)
        draft = ""
    }
}
