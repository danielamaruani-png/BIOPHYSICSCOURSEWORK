import Foundation

enum PartnerState {
    case none
    case requestSent
    case requestReceived
    case accepted
}

/// Backs the Friends tab — accountability partners only. There's no
/// separate lightweight "follow" concept anymore: `PublicProfile` (name,
/// total streak, crew count) is already visible to any signed-in user
/// via search, so following someone just to see that would have been
/// redundant. Becoming partners is the one meaningful relationship left
/// to model here — same shape as the interactive mockup's Friends tab
/// (search, add, accept/decline).
@MainActor
final class FriendsViewModel: ObservableObject {
    @Published var friends: [PublicProfile] = []
    @Published var searchResults: [PublicProfile] = []
    @Published var searchText: String = ""
    @Published var incomingRequests: [PublicProfile] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var partnerRequestsByOtherUid: [String: PartnerRequest] = [:]

    func loadFriends(uid: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let requests = try await FirestoreService.shared.fetchPartnerRequests(uid: uid)
            partnerRequestsByOtherUid = Dictionary(
                uniqueKeysWithValues: requests.map { ($0.otherUid(from: uid), $0) }
            )

            let acceptedIds = requests.filter { $0.status == .accepted }.map { $0.otherUid(from: uid) }
            friends = try await FirestoreService.shared.fetchPublicProfiles(uids: acceptedIds)

            let incomingIds = requests
                .filter { $0.status == .pending && $0.fromUid != uid }
                .map { $0.otherUid(from: uid) }
            incomingRequests = try await FirestoreService.shared.fetchPublicProfiles(uids: incomingIds)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func search() async {
        guard !searchText.isEmpty else { searchResults = []; return }
        do {
            searchResults = try await FirestoreService.shared.searchPublicProfiles(nameStartingWith: searchText)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func partnerState(for profile: PublicProfile, uid: String) -> PartnerState {
        guard let request = partnerRequestsByOtherUid[profile.uid] else { return .none }
        switch request.status {
        case .accepted: return .accepted
        case .declined: return .none
        case .pending: return request.fromUid == uid ? .requestSent : .requestReceived
        }
    }

    func requestPartnership(uid: String, target: PublicProfile) async {
        do {
            try await FirestoreService.shared.sendPartnerRequest(from: uid, to: target.uid)
            await loadFriends(uid: uid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func respondToPartnership(uid: String, target: PublicProfile, accept: Bool) async {
        do {
            try await FirestoreService.shared.respondToPartnerRequest(uid: uid, otherUid: target.uid, accept: accept)
            await loadFriends(uid: uid)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
