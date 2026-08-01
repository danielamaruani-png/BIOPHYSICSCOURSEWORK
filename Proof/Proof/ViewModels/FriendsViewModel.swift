import Foundation

enum PartnerState {
    case none
    case requestSent
    case requestReceived
    case accepted
}

@MainActor
final class FriendsViewModel: ObservableObject {
    @Published var friends: [PublicProfile] = []
    @Published var searchResults: [PublicProfile] = []
    @Published var searchText: String = ""
    @Published var incomingRequests: [PublicProfile] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var followingIds: Set<String> = []
    private var partnerRequestsByOtherUid: [String: PartnerRequest] = [:]

    func loadFriends(uid: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            async let followingTask = FirestoreService.shared.fetchFollowingIds(followerId: uid)
            async let partnerTask = FirestoreService.shared.fetchPartnerRequests(uid: uid)
            let (ids, requests) = try await (followingTask, partnerTask)

            followingIds = Set(ids)
            friends = try await FirestoreService.shared.fetchPublicProfiles(uids: ids)

            partnerRequestsByOtherUid = Dictionary(
                uniqueKeysWithValues: requests.map { ($0.otherUid(from: uid), $0) }
            )
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

    func isFollowing(_ profile: PublicProfile) -> Bool {
        followingIds.contains(profile.uid)
    }

    func toggleFollow(uid: String, target: PublicProfile) async {
        do {
            if isFollowing(target) {
                try await FirestoreService.shared.unfollow(followerId: uid, followingId: target.uid)
                followingIds.remove(target.uid)
                friends.removeAll { $0.uid == target.uid }
            } else {
                try await FirestoreService.shared.follow(followerId: uid, followingId: target.uid)
                followingIds.insert(target.uid)
                friends.append(target)
            }
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

    /// Asks `target` for permission to see each other's actual proof
    /// photos — a separate, explicit step from following.
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
