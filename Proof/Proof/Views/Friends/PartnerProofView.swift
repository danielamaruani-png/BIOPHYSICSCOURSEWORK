import SwiftUI

/// Shown only for an *accepted* accountability partner — lists their
/// resolutions and lets you drill into each one's actual proof photos
/// via the same read-only ProgressScreenView they'd see for themselves.
struct PartnerProofView: View {
    let partner: PublicProfile

    @State private var resolutions: [Resolution] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        List {
            if isLoading {
                ProgressView()
            } else if resolutions.isEmpty {
                Text("\(partner.name) hasn't added a resolution yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(resolutions) { resolution in
                    NavigationLink(value: resolution) {
                        HStack {
                            Image(systemName: resolution.icon).foregroundStyle(resolution.color)
                            VStack(alignment: .leading) {
                                Text(resolution.name).font(.headline)
                                Text(resolution.targetFrequency.label)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if resolution.currentStreak > 0 {
                                StreakBadge(streak: resolution.currentStreak)
                            }
                        }
                    }
                }
            }
            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red)
            }
        }
        .navigationTitle(partner.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Resolution.self) { resolution in
            ProgressScreenView(ownerUid: partner.uid, resolution: resolution)
        }
        .task {
            do {
                resolutions = try await FirestoreService.shared.fetchResolutions(uid: partner.uid)
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
}
