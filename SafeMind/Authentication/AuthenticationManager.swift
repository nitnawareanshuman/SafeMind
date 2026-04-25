//
//  AuthenticationManager.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 01/04/26.
//

import Foundation
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import AuthenticationServices
import CryptoKit

struct AuthDataResultModel {
    let uid: String
    let email: String?
    let photoUrl: String?

    init(user: User) {
        self.uid = user.uid
        self.email = user.email
        self.photoUrl = user.photoURL?.absoluteString
    }
}

final class AuthenticationManager {
    static let shared = AuthenticationManager()
    private init() {}

    func getAuthenticatedUser() throws -> AuthDataResultModel {
        guard let user = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }
        return AuthDataResultModel(user: user)
    }

    func createUser(email: String, password: String) async throws -> AuthDataResultModel {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return AuthDataResultModel(user: result.user)
    }

    func signInUser(email: String, password: String) async throws -> AuthDataResultModel {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return AuthDataResultModel(user: result.user)
    }

    func resetPassword(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    func sendEmailVerification() async throws {
        guard let user = Auth.auth().currentUser else {
            throw NSError(
                domain: "AuthError",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "No authenticated user"]
            )
        }

        if user.isEmailVerified {
            throw NSError(
                domain: "AuthError",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Email already verified"]
            )
        }

        try await user.sendEmailVerification()
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }

    func signInWithGoogle() async throws -> AuthDataResultModel {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw URLError(.badURL)
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = scene.keyWindow?.rootViewController else {
            throw URLError(.badURL)
        }

        let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)

        guard let idToken = result.user.idToken?.tokenString else {
            throw URLError(.badServerResponse)
        }

        let accessToken = result.user.accessToken.tokenString

        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: accessToken
        )

        let authResult = try await Auth.auth().signIn(with: credential)
        return AuthDataResultModel(user: authResult.user)
    }

    func signInWithApple(
        idTokenString: String,
        nonce: String
    ) async throws -> AuthDataResultModel {

        let credential = OAuthProvider.appleCredential(
            withIDToken: idTokenString,
            rawNonce: nonce,
            fullName: nil
        )

        let authResult = try await Auth.auth().signIn(with: credential)

        return AuthDataResultModel(user: authResult.user)
    }
}

extension UIWindowScene {
    var keyWindow: UIWindow? {
        windows.first(where: { $0.isKeyWindow })
    }
}
