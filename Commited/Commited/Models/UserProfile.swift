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

    /// City/region used to scope Local discovery (crews, events,
    /// challenges). Editable from Profile → Local.
    var localCity: String = "Paris"

    /// When true, this user's crew proof photos are mirrored into the
    /// public `publicFeed` collection for everyone to discover — not
    /// just friends/crew-mates. See Profile → "Public feed" toggle.
    var publicFeedOptIn: Bool = true

    /// Grants access to Creator Tools (editing global Rewards, creating
    /// boosted communities). Deliberately NOT settable by the user
    /// themselves — firestore.rules only allows this field to be
    /// changed by someone who already has it, so the very first creator
    /// has to be flipped on directly in the Firebase console.
    var isCreator: Bool = false

    var uid: String { id ?? "" }
}
