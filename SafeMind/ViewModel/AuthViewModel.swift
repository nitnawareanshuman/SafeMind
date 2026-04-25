//
//  AuthViewModel.swift
//  SafeMind
//

import Foundation
import FirebaseAuth
import Combine
import AuthenticationServices
import CryptoKit
import Security

@MainActor
final class AuthViewModel: ObservableObject {

    @Published var user: AuthDataResultModel? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isEmailVerified: Bool = false
    private var currentNonce: String?

    init() {
        checkAuth()
    }

    func signIn(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let user = try await AuthenticationManager.shared.signInUser(email: email, password: password)

            guard let firebaseUser = Auth.auth().currentUser else {
                errorMessage = "User not found"
                return false
            }

            try await firebaseUser.reload()

            if !firebaseUser.isEmailVerified {
                try AuthenticationManager.shared.signOut()
                errorMessage = "Please verify your email first"
                return false
            }

            self.user = user
            self.isEmailVerified = true
            return true

        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }

    func signUp(email: String, password: String, name: String) async -> Bool {
        do {
            // ✅ Pass name through so we can save it to Firestore
            let authUser = try await AuthenticationManager.shared.createUser(email: email, password: password)

            // Save profile to Firestore right after creation
            let profile = UserProfile(
                uid: authUser.uid,   // ← this becomes the @DocumentID
                name: name,
                email: email,
                photoURL: "",
                joinedDate: Date(),
                avgSession: 0,
                totalTime: 0,
                sessionsCompleted: 0
            )
            
            do {
                try await ProfileManager.shared.createUser(profile: profile)
                print("✅ Firestore user saved")
            } catch {
                print("❌ Firestore error:", error.localizedDescription)
                throw error
            }

            try await AuthenticationManager.shared.sendEmailVerification()
            self.user = authUser
            self.isEmailVerified = false
            return true
        } catch {
            self.errorMessage = error.localizedDescription
            return false
        }
    }

    func signOut() {
        do {
            try AuthenticationManager.shared.signOut()
            self.user = nil
            self.isEmailVerified = false
        } catch {
            print("Sign out error:", error)
        }
    }

    func signInWithGoogle() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let result = try await AuthenticationManager.shared.signInWithGoogle()
                self.user = result
                self.isEmailVerified = true
                print("✅ Google Sign-In: \(result.uid)")
            } catch {
                self.errorMessage = error.localizedDescription
                print("❌ Google Sign-In Error: \(error.localizedDescription)")
            }
            self.isLoading = false
        }
    }

    func checkAuth() {
        if let user = try? AuthenticationManager.shared.getAuthenticatedUser() {
            self.user = user
            Task { await reloadVerificationStatus() }
        } else {
            self.user = nil
            self.isEmailVerified = false
        }
    }

    func reloadVerificationStatus() async {
        do {
            try await Auth.auth().currentUser?.reload()
            self.isEmailVerified = Auth.auth().currentUser?.isEmailVerified ?? false
        } catch {
            self.isEmailVerified = false
        }
    }
    
    func signInWithApple(
        idTokenString: String,
        nonce: String
    ) {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                let result = try await AuthenticationManager.shared
                    .signInWithApple(
                        idTokenString: idTokenString,
                        nonce: nonce
                    )

                self.user = result
                self.isEmailVerified = true

                print("✅ Apple Sign-In success: \(result.uid)")
            } catch {
                self.errorMessage = error.localizedDescription
                print("❌ Apple Sign-In Error: \(error.localizedDescription)")
            }

            self.isLoading = false
        }
    }
    
    func signInWithAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]

        let nonce = randomNonceString()
        currentNonce = nonce
        request.nonce = sha256(nonce)
    }
    
    func handleSignInWithAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        
        switch result {
            
        case .failure(let error):
            print(error.localizedDescription)
            
        case .success(let authResults):
            
            // ✅ First get Apple credential
            guard let appleIDCredential = authResults.credential as? ASAuthorizationAppleIDCredential else {
                print("Unable to fetch Apple credential")
                return
            }
            
            // ✅ Get saved nonce
            guard let nonce = currentNonce else {
                fatalError("Invalid state: Login callback received but no login request sent.")
            }
            
            // ✅ Get identity token
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unable to fetch identity token")
                return
            }
            
            // ✅ Convert token to String
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to serialize token string")
                return
            }
            
            // ✅ Create Firebase credential
            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: nonce,
                fullName: appleIDCredential.fullName
            )
            
            // ✅ Sign in to Firebase
            Task {
                do {
                    let authResult = try await Auth.auth().signIn(with: credential)
                    print("✅ Apple Sign-In Success: \(authResult.user.uid)")
                    
                } catch {
                    print("❌ Firebase Auth Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)

        let charset: [Character] = Array(
            "0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._"
        )

        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(
                    kSecRandomDefault,
                    1,
                    &random
                )

                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce.")
                }

                return random
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)

        return hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
    }
}
