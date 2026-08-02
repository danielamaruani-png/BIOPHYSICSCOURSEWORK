import Foundation
import UIKit

@MainActor
final class CaptureProofViewModel: ObservableObject {
    @Published var caption: String = "" {
        didSet {
            if caption.count > Self.captionLimit {
                caption = String(caption.prefix(Self.captionLimit))
            }
        }
    }
    @Published var isSubmitting = false
    @Published var errorMessage: String?

    static let captionLimit = 100

    func submit(uid: String, resolution: Resolution, image: UIImage) async -> Bool {
        guard let resolutionId = resolution.id else { return false }
        isSubmitting = true
        defer { isSubmitting = false }

        let day = FirestoreService.dayString()
        do {
            let photoURL = try await StorageService.shared.uploadProofPhoto(
                uid: uid, resolutionId: resolutionId, day: day, image: image
            )
            _ = try await FirestoreService.shared.recordProof(
                uid: uid, resolutionId: resolutionId, photoURL: photoURL,
                caption: caption.isEmpty ? nil : caption
            )
            try await StreakEngine.recordProofAndUpdateStreak(uid: uid, resolutionId: resolutionId, day: day)
            // Cache the photo we already have in memory for the widget,
            // rather than making it re-download what we just uploaded.
            WidgetPhotoCache.save(image: image, forUid: uid)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
