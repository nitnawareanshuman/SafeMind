//
//  AppleSignInCoordinator.swift
//  Irene
//
//  Bridges AuthenticationServices' delegate-based Sign in with Apple API into a single
//  async call that hands back the identity token + raw nonce Supabase needs for
//  `signInWithIdToken`.
//

import AuthenticationServices
import CryptoKit
import UIKit

enum AppleSignInError: LocalizedError {
    case missingIdentityToken
    case cancelled
    case other(String)

    var errorDescription: String? {
        switch self {
        case .missingIdentityToken: return "Apple didn't return an identity token. Please try again."
        case .cancelled: return "Sign in with Apple was cancelled."
        case let .other(message): return message
        }
    }
}

/// One-shot coordinator: create, call `start()`, then discard.
@MainActor
final class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {

    struct Result {
        let idToken: String
        let rawNonce: String
    }

    private var continuation: CheckedContinuation<Result, Error>?
    private var rawNonce = ""

    func start() async throws -> Result {
        let nonce = Self.randomNonceString()
        rawNonce = nonce

        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = Self.sha256(nonce)

        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            controller.performRequests()
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
              let tokenData = credential.identityToken,
              let idToken = String(data: tokenData, encoding: .utf8) else {
            continuation?.resume(throwing: AppleSignInError.missingIdentityToken)
            continuation = nil
            return
        }
        continuation?.resume(returning: Result(idToken: idToken, rawNonce: rawNonce))
        continuation = nil
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        if let authError = error as? ASAuthorizationError, authError.code == .canceled {
            continuation?.resume(throwing: AppleSignInError.cancelled)
        } else {
            continuation?.resume(throwing: AppleSignInError.other(error.localizedDescription))
        }
        continuation = nil
    }

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }

    // MARK: - Nonce helpers (Apple-recommended pattern for replay protection)

    private static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            precondition(status == errSecSuccess)

            for random in randoms where remainingLength > 0 {
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        let hashed = SHA256.hash(data: Data(input.utf8))
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
