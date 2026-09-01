import Foundation
import UIKit

/// Backs the "post today's proof" flow for a single crew. Camera-only
/// by construction — the view only ever hands this a `UIImage` that
/// came from `ImagePicker`, which no longer offers a photo-library
/// source at all (see ImagePicker.swift).
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

    /// Posts to the crew's own feed and, if the poster has opted into
    /// the public Feed, mirrors the same photo there too — two explicit
    /// writes so a crew-only post never silently becomes public.
    func submit(uid: String, crewId: String, authorName: String, colorHex: String, image: UIImage) async -> Bool {
        isSubmitting = true
        defer { isSubmitting = false }

        let day = FirestoreService.dayString()
        let finalCaption = caption.isEmpty ? "Showed up today 🔥" : caption
        do {
            let photoURL = try await StorageService.shared.uploadProofPhoto(
                uid: uid, crewId: crewId, day: day, image: image
            )
            _ = try await FirestoreService.shared.postCrewProof(
                crewId: crewId, uid: uid, name: authorName, colorHex: colorHex,
                photoURL: photoURL, caption: finalCaption
            )
            try await FirestoreService.shared.postToPublicFeedIfOptedIn(
                authorUid: uid, authorName: authorName, colorHex: colorHex,
                photoURL: photoURL, caption: finalCaption
            )
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
