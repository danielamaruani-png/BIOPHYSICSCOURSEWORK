import FirebaseFirestore
import Foundation

/// Updates a resolution's denormalized streak counters right after a
/// proof is recorded. Runs client-side as a Firestore transaction —
/// Phase 1 has no Cloud Functions, and a transaction is enough to keep
/// the counters correct even if two devices write around the same time.
enum StreakEngine {
    static func recordProofAndUpdateStreak(uid: String, resolutionId: String, day: String) async throws {
        let db = Firestore.firestore()
        let resolutionRef = db.collection("users").document(uid)
            .collection("resolutions").document(resolutionId)

        try await db.runTransaction { transaction, errorPointer in
            do {
                let snapshot = try transaction.getDocument(resolutionRef)
                let lastProofDate = snapshot.get("lastProofDate") as? String
                let currentStreak = snapshot.get("currentStreak") as? Int ?? 0
                let longestStreak = snapshot.get("longestStreak") as? Int ?? 0
                let totalProofs = snapshot.get("totalProofs") as? Int ?? 0

                let newStreak: Int
                if let lastProofDate, isYesterday(lastProofDate, relativeTo: day) {
                    newStreak = currentStreak + 1
                } else if lastProofDate == day {
                    newStreak = currentStreak // already recorded today, no-op streak-wise
                } else {
                    newStreak = 1
                }

                transaction.updateData([
                    "currentStreak": newStreak,
                    "longestStreak": max(longestStreak, newStreak),
                    "totalProofs": lastProofDate == day ? totalProofs : totalProofs + 1,
                    "lastProofDate": day
                ], forDocument: resolutionRef)
            } catch {
                errorPointer?.pointee = error as NSError
                return nil
            }
            return nil
        }
    }

    private static func isYesterday(_ candidate: String, relativeTo day: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let candidateDate = formatter.date(from: candidate),
              let dayDate = formatter.date(from: day)
        else { return false }
        let diff = Calendar.current.dateComponents([.day], from: candidateDate, to: dayDate).day
        return diff == 1
    }
}
