import Foundation

/// Backs a single crew's chat: the "checked in today" banner (whichever
/// members have `doneToday == true`) plus the proof/message feed below
/// it.
@MainActor
final class CrewChatViewModel: ObservableObject {
    @Published var feed: [CrewFeedItem] = []
    @Published var members: [CrewMember] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    var checkedInToday: [CrewMember] { members.filter(\.doneToday) }

    func load(crewId: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let feedTask = FirestoreService.shared.fetchCrewFeed(crewId: crewId)
            async let membersTask = FirestoreService.shared.fetchCrewMembers(crewId: crewId)
            (feed, members) = try await (feedTask, membersTask)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
