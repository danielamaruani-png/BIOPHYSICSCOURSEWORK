import FirebaseAuth
import FirebaseMessaging
import UIKit
import UserNotifications

/// Requests notification permission and keeps the current user's FCM
/// token saved to Firestore, so the notifyPartnersOnProof Cloud
/// Function (functions/index.js) has somewhere to send "X completed
/// today's proof!" pushes. Everything here is best-effort — a user who
/// declines the permission prompt just never gets nudged, nothing else
/// in the app depends on it.
final class PushNotificationService: NSObject {
    static let shared = PushNotificationService()

    func requestAuthorizationAndRegister() {
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            guard granted else { return }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }

    private func saveTokenIfSignedIn(_ token: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Task { try? await FirestoreService.shared.updatePushToken(uid: uid, token: token) }
    }
}

extension PushNotificationService: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken else { return }
        saveTokenIfSignedIn(fcmToken)
    }
}

extension PushNotificationService: UNUserNotificationCenterDelegate {
    /// Shows the banner even while the app is in the foreground —
    /// otherwise a "Marco completed today's proof!" push would only
    /// ever surface while Proof is backgrounded, which defeats the
    /// point of the nudge.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .list])
    }
}
