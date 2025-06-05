import Foundation
import AuthenticationServices
import UIKit

/// Coordinates ASAuthorizationController for Sign in with Apple.
public final class AppleSignInCoordinator: NSObject {
    public override init() { super.init() }

    public struct Credential {
        public let userID: String
        public let idToken: String
    }

    /// Performs the Sign in with Apple flow and returns the user credential.
    @MainActor
    public func signIn() async throws -> Credential {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName]

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self

        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Credential, Error>) in
            self.continuation = continuation
            controller.performRequests()
        }
    }

    private var continuation: CheckedContinuation<Credential, Error>?
}

// MARK: - ASAuthorizationControllerDelegate
extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {
    public func authorizationController(controller: ASAuthorizationController,
                                        didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleID = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = appleID.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            continuation?.resume(throwing: NSError(domain: "AuthKit",
                                                   code: 0,
                                                   userInfo: [NSLocalizedDescriptionKey: "Invalid credential"]))
            return
        }
        let userID = appleID.user
        continuation?.resume(returning: Credential(userID: userID, idToken: idToken))
    }

    public func authorizationController(controller: ASAuthorizationController,
                                        didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding
extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }) else {
            return ASPresentationAnchor()
        }
        return window
    }
}
