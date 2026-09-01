import Foundation
import UIKit

/// Small photos (mine + one accepted partner's) cached as plain JPEG
/// files inside the shared App Group container, so the widget can
/// render an actual proof photo without needing its own network
/// access or Firebase session — it just reads a file by a
/// deterministic name (`<uid>.jpg`).
enum WidgetPhotoCache {
    private static var directory: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: WidgetSnapshot.appGroupId)?
            .appendingPathComponent("widgetPhotos", isDirectory: true)
    }

    static func fileName(forUid uid: String) -> String { "\(uid).jpg" }

    /// Called right after a successful capture, using the UIImage the
    /// user just took — avoids re-downloading what we already have in
    /// memory.
    static func save(image: UIImage, forUid uid: String) {
        guard let dir = directory, let data = image.jpegData(compressionQuality: 0.55) else { return }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? data.write(to: dir.appendingPathComponent(fileName(forUid: uid)), options: .atomic)
    }

    /// Called while refreshing partners, to pull down today's photo
    /// for whichever accepted partner has one — the widget itself
    /// never talks to Storage directly.
    static func downloadAndSave(from url: URL, forUid uid: String) async {
        guard let (data, _) = try? await URLSession.shared.data(from: url), let dir = directory else { return }
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? data.write(to: dir.appendingPathComponent(fileName(forUid: uid)), options: .atomic)
    }
}
