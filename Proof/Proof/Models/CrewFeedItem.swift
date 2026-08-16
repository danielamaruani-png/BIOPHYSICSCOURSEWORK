import FirebaseFirestore

enum CrewFeedItemType: String, Codable {
    case proof
    case message
}

/// One entry in a crew's chat feed at `crews/{crewId}/feed/{itemId}` —
/// either a proof photo or a plain chat message. Chat messages aren't
/// composable from the client yet (the message field in the UI is
/// intentionally disabled, same as the interactive mockup) but the
/// model supports them so that's a UI-only gap, not a data one.
struct CrewFeedItem: Codable, Identifiable {
    @DocumentID var id: String?
    var type: CrewFeedItemType
    var authorUid: String
    var authorName: String
    var colorHex: String
    var photoURL: String?
    var caption: String?
    var text: String?
    var createdAt: Date = Date()
}
