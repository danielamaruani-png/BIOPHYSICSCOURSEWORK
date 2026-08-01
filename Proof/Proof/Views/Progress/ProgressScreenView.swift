import SwiftUI

/// Read-only by construction — there's no capture affordance here, so
/// this same view works both for a user's own progress and (once
/// `ownerUid` is a partner's uid instead of the viewer's own) for
/// looking at an accepted partner's actual proof photos.
struct ProgressScreenView: View {
    let ownerUid: String
    let resolution: Resolution

    @StateObject private var viewModel = ProgressViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                statsRow

                VStack(alignment: .leading, spacing: 8) {
                    Text("Last 14 weeks").font(.headline)
                    HeatmapGrid(markedDays: viewModel.proofDates, color: resolution.color)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent proofs").font(.headline)
                    ForEach(viewModel.proofs.sorted { $0.dateString > $1.dateString }.prefix(10)) { proof in
                        HStack(alignment: .top, spacing: 12) {
                            ProofThumbnail(urlString: proof.photoURL)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(proof.dateString).font(.footnote).foregroundStyle(.secondary)
                                if let caption = proof.caption, !caption.isEmpty {
                                    Text(caption).font(.subheadline)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding()
        }
        .navigationTitle(resolution.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load(uid: ownerUid, resolution: resolution)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 16) {
            statTile(title: "Current", value: "\(resolution.currentStreak)")
            statTile(title: "Longest", value: "\(resolution.longestStreak)")
            statTile(title: "Total", value: "\(resolution.totalProofs)")
            statTile(title: "Completion", value: "\(Int(viewModel.completionPercentage(resolution: resolution) * 100))%")
        }
    }

    private func statTile(title: String, value: String) -> some View {
        VStack {
            Text(value).font(.title2.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct ProofThumbnail: View {
    let urlString: String

    var body: some View {
        Group {
            if let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Color(.secondarySystemBackground)
                }
            } else {
                Color(.secondarySystemBackground)
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
