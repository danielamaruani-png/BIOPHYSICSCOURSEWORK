import AuthenticationServices
import CryptoKit
import FirebaseAuth
import GoogleSignIn
import UIKit

enum AuthError: Error {
    case missingPresentingViewController
    case invalidAppleCredential
    case missingIdToken
}

/// Wraps Sign in with Apple and Google Sign-In behind a single
/// Firebase-backed interface. Both flows end the same way: exchange
/// a provider credential for a Firebase user, then hand off to
/// FirestoreService to create the profile on first login.
final class AuthService: NSObject {
    static let shared = AuthService()

    private var currentAppleNonce: String?
    private var appleContinuation: CheckedContinuation<AuthCredential, Error>?

    var currentUserId: String? { Auth.auth().currentUser?.uid }

    // MARK: - Apple

    @MainActor
    func signInWithApple() async throws -> AuthDataResult {
        let nonce = Self.randomNonceString()
        currentAppleNonce = nonce

        let credential: AuthCredential = try await withCheckedThrowingContinuation { continuation in
            self.appleContinuation = continuation
            let provider = ASAuthorizationAppleIDProvider()
            let request = provider.createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = Self.sha256(nonce)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
        return try await Auth.auth().signIn(with: credential)
    }

    // MARK: - Google

    @MainActor
    func signInWithGoogle() async throws -> AuthDataResult {
        guard let presenting = Self.topViewController() else {
            throw AuthError.missingPresentingViewController
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presenting)
        guard let idToken = result.user.idToken?.tokenString else {
            throw AuthError.missingIdToken
        }
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: result.user.accessToken.tokenString
        )
        return try await Auth.auth().signIn(with: credential)
    }

    func signOut() throws {
        try Auth.auth().signOut()
        GIDSignIn.sharedInstance.signOut()
    }

    // MARK: - Helpers

    private static func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: \.isKeyWindow)?.rootViewController
        else { return nil }
        var top = root
        while let presented = top.presentedViewController { top = presented }
        return top
    }

    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        _ = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    private static func sha256(_ input: String) -> String {
        let hashed = SHA256.hash(data: Data(input.utf8))
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}

extension AuthService: ASAuthorizationControllerDelegate {
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let nonce = currentAppleNonce,
              let tokenData = appleIDCredential.identityToken,
              let idTokenString = String(data: tokenData, encoding: .utf8)
        else {
            appleContinuation?.resume(throwing: AuthError.invalidAppleCredential)
            appleContinuation = nil
            return
        }

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: appleIDCredential.fullName
        )
        appleContinuation?.resume(returning: credential)
        appleContinuation = nil
    }

    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        appleContinuation?.resume(throwing: error)
        appleContinuation = nil
    }
}

extension AuthService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        Self.topViewController()?.view.window ?? ASPresentationAnchor()
    }
}
