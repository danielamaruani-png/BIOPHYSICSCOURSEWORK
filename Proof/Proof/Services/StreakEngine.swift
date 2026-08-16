import FirebaseFirestore
import Foundation

/// Updates a crew member's denormalized streak counters right after a
/// proof is posted. Runs client-side as a Firestore transaction — same
/// as Phase 1, there's still no Cloud Function computing streaks
/// server-side, so a determined client could in principle forge one
/// (called out in README's "Known gaps").
///
/// Known gap: `doneToday` is set `true` here but nothing ever flips it
/// back to `false` at midnight — that needs a scheduled Cloud Function
/// (or a "is lastProofDate == today" check computed at read time
/// instead of trusting the stored flag) before this ships.
enum StreakEngine {
    static func recordProofAndUpdateStreak(crewId: String, uid: String, day: String) async throws {
        let db = Firestore.firestore()
        let memberRef = db.collection("crews").document(crewId)
            .collection("members").document(uid)

        try await db.runTransaction { transaction, errorPointer in
            do {
                let snapshot = try transaction.getDocument(memberRef)
                let lastProofDate = snapshot.get("lastProofDate") as? String
                let currentStreak = snapshot.get("streak") as? Int ?? 0
                let longestStreak = snapshot.get("longestStreak") as? Int ?? 0

                let newStreak: Int
                if let lastProofDate, isYesterday(lastProofDate, relativeTo: day) {
                    newStreak = currentStreak + 1
                } else if lastProofDate == day {
                    newStreak = currentStreak // already recorded today, no-op streak-wise
                } else {
                    newStreak = 1
                }

                transaction.updateData([
                    "streak": newStreak,
                    "longestStreak": max(longestStreak, newStreak),
                    "lastProofDate": day,
                    "doneToday": true
                ], forDocument: memberRef)
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
