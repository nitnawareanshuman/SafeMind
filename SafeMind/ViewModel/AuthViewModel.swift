import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published private(set) var user: AuthUser?
    @Published private(set) var profile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var isEmailVerified = false
    private let authManager: AuthManaging?

    init(authManager: AuthManaging? = nil, startupError: String? = nil) {
        self.authManager = authManager
        self.errorMessage = startupError
        if authManager != nil { Task { await restoreSession() } }
    }

    func signUp(email: String, password: String, name: String) async -> Bool {
        await perform { manager in
            let user = try await manager.signUp(email: email, password: password, name: name)
            self.user = user; self.isEmailVerified = user.isEmailVerified
        }
    }

    func signIn(email: String, password: String) async -> Bool {
        await perform { manager in
            self.profile = try await manager.signIn(email: email, password: password)
            self.user = try await manager.currentUser()
            self.isEmailVerified = true
        }
    }

    func sendPasswordReset(email: String) async throws {
        guard let authManager else { throw AuthManagerError.missingSession }
        try await authManager.sendPasswordReset(to: email)
    }

    func resetPassword(email: String, oldPassword: String, newPassword: String) async throws {
        guard let authManager else { throw AuthManagerError.missingSession }
        try await authManager.resetPassword(email: email, oldPassword: oldPassword, newPassword: newPassword)
    }

    func resendVerification(email: String) async throws {
        guard let authManager else { throw AuthManagerError.missingSession }
        try await authManager.resendVerificationEmail(to: email)
    }

    func reloadVerificationStatus() async {
        guard let authManager else { return }
        do { user = try await authManager.currentUser(); isEmailVerified = user?.isEmailVerified ?? false }
        catch { errorMessage = error.localizedDescription }
    }

    func signOut() { Task {
        guard let authManager else { return }
        do { try await authManager.signOut(); user = nil; profile = nil; isEmailVerified = false }
        catch { errorMessage = error.localizedDescription }
    }}

    private func restoreSession() async {
        guard let authManager else { return }
        do { user = try await authManager.restoreSession(); isEmailVerified = user?.isEmailVerified ?? false }
        catch { user = nil; isEmailVerified = false }
    }

    private func perform(_ action: (AuthManaging) async throws -> Void) async -> Bool {
        guard let authManager else { errorMessage = "Supabase is not configured."; return false }
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do { try await action(authManager); return true } catch { errorMessage = error.localizedDescription; return false }
    }
}
