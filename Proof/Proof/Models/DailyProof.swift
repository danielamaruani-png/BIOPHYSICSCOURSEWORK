import FirebaseFirestore

/// A single day's evidence, stored at
/// `users/{uid}/resolutions/{resolutionId}/proofs/{yyyy-MM-dd}`.
/// Using the date string as the document ID is what enforces
/// "only one proof per resolution per day" without extra query logic.
struct DailyProof: Codable, Identifiable {
    @DocumentID var id: String? // yyyy-MM-dd
    var photoURL: String
    var caption: String?
    var completedAt: Date

    var dateString: String { id ?? "" }
}
