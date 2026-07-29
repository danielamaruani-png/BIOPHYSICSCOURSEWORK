import SwiftUI

struct ProgressScreenView: View {
    let resolution: Resolution

    @EnvironmentObject var session: SessionViewModel
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
                            Text(proof.dateString).font(.footnote).foregroundStyle(.secondary)
                            if let caption = proof.caption, !caption.isEmpty {
                                Text(caption)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(resolution.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            guard let uid = session.userId else { return }
            await viewModel.load(uid: uid, resolution: resolution)
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
