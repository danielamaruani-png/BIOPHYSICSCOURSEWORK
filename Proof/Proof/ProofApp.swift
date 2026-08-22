import SwiftUI
import FirebaseCore
import FirebaseMessaging
import GoogleSignIn

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Hands the APNs token to Firebase Messaging, which is what
        // actually derives the FCM token PushNotificationService saves.
        Messaging.messaging().apnsToken = deviceToken
    }
}

@main
struct ProofApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var session = SessionViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(session)
                .onOpenURL { url in
                    if url.scheme == "proof" {
                        // The widget's "post proof" button deep-links
                        // here (proof://capture?crewId=...) so tapping
                        // it drops the user straight into that crew's
                        // capture sheet instead of just opening the app.
                        handleDeepLink(url)
                    } else {
                        // Completes the Google Sign-In redirect back into
                        // the app; without this the auth flow hangs after
                        // the browser sheet dismisses.
                        GIDSignIn.sharedInstance.handle(url)
                    }
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        guard url.host == "capture",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let crewId = components.queryItems?.first(where: { $0.name == "crewId" })?.value
        else { return }
        session.pendingCaptureCrewId = crewId
    }
}
