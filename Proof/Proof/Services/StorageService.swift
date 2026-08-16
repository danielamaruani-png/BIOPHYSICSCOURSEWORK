import FirebaseStorage
import UIKit

enum StorageError: Error {
    case encodingFailed
}

/// Uploads proof photos to Firebase Storage under a per-user,
/// per-crew path so security rules can scope access per crew
/// membership. Always fed a camera-captured `UIImage` — the capture UI
/// no longer offers a photo-library source at all, so there's nothing
/// here that needs to special-case where the image came from.
final class StorageService {
    static let shared = StorageService()
    private let storage = Storage.storage()

    func uploadProofPhoto(uid: String, crewId: String, day: String, image: UIImage) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            throw StorageError.encodingFailed
        }
        let ref = storage.reference().child("proofs/\(uid)/\(crewId)/\(day).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await ref.putDataAsync(data, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }
}
