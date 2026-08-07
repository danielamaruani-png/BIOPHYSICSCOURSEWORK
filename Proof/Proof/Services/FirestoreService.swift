import FirebaseFirestore

/// Thin wrapper around Firestore access patterns. Kept as one service
/// (rather than one per collection) because Phase 1's data model is
/// small enough that splitting it further would just add indirection.
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

        let publicProfile = PublicProfile(
            name: name,
            photoURL: photoURL,
            bestCurrentStreak: 0,
            todayCompleted: false,
            todayDate: Self.dayString(),
            activeResolutionsCount: 0
        )
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

    // MARK: - Resolutions

    private func resolutionsRef(uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("resolutions")
    }

    func fetchResolutions(uid: String) async throws -> [Resolution] {
        let snapshot = try await resolutionsRef(uid: uid).order(by: "createdAt").getDocuments()
        return try snapshot.documents.map { try $0.data(as: Resolution.self) }
    }

    @discardableResult
    func createResolution(uid: String, _ resolution: Resolution) async throws -> String {
        let ref = resolutionsRef(uid: uid).document()
        var withId = resolution
        withId.id = ref.documentID
        try ref.setData(from: withId)
        try await bumpActiveResolutionsCount(uid: uid)
        return ref.documentID
    }

    func deleteResolution(uid: String, resolutionId: String) async throws {
        try await resolutionsRef(uid: uid).document(resolutionId).delete()
        try await bumpActiveResolutionsCount(uid: uid)
    }

    private func bumpActiveResolutionsCount(uid: String) async throws {
        let count = try await resolutionsRef(uid: uid).getDocuments().documents.count
        try await db.collection("publicProfiles").document(uid).updateData([
            "activeResolutionsCount": count
        ])
    }

    // MARK: - Daily proofs

    private func proofsRef(uid: String, resolutionId: String) -> CollectionReference {
        resolutionsRef(uid: uid).document(resolutionId).collection("proofs")
    }

    func fetchProof(uid: String, resolutionId: String, day: String) async throws -> DailyProof? {
        let snapshot = try await proofsRef(uid: uid, resolutionId: resolutionId).document(day).getDocument()
        guard snapshot.exists else { return nil }
        return try snapshot.data(as: DailyProof.self)
    }

    func fetchAllProofs(uid: String, resolutionId: String) async throws -> [DailyProof] {
        let snapshot = try await proofsRef(uid: uid, resolutionId: resolutionId)
            .order(by: FieldPath.documentID())
            .getDocuments()
        return try snapshot.documents.map { try $0.data(as: DailyProof.self) }
    }

    /// Writes the proof doc for today. The date-string document ID is
    /// what makes "one proof per resolution per day" a plain `set`
    /// rather than a query-then-check.
    func recordProof(uid: String, resolutionId: String, photoURL: String, caption: String?) async throws -> String {
        let day = Self.dayString()
        let proof = DailyProof(photoURL: photoURL, caption: caption, completedAt: Date())
        try proofsRef(uid: uid, resolutionId: resolutionId).document(day).setData(from: proof)
        return day
    }

    // MARK: - Follows / public profiles

    func follow(followerId: String, followingId: String) async throws {
        let id = FollowRelationship.documentId(follower: followerId, following: followingId)
        let relationship = FollowRelationship(followerId: followerId, followingId: followingId, createdAt: Date())
        try db.collection("follows").document(id).setData(from: relationship)
    }

    func unfollow(followerId: String, followingId: String) async throws {
        let id = FollowRelationship.documentId(follower: followerId, following: followingId)
        try await db.collection("follows").document(id).delete()
    }

    func fetchFollowingIds(followerId: String) async throws -> [String] {
        let snapshot = try await db.collection("follows")
            .whereField("followerId", isEqualTo: followerId)
            .getDocuments()
        return snapshot.documents.compactMap { $0.data()["followingId"] as? String }
    }

    func fetchPublicProfiles(uids: [String]) async throws -> [PublicProfile] {
        guard !uids.isEmpty else { return [] }
        // Firestore 'in' queries cap at 30 ids, which is well above what
        // a Phase 1 friends list needs.
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

    // MARK: - Accountability partners (mutual proof sharing)

    /// Sends (or re-sends after a decline) a request to share actual
    /// proof photos with someone — distinct from `follow`, which never
    /// needs the other person's consent because it only ever exposes
    /// today's ✅/⭕.
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
