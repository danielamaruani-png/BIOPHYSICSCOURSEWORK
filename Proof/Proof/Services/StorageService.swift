import FirebaseStorage
import UIKit

enum StorageError: Error {
    case encodingFailed
}

/// Uploads proof photos to Firebase Storage under a per-user,
/// per-resolution path so security rules can scope access per owner.
final class StorageService {
    static let shared = StorageService()
    private let storage = Storage.storage()

    func uploadProofPhoto(uid: String, resolutionId: String, day: String, image: UIImage) async throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.7) else {
            throw StorageError.encodingFailed
        }
        let ref = storage.reference().child("proofs/\(uid)/\(resolutionId)/\(day).jpg")
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        _ = try await ref.putDataAsync(data, metadata: metadata)
        let url = try await ref.downloadURL()
        return url.absoluteString
    }
}
