import FirebaseFirestore

/// Thin wrapper around Firestore access patterns. Kept as one service
/// (rather than one per collection) because the whole data model is
/// still small enough that splitting it further would just add
/// indirection — same call as Phase 1's version of this file.
final class FirestoreService {
    static let shared = FirestoreService()
    private let db = Firestore.firestore()

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = .current
        return formatter
    }()

    static func dayString(for date: Date = Date()) -> String {
        dateFormatter.string(from: date)
    }

    // MARK: - User profile

    func createUserProfileIfNeeded(uid: String, name: String, photoURL: String?) async throws {
        let ref = db.collection("users").document(uid)
        let snapshot = try await ref.getDocument()
        guard !snapshot.exists else { return }

        let profile = UserProfile(name: name, photoURL: photoURL, bio: nil, createdAt: Date())
        try ref.setData(from: profile)

        let publicProfile = PublicProfile(name: name, photoURL: photoURL, totalStreak: 0, crewCount: 0)
        try db.collection("publicProfiles").document(uid).setData(from: publicProfile)
    }

    func fetchUserProfile(uid: String) async throws -> UserProfile {
        try await db.collection("users").document(uid).getDocument(as: UserProfile.self)
    }

    func updateProfile(uid: String, name: String, bio: String?, photoURL: String?) async throws {
        // Reaching this call at all — even leaving bio blank — is what
        // marks onboarding done; gating on `bio` itself would trap a
        // user who intentionally skips an optional field.
        var fields: [String: Any] = ["name": name, "onboardingCompleted": true]
        if let bio { fields["bio"] = bio }
        if let photoURL { fields["photoURL"] = photoURL }
        try await db.collection("users").document(uid).updateData(fields)

        var publicFields: [String: Any] = ["name": name]
        if let photoURL { publicFields["photoURL"] = photoURL }
        try await db.collection("publicProfiles").document(uid).updateData(publicFields)
    }

    /// Saves this device's FCM token so notifyPartnersOnProof (Cloud
    /// Function) can reach it. Only ever read server-side with Admin
    /// privileges — no rule change needed beyond the existing
    /// owner-only write on `users/{uid}`.
    func updatePushToken(uid: String, token: String) async throws {
        try await db.collection("users").document(uid).updateData(["pushToken": token])
    }

    /// Profile → Local: which city/region this user discovers, searches,
    /// and creates public crews and events/challenges in.
    func updateLocalCity(uid: String, city: String) async throws {
        try await db.collection("users").document(uid).updateData(["localCity": city])
    }

    /// Profile → "Public feed" toggle. Turning this off doesn't remove
    /// posts already mirrored into `publicFeed` — same "doesn't rewrite
    /// history" behavior as the interactive mockup.
    func updatePublicFeedOptIn(uid: String, optedIn: Bool) async throws {
        try await db.collection("users").document(uid).updateData(["publicFeedOptIn": optedIn])
    }

    func fetchPublicProfile(uid: String) async throws -> PublicProfile {
        try await db.collection("publicProfiles").document(uid).getDocument(as: PublicProfile.self)
    }

    /// Keeps `publicProfiles/{uid}` (name/photo aside) in sync with
    /// crew activity — called after any crew join/create/proof so
    /// friend search and search results show current totals.
    func refreshPublicProfileStats(uid: String, totalStreak: Int, crewCount: Int) async throws {
        try await db.collection("publicProfiles").document(uid).updateData([
            "totalStreak": totalStreak,
            "crewCount": crewCount
        ])
    }

    // MARK: - Crews

    private var crewsRef: CollectionReference { db.collection("crews") }
    private func membersRef(crewId: String) -> CollectionReference { crewsRef.document(crewId).collection("members") }
    private func feedRef(crewId: String) -> CollectionReference { crewsRef.document(crewId).collection("feed") }

    /// Creates a crew and its `members` subcollection docs in one go.
    /// `invitedMembers` is only used for private crews created with
    /// friends pre-added (see Create Crew → "Add friends"); public
    /// crews (including boosted ones) always start with just the owner.
    @discardableResult
    func createCrew(
        _ crew: Crew,
        ownerName: String,
        ownerColorHex: String,
        invitedMembers: [(uid: String, name: String, colorHex: String)] = []
    ) async throws -> String {
        let ref = crewsRef.document()
        var withId = crew
        withId.id = ref.documentID
        withId.memberUids = [crew.ownerUid] + invitedMembers.map(\.uid)
        withId.memberCount = withId.memberUids.count
        try ref.setData(from: withId)

        let ownerMember = CrewMember(name: ownerName, colorHex: ownerColorHex)
        try membersRef(crewId: ref.documentID).document(crew.ownerUid).setData(from: ownerMember)
        for invitee in invitedMembers {
            let member = CrewMember(name: invitee.name, colorHex: invitee.colorHex)
            try membersRef(crewId: ref.documentID).document(invitee.uid).setData(from: member)
        }
        return ref.documentID
    }

    /// My Crews: private crews this user belongs to.
    func fetchMyCrews(uid: String) async throws -> [Crew] {
        let snapshot = try await crewsRef
            .whereField("isPrivate", isEqualTo: true)
            .whereField("memberUids", arrayContains: uid)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: Crew.self) }
    }

    /// All public crews for a city — callers split this into "already
    /// joined" (→ Local "Chats") vs "not yet joined" (→ "Discover more
    /// nearby") by checking `memberUids.contains(uid)` client-side,
    /// same partition the interactive mockup does between
    /// `local.chats` and `local.discover`.
    func fetchLocalCrews(city: String) async throws -> [Crew] {
        let snapshot = try await crewsRef
            .whereField("isPrivate", isEqualTo: false)
            .whereField("city", isEqualTo: city)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: Crew.self) }
            .sorted { a, b in
                if a.boosted != b.boosted { return a.boosted && !b.boosted }
                return a.name < b.name
            }
    }

    func joinCrew(crewId: String, uid: String, name: String, colorHex: String) async throws {
        try await crewsRef.document(crewId).updateData([
            "memberUids": FieldValue.arrayUnion([uid]),
            "memberCount": FieldValue.increment(Int64(1))
        ])
        let member = CrewMember(name: name, colorHex: colorHex)
        try membersRef(crewId: crewId).document(uid).setData(from: member, merge: true)
    }

    func fetchCrewMembers(crewId: String) async throws -> [CrewMember] {
        let snapshot = try await membersRef(crewId: crewId).getDocuments()
        return try snapshot.documents.map { try $0.data(as: CrewMember.self) }
    }

    func fetchMyCrewMembership(crewId: String, uid: String) async throws -> CrewMember? {
        let snapshot = try await membersRef(crewId: crewId).document(uid).getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: CrewMember.self)
    }

    func fetchCrewFeed(crewId: String) async throws -> [CrewFeedItem] {
        let snapshot = try await feedRef(crewId: crewId)
            .order(by: "createdAt", descending: true)
            .limit(to: 100)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: CrewFeedItem.self) }
    }

    /// Posts today's proof to a crew's chat feed and bumps the poster's
    /// streak for that crew. Doesn't touch `publicFeed` — see
    /// `postToPublicFeedIfOptedIn`, which callers invoke separately so a
    /// crew post and its public mirror stay two explicit steps rather
    /// than one method secretly doing both.
    @discardableResult
    func postCrewProof(
        crewId: String,
        uid: String,
        name: String,
        colorHex: String,
        photoURL: String,
        caption: String
    ) async throws -> String {
        let day = Self.dayString()
        let item = CrewFeedItem(
            type: .proof, authorUid: uid, authorName: name, colorHex: colorHex,
            photoURL: photoURL, caption: caption
        )
        let ref = feedRef(crewId: crewId).document()
        try ref.setData(from: item)
        try await StreakEngine.recordProofAndUpdateStreak(crewId: crewId, uid: uid, day: day)
        return ref.documentID
    }

    func setCrewEvent(crewId: String, event: CrewEvent) async throws {
        try await db.collection("crews").document(crewId).updateData(["event": try Firestore.Encoder().encode(event)])
    }

    func setCrewChallenge(crewId: String, challenge: CrewChallenge) async throws {
        try await db.collection("crews").document(crewId).updateData(["challenge": try Firestore.Encoder().encode(challenge)])
    }

    /// Creator Tools → Boosted communities → Remove. Deletes the crew
    /// doc outright rather than just clearing `boosted` — matches the
    /// mockup's admin panel, which only ever lists (and removes) crews
    /// it created itself, never regular public crews other users made.
    func deleteCrew(crewId: String) async throws {
        try await db.collection("crews").document(crewId).delete()
    }

    // MARK: - Local (city-wide events & challenges)

    func fetchLocalEvents(city: String) async throws -> [LocalEvent] {
        let snapshot = try await db.collection("localEvents")
            .whereField("city", isEqualTo: city)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: LocalEvent.self) }
    }

    func fetchLocalChallenges(city: String) async throws -> [LocalChallenge] {
        let snapshot = try await db.collection("localChallenges")
            .whereField("city", isEqualTo: city)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: LocalChallenge.self) }
    }

    @discardableResult
    func createLocalEvent(_ event: LocalEvent) async throws -> String {
        let ref = db.collection("localEvents").document()
        var withId = event
        withId.id = ref.documentID
        try ref.setData(from: withId)
        return ref.documentID
    }

    @discardableResult
    func createLocalChallenge(_ challenge: LocalChallenge) async throws -> String {
        let ref = db.collection("localChallenges").document()
        var withId = challenge
        withId.id = ref.documentID
        try ref.setData(from: withId)
        return ref.documentID
    }

    // MARK: - Public feed (BeReal-style, opt-in)

    func fetchPublicFeed(limit: Int = 50) async throws -> [PublicFeedPost] {
        let snapshot = try await db.collection("publicFeed")
            .order(by: "createdAt", descending: true)
            .limit(to: limit)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: PublicFeedPost.self) }
    }

    /// No-ops (and doesn't throw) if the author has opted out — callers
    /// don't need to check `publicFeedOptIn` themselves before calling
    /// this after a crew proof post.
    func postToPublicFeedIfOptedIn(
        authorUid: String, authorName: String, colorHex: String, photoURL: String, caption: String
    ) async throws {
        let profile = try await fetchUserProfile(uid: authorUid)
        guard profile.publicFeedOptIn else { return }
        let post = PublicFeedPost(
            authorUid: authorUid, authorName: authorName, colorHex: colorHex,
            photoURL: photoURL, caption: caption
        )
        try db.collection("publicFeed").document().setData(from: post)
    }

    /// Toggles one specific emoji for one specific user on one post —
    /// tapping ❤️ twice removes just the ❤️, a 🔥 reacted alongside it
    /// (if any) is untouched. See `FeedReaction`'s doc-comment for why
    /// the subcollection is keyed by `{uid}_{emoji}` instead of `{uid}`.
    func toggleReaction(postId: String, uid: String, emoji: String) async throws {
        let postRef = db.collection("publicFeed").document(postId)
        let reactionRef = postRef.collection("reactions").document(FeedReaction.docId(uid: uid, emoji: emoji))

        try await db.runTransaction { transaction, errorPointer in
            do {
                let existing = try transaction.getDocument(reactionRef)
                if existing.exists {
                    transaction.deleteDocument(reactionRef)
                    transaction.updateData(["reactionCounts.\(emoji)": FieldValue.increment(Int64(-1))], forDocument: postRef)
                } else {
                    transaction.setData(["uid": uid, "emoji": emoji], forDocument: reactionRef)
                    transaction.updateData(["reactionCounts.\(emoji)": FieldValue.increment(Int64(1))], forDocument: postRef)
                }
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            return nil
        }
    }

    func fetchComments(postId: String) async throws -> [FeedComment] {
        let snapshot = try await db.collection("publicFeed").document(postId).collection("comments")
            .order(by: "createdAt")
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: FeedComment.self) }
    }

    func addComment(postId: String, authorUid: String, authorName: String, text: String) async throws {
        let postRef = db.collection("publicFeed").document(postId)
        let comment = FeedComment(authorUid: authorUid, authorName: authorName, text: text)
        try postRef.collection("comments").document().setData(from: comment)
        try await postRef.updateData(["commentCount": FieldValue.increment(Int64(1))])
    }

    // MARK: - Rewards (Creator Tools)

    func fetchRewards() async throws -> [Reward] {
        let snapshot = try await db.collection("rewards").order(by: "days").getDocuments()
        return try snapshot.documents.map { try $0.data(as: Reward.self) }
    }

    /// Creates a new reward if `reward.id` is nil, otherwise overwrites
    /// the existing one — same create-or-edit split the mockup's "Edit
    /// reward" sheet uses (`editingRewardIndex == -1` vs. not).
    @discardableResult
    func saveReward(_ reward: Reward) async throws -> String {
        if let id = reward.id {
            try db.collection("rewards").document(id).setData(from: reward)
            return id
        } else {
            let ref = db.collection("rewards").document()
            var withId = reward
            withId.id = ref.documentID
            try ref.setData(from: withId)
            return ref.documentID
        }
    }

    func deleteReward(id: String) async throws {
        try await db.collection("rewards").document(id).delete()
    }

    // MARK: - Public profiles

    func fetchPublicProfiles(uids: [String]) async throws -> [PublicProfile] {
        guard !uids.isEmpty else { return [] }
        // Firestore 'in' queries cap at 30 ids, well above what a
        // friends list realistically needs at once.
        let snapshot = try await db.collection("publicProfiles")
            .whereField(FieldPath.documentID(), in: Array(uids.prefix(30)))
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: PublicProfile.self) }
    }

    func searchPublicProfiles(nameStartingWith prefix: String) async throws -> [PublicProfile] {
        guard !prefix.isEmpty else { return [] }
        let end = prefix + "\u{f8ff}"
        let snapshot = try await db.collection("publicProfiles")
            .order(by: "name")
            .start(at: [prefix])
            .end(at: [end])
            .limit(to: 20)
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: PublicProfile.self) }
    }

    // MARK: - Accountability partners (mutual, unchanged from Phase 1)

    /// Sends (or re-sends after a decline) a request to become
    /// accountability partners — distinct from `follow`, which never
    /// needs the other person's consent.
    func sendPartnerRequest(from: String, to: String) async throws {
        let id = PartnerRequest.pairId(from, to)
        let request = PartnerRequest(
            uidA: from < to ? from : to,
            uidB: from < to ? to : from,
            fromUid: from,
            status: .pending,
            createdAt: Date(),
            respondedAt: nil
        )
        try db.collection("partnerRequests").document(id).setData(from: request)
    }

    /// Only the recipient of a request may call this — enforced again
    /// server-side by firestore.rules, not just here.
    func respondToPartnerRequest(uid: String, otherUid: String, accept: Bool) async throws {
        let id = PartnerRequest.pairId(uid, otherUid)
        try await db.collection("partnerRequests").document(id).updateData([
            "status": accept ? PartnerStatus.accepted.rawValue : PartnerStatus.declined.rawValue,
            "respondedAt": Date()
        ])
    }

    /// All partner requests (any status, either direction) touching
    /// this user. Callers split it into incoming/outgoing/accepted by
    /// comparing `fromUid`/`status` against `uid`.
    func fetchPartnerRequests(uid: String) async throws -> [PartnerRequest] {
        async let asA = db.collection("partnerRequests").whereField("uidA", isEqualTo: uid).getDocuments()
        async let asB = db.collection("partnerRequests").whereField("uidB", isEqualTo: uid).getDocuments()
        let (snapshotA, snapshotB) = try await (asA, asB)
        let requests = try (snapshotA.documents + snapshotB.documents).map { try $0.data(as: PartnerRequest.self) }
        return requests
    }

    func fetchAcceptedPartnerIds(uid: String) async throws -> [String] {
        try await fetchPartnerRequests(uid: uid)
            .filter { $0.status == .accepted }
            .map { $0.otherUid(from: uid) }
    }
}
