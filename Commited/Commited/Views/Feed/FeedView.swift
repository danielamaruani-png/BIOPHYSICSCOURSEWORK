import SwiftUI

private let reactionSet = ["❤️", "😂", "😮", "🔥", "👏"]

/// BeReal-style public Feed tab: random posts from anyone with
/// `UserProfile.publicFeedOptIn == true`, not just friends or
/// crew-mates. Every post carries a reaction row and a comment count
/// that opens `FeedCommentsView`.
struct FeedView: View {
    @EnvironmentObject var session: SessionViewModel
    @StateObject private var viewModel = FeedViewModel()
    @State private var openedPost: PublicFeedPost?

    var body: some View {
        NavigationStack {
            ScrollView {
                Text("Random photos from people with a public feed — anyone can post, react, and comment.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 8)

                LazyVStack(spacing: 14) {
                    if viewModel.posts.isEmpty && !viewModel.isLoading {
                        Text("No public posts right now.")
                            .foregroundStyle(.secondary)
                            .padding(.top, 40)
                    }
                    ForEach(viewModel.posts) { post in
                        FeedCardView(post: post, viewModel: viewModel, uid: session.userId ?? "") {
                            openedPost = post
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Feed")
            .task { await viewModel.load() }
            .refreshable { await viewModel.load() }
            .sheet(item: $openedPost) { post in
                FeedCommentsView(post: post, viewModel: viewModel, uid: session.userId ?? "", name: session.profile?.name ?? "You")
            }
        }
    }
}

private struct FeedCardView: View {
    let post: PublicFeedPost
    @ObservedObject var viewModel: FeedViewModel
    let uid: String
    let onOpenComments: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                InitialAvatarView(name: post.authorName, colorHex: post.colorHex, size: 30)
                Text(post.authorName).font(.subheadline.bold())
                Spacer()
                Text(post.createdAt, style: .relative).font(.caption).foregroundStyle(.secondary)
            }
            if let url = URL(string: post.photoURL) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color(.secondarySystemBackground)
                }
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            Text(post.caption).font(.subheadline)

            HStack {
                reactionRow
                Spacer()
                Button(action: onOpenComments) {
                    Label("\(post.commentCount)", systemImage: "bubble.left")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
    }

    private var reactionRow: some View {
        HStack(spacing: 6) {
            ForEach(reactionSet, id: \.self) { emoji in
                let count = post.reactionCounts[emoji] ?? 0
                let mine = viewModel.hasReacted(postId: post.id ?? "", emoji: emoji)
                if count > 0 || mine {
                    Button {
                        Task { await viewModel.react(postId: post.id ?? "", uid: uid, emoji: emoji) }
                    } label: {
                        Text("\(emoji) \(count)")
                            .font(.caption.bold())
                            .padding(.horizontal, 8).padding(.vertical, 4)
                            .background(mine ? Color.accentColor.opacity(0.16) : Color(.tertiarySystemBackground), in: Capsule())
                            .foregroundStyle(mine ? Color.accentColor : .secondary)
                    }
                }
            }
            ForEach(reactionSet.filter { (post.reactionCounts[$0] ?? 0) == 0 }, id: \.self) { emoji in
                Button {
                    Task { await viewModel.react(postId: post.id ?? "", uid: uid, emoji: emoji) }
                } label: {
                    Text(emoji)
                        .font(.caption)
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color(.tertiarySystemBackground), in: Capsule())
                }
            }
        }
    }
}
