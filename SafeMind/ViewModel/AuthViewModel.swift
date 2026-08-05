import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published private(set) var user: AuthUser?
    @Published private(set) var profile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published private(set) var isEmailVerified = false
    /// True while the recovery session from a "reset password" email link is active —
    /// the UI should show the "enter new password" screen regardless of other state.
    @Published private(set) var isPasswordRecovery = false
    /// True until the first auth event (restored session or none) has been received,
    /// so the splash screen can wait instead of flashing the Login screen briefly.
    @Published private(set) var isInitializing = true
    @Published private(set) var profileCheckFailed = false

    private let authManager: AuthManaging?
    private var authEventsTask: Task<Void, Never>?

    init(authManager: AuthManaging? = nil, startupError: String? = nil) {
        self.authManager = authManager
        self.errorMessage = startupError
        guard let authManager else {
            isInitializing = false
            return
        }
        authEventsTask = Task { [weak self] in
            for await event in authManager.authEvents() {
                await self?.handle(event)
            }
        }
    }

    deinit {
        authEventsTask?.cancel()
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

    /// Completes the "forgot password" flow after the user tapped the reset link and is
    /// now in a recovery session.
    func updatePasswordAfterRecovery(newPassword: String) async throws {
        guard let authManager else { throw AuthManagerError.missingSession }
        try await authManager.updatePasswordAfterRecovery(newPassword: newPassword)
    }

    func resendVerification(email: String) async throws {
        guard let authManager else { throw AuthManagerError.missingSession }
        try await authManager.resendVerificationEmail(to: email)
    }

    /// Manual fallback in case the user verified on another device and the reactive
    /// event stream didn't pick it up.
    func reloadVerificationStatus() async {
        guard let authManager else { return }
        do {
            user = try await authManager.currentUser()
            isEmailVerified = user?.isEmailVerified ?? false
            if isEmailVerified { await ensureProfile() }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Confirms the `profiles` row exists for the signed-in user (creating it if the
    /// server-side trigger hasn't run yet), then makes Home available.
    func ensureProfile() async {
        guard let authManager, let user, isEmailVerified, profile == nil else { return }
        do {
            profile = try await authManager.fetchOrCreateProfile(for: user)
            profileCheckFailed = false
        } catch {
            profileCheckFailed = true
            errorMessage = error.localizedDescription
        }
    }

    /// Updates the in-memory profile (e.g. after a local-only change like a
    /// profile photo saved via `LocalImageStore`) without a full round-trip
    /// through `ensureProfile()`. Keeps Home/Profile avatars in sync instantly.
    func updateLocalProfile(_ updated: UserProfile) {
        profile = updated
    }

    func signOut() { Task {
        guard let authManager else { return }
        do { try await authManager.signOut(); user = nil; profile = nil; isEmailVerified = false; isPasswordRecovery = false }
        catch { errorMessage = error.localizedDescription }
    }}

    private func handle(_ event: AuthLifecycleEvent) async {
        isInitializing = false
        switch event {
        case .signedIn(let authUser):
            isPasswordRecovery = false
            user = authUser
            isEmailVerified = authUser.isEmailVerified
            if isEmailVerified {
                await ensureProfile()
            } else {
                profile = nil
                profileCheckFailed = false
            }
        case .passwordRecovery(let authUser):
            user = authUser
            isPasswordRecovery = true
        case .signedOut:
            user = nil
            profile = nil
            isEmailVerified = false
            isPasswordRecovery = false
            profileCheckFailed = false
        }
    }

    private func perform(_ action: (AuthManaging) async throws -> Void) async -> Bool {
        guard let authManager else { errorMessage = "Supabase is not configured."; return false }
        isLoading = true; errorMessage = nil; defer { isLoading = false }
        do { try await action(authManager); return true } catch { errorMessage = error.localizedDescription; return false }
    }
}
