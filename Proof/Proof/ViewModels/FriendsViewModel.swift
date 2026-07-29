import Foundation

@MainActor
final class FriendsViewModel: ObservableObject {
    @Published var friends: [PublicProfile] = []
    @Published var searchResults: [PublicProfile] = []
    @Published var searchText: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    private var followingIds: Set<String> = []

    func loadFriends(uid: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let ids = try await FirestoreService.shared.fetchFollowingIds(followerId: uid)
            followingIds = Set(ids)
            friends = try await FirestoreService.shared.fetchPublicProfiles(uids: ids)
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
}
