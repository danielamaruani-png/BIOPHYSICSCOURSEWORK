import FirebaseFirestore

/// Private profile document at `users/{uid}`.
struct UserProfile: Codable, Identifiable {
    @DocumentID var id: String?
    var name: String
    var photoURL: String?
    var bio: String?
    var createdAt: Date
    var onboardingCompleted: Bool = false
    var pushToken: String? // FCM token; read by notifyPartnersOnProof (functions/index.js)

    var uid: String { id ?? "" }
}
