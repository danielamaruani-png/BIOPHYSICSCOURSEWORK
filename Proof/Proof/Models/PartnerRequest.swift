import FirebaseFirestore

enum PartnerStatus: String, Codable {
    case pending
    case accepted
    case declined
}

/// A mutual accountability-partner link, stored at
/// `partnerRequests/{pairId}` where `pairId` is the two uids sorted and
/// joined with "_". Sorting the pair into the document ID (rather than
/// keying by requester) is what lets security rules check "are these
/// two people partners" with a single `exists`/`get`, and guarantees
/// there's only ever one relationship per pair.
///
/// Being partners is strictly more than following: it's what unlocks
/// reading each other's actual proof photos, not just today's ✅/⭕.
struct PartnerRequest: Codable, Identifiable {
    @DocumentID var id: String?
    var uidA: String // lexicographically smaller uid
    var uidB: String
    var fromUid: String // who sent the request; only the other side may accept/decline
    var status: PartnerStatus
    var createdAt: Date
    var respondedAt: Date?

    static func pairId(_ a: String, _ b: String) -> String {
        a < b ? "\(a)_\(b)" : "\(b)_\(a)"
    }

    func otherUid(from uid: String) -> String {
        uid == uidA ? uidB : uidA
    }
}
