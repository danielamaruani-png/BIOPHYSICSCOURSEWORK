import SwiftUI

struct HomeView: View {
    @EnvironmentObject var session: SessionViewModel
    @State private var showCreateResolution = false
    @State private var captureTarget: Resolution?
    @State private var progressTarget: Resolution?

    private var today: String { FirestoreService.dayString() }

    var body: some View {
        NavigationStack {
            Group {
                if session.resolutions.isEmpty {
                    emptyState
                } else {
                    missionList
                }
            }
            .navigationTitle("Today's Mission")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showCreateResolution = true } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateResolution) {
                CreateResolutionView()
            }
            .sheet(item: $captureTarget) { resolution in
                CaptureProofView(resolution: resolution)
            }
            .navigationDestination(item: $progressTarget) { resolution in
                ProgressScreenView(ownerUid: session.userId ?? "", resolution: resolution)
            }
            .task { await session.refreshResolutions() }
            .refreshable { await session.refreshResolutions() }
        }
    }

    private var missionList: some View {
        VStack(spacing: 0) {
            List {
                ForEach(session.resolutions) { resolution in
                    let completed = resolution.lastProofDate == today
                    MissionRow(resolution: resolution, isCompletedToday: completed)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if completed {
                                progressTarget = resolution
                            } else {
                                captureTarget = resolution
                            }
                        }
                }
            }
            .listStyle(.plain)

            PrimaryButton(title: "Add Today's Proof", systemImage: "camera.fill") {
                captureTarget = firstIncompleteResolution
            }
            .padding()
            .disabled(firstIncompleteResolution == nil)
        }
    }

    private var firstIncompleteResolution: Resolution? {
        session.resolutions.first { $0.lastProofDate != today }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "target").font(.system(size: 48)).foregroundStyle(.secondary)
            Text("No resolutions yet").font(.headline)
            Text("Add your first goal to start posting daily proof.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            PrimaryButton(title: "Create a resolution", systemImage: "plus") {
                showCreateResolution = true
            }
            .padding(.horizontal, 40)
        }
        .padding()
    }
}
