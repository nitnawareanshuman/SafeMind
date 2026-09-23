import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published private(set) var user: AuthUser?
    @Published private(set) var profile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    /// Non-error, informational text for the auth screens (e.g. "Email verified — please log
    /// in."). Shown inline, never as a dialog/alert.
    @Published var infoMessage: String?
    @Published private(set) var isEmailVerified = false
    /// True while the recovery session from a "reset password" email link is active —
    /// the UI should show the "enter new password" screen regardless of other state.
    @Published private(set) var isPasswordRecovery = false
    /// True until the first auth event (restored session or none) has been received,
    /// so the splash screen can wait instead of flashing the Login screen briefly.
    @Published private(set) var isInitializing = true
    @Published private(set) var profileCheckFailed = false

    @Published private(set) var pendingVerificationEmail: String?
    @Published private(set) var isProcessingAuthLink = false
    @Published var authLinkError: String?
    private var requiresExplicitLogin = false
    private let recoveryKey = "irene.auth.recoveryPending"
    private let verificationKey = "irene.auth.pendingEmail"
    private var stateRevision = 0
    private var resendDates: [String: Date] = [:]

    private let authManager: AuthManaging?
    private var authEventsTask: Task<Void, Never>?

    init(authManager: AuthManaging? = nil, startupError: String? = nil) {
        self.authManager = authManager
        self.errorMessage = startupError
        self.isPasswordRecovery = UserDefaults.standard.bool(forKey: recoveryKey)
        self.pendingVerificationEmail = UserDefaults.standard.string(forKey: verificationKey)
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
        requiresExplicitLogin = false
        return await perform { manager in
            let user = try await manager.signUp(email: email, password: password, name: name)
            self.user = user; self.isEmailVerified = user.isEmailVerified
            if !user.isEmailVerified {
                self.pendingVerificationEmail = user.email
                UserDefaults.standard.set(user.email, forKey: self.verificationKey)
                self.resendDates["verify:" + user.email] = Date().addingTimeInterval(60)
            }
        }
    }

    func signIn(email: String, password: String) async -> Bool {
        requiresExplicitLogin = false
        return await perform { manager in
            self.profile = try await manager.signIn(email: email, password: password)
            self.user = try await manager.currentUser()
            self.clearPendingVerification()
            self.isEmailVerified = true
        }
    }

    func signInWithApple(idToken: String, rawNonce: String) async -> Bool {
        requiresExplicitLogin = false
        return await perform { manager in
            self.profile = try await manager.signInWithApple(idToken: idToken, rawNonce: rawNonce)
            self.user = try await manager.currentUser()
            self.clearPendingVerification()
            self.isEmailVerified = true
        }
    }

    func signInWithGoogle() async -> Bool {
        requiresExplicitLogin = false
        return await perform { manager in
            self.profile = try await manager.signInWithGoogle()
            self.user = try await manager.currentUser()
            self.clearPendingVerification()
            self.isEmailVerified = true
        }
    }

    /// Only a successful Supabase exchange can authorize recovery or confirmation.
    func handleAuthURL(_ url: URL) async {
        guard url.scheme?.lowercased() == "irene", !isProcessingAuthLink else { return }
        let host = url.host?.lowercased()
        guard host == "login-callback" || host == "reset-password-callback" || host == "rest-password-callback" else { return }
        guard let authManager else { return }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let fragmentItems = components?.fragment.flatMap { URLComponents(string: "?" + $0)?.queryItems } ?? []
        let linkType = ((components?.queryItems ?? []) + fragmentItems).first { $0.name == "type" }?.value
        let isRecoveryLink = host == "reset-password-callback" || host == "rest-password-callback" || linkType == "recovery"
        isProcessingAuthLink = true
        authLinkError = nil
        errorMessage = nil
        infoMessage = nil
        stateRevision += 1
        defer { isProcessingAuthLink = false; isInitializing = false }
        do {
            let linkedUser = try await authManager.sessionFromLink(url)
            user = linkedUser
            isEmailVerified = false
            profile = nil
            if isRecoveryLink {
                requiresExplicitLogin = false
                isPasswordRecovery = true
                UserDefaults.standard.set(true, forKey: recoveryKey)
            } else {
                guard linkedUser.isEmailVerified else { throw AuthManagerError.emailNotVerified }
                requiresExplicitLogin = true
                try await authManager.endLinkSession()
                clearSessionState()
                clearPendingVerification()
                infoMessage = "Email verified! Please log in to continue."
            }
        } catch {
            // A link exchange may have created a session before a later step failed.
            // Keep that session from being treated as an ordinary login.
            requiresExplicitLogin = true
            try? await authManager.endLinkSession()
            clearSessionState()
            authLinkError = "Could not finish this email link. It may be expired, already used, or opened on a different device. Request a new email and open it on this device."
        }
    }

    func resendSeconds(email: String, recovery: Bool = false) -> Int {
        let key = (recovery ? "reset:" : "verify:") + email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return max(0, Int(ceil((resendDates[key] ?? .distantPast).timeIntervalSinceNow)))
    }

    private func sendEmail(email: String, recovery: Bool) async throws {
        guard let authManager else { throw AuthManagerError.missingSession }
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let key = (recovery ? "reset:" : "verify:") + email
        guard resendSeconds(email: email, recovery: recovery) == 0 else {
            throw AuthManagerError.requestFailed("Please wait before requesting another email.")
        }
        resendDates[key] = Date().addingTimeInterval(60)
        do {
            if recovery { try await authManager.sendPasswordReset(to: email) }
            else { try await authManager.resendVerificationEmail(to: email) }
        } catch {
            resendDates.removeValue(forKey: key)
            throw error
        }
    }

    func sendPasswordReset(email: String) async throws {
        try await sendEmail(email: email, recovery: true)
    }

    func resetPassword(email: String, oldPassword: String, newPassword: String) async throws {
        guard let authManager else { throw AuthManagerError.missingSession }
        try await authManager.resetPassword(email: email, oldPassword: oldPassword, newPassword: newPassword)
    }

    /// Completes the "forgot password" flow after the user tapped the reset link and is
    /// now in a recovery session.
    func updatePasswordAfterRecovery(newPassword: String) async throws {
        guard let authManager else { throw AuthManagerError.missingSession }
        guard isPasswordRecovery, user != nil else { throw AuthManagerError.missingSession }
        try await authManager.updatePasswordAfterRecovery(newPassword: newPassword)
    }

    func resendVerification(email: String) async throws {
        try await sendEmail(email: email, recovery: false)
    }

    /// Confirms the `profiles` row exists for the signed-in user (creating it if the
    /// server-side trigger hasn't run yet), then makes Home available.
    func ensureProfile() async {
        guard let authManager, let user, isEmailVerified, profile == nil else { return }
        let revision = stateRevision
        do {
            let fetched = try await authManager.fetchOrCreateProfile(for: user)
            guard revision == stateRevision, !isPasswordRecovery, !isProcessingAuthLink, !requiresExplicitLogin else { return }
            profile = fetched
            profileCheckFailed = false
        } catch {
            guard revision == stateRevision, !isPasswordRecovery, !isProcessingAuthLink, !requiresExplicitLogin else { return }
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

    private func clearPendingVerification() {
        pendingVerificationEmail = nil
        UserDefaults.standard.removeObject(forKey: verificationKey)
    }

    private func clearSessionState() {
        stateRevision += 1
        user = nil
        profile = nil
        isEmailVerified = false
        isPasswordRecovery = false
        profileCheckFailed = false
        UserDefaults.standard.removeObject(forKey: recoveryKey)
    }

    func finishRecovery() async throws {
        guard let authManager else { throw AuthManagerError.missingSession }
        requiresExplicitLogin = true
        try await authManager.endLinkSession()
        clearSessionState()
        clearPendingVerification()
        infoMessage = "Password updated! Please log in."
    }

    func signOut() {
        Task {
            guard let authManager else { return }
            requiresExplicitLogin = true
            do {
                try await authManager.endLinkSession()
                clearSessionState()
                clearPendingVerification()
            } catch { authLinkError = error.localizedDescription }
        }
    }

    private func handle(_ event: AuthLifecycleEvent) async {
        guard !isProcessingAuthLink else { return }
        isInitializing = false
        if requiresExplicitLogin { return }
        switch event {
        case .signedIn(let authUser):
            if isPasswordRecovery {
                user = authUser
                return
            }
            user = authUser
            isEmailVerified = authUser.isEmailVerified
            if isEmailVerified {
                clearPendingVerification()
                await ensureProfile()
            } else {
                profile = nil
                profileCheckFailed = false
            }
        case .passwordRecovery(let authUser):
            user = authUser
            isPasswordRecovery = true
            UserDefaults.standard.set(true, forKey: recoveryKey)
        case .emailConfirmed:
            user = nil
            profile = nil
            isEmailVerified = false
            isPasswordRecovery = false
            profileCheckFailed = false
            infoMessage = "Email verified! Please log in to continue."
        case .signedOut:
            clearSessionState()
        }
    }

    private func perform(_ action: (AuthManaging) async throws -> Void) async -> Bool {
        guard let authManager else { errorMessage = "Supabase is not configured."; return false }
        guard !isLoading else { return false }
        isLoading = true; errorMessage = nil; infoMessage = nil; defer { isLoading = false }
        do { try await action(authManager); return true } catch { errorMessage = error.localizedDescription; return false }
    }
}
