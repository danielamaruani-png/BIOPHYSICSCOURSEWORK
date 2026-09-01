import Foundation
import UIKit

/// Read-only counterpart to Commited/Services/WidgetPhotoCache.swift — the
/// widget only ever loads photos the main app already cached into the
/// shared App Group container, never fetches or writes anything itself.
enum WidgetPhotoLoader {
    private static var directory: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: WidgetSnapshot.appGroupId)?
            .appendingPathComponent("widgetPhotos", isDirectory: true)
    }

    static func image(forUid uid: String) -> UIImage? {
        guard let dir = directory else { return nil }
        let url = dir.appendingPathComponent("\(uid).jpg")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }
}
