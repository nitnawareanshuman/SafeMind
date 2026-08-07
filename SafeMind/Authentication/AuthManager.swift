import Foundation
import Supabase

/// Presentation-friendly representation of the authenticated Supabase user.
struct AuthUser: Equatable, Sendable {
    let id: UUID
    let email: String
    let isEmailVerified: Bool
    var uid: String { id.uuidString }
}

/// App-specific authentication errors, decoupled from Supabase SDK errors.
enum AuthManagerError: LocalizedError, Equatable {
    case invalidEmail, invalidPassword, missingSession, emailNotVerified, missingEmail, invalidCredentials
    case incorrectOldPassword
    case requestFailed(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail: return "Enter a valid email address."
        case .invalidPassword: return "Password must be 8+ characters and include 1 uppercase letter, 1 number, and 1 special character."
        case .missingSession: return "Your session has expired. Please sign in again."
        case .emailNotVerified: return "Please verify your email before signing in."
        case .missingEmail: return "This account does not have an email address."
        case .invalidCredentials: return "The email address or password is incorrect."
        case .incorrectOldPassword: return "Your old password is incorrect."
        case let .requestFailed(message): return message
        }
    }
}

/// High-level auth lifecycle events, decoupled from the Supabase SDK's `AuthChangeEvent`.
/// Drives the app's top-level navigation reactively (e.g. tapping an email-verification
/// or password-reset link while the app is backgrounded).
enum AuthLifecycleEvent: Sendable {
    case signedIn(AuthUser)
    case passwordRecovery(AuthUser)
    /// The user tapped the "confirm your email" link. The recovery/confirmation session has
    /// already been signed out server-side by the manager — the UI should land on Login, not Home.
    case emailConfirmed
    case signedOut
}

/// Distinguishes which kind of email link the app is about to process, decided from the
/// `type` query/fragment parameter Supabase appends to the redirect URL. Set right before
/// exchanging the URL for a session, so the resulting auth event can be routed correctly
/// regardless of whether the underlying SDK flow is PKCE or implicit.
enum PendingAuthLink: Equatable, Sendable {
    case signupConfirmation
    case passwordRecovery
}

protocol AuthManaging: Sendable {
    func signUp(email: String, password: String, name: String) async throws -> AuthUser
    func signIn(email: String, password: String) async throws -> UserProfile
    func signInWithApple(idToken: String, rawNonce: String) async throws -> UserProfile
    func signInWithGoogle() async throws -> UserProfile
    func signOut() async throws
    func sendPasswordReset(to email: String) async throws
    func resetPassword(email: String, oldPassword: String, newPassword: String) async throws
    func updatePasswordAfterRecovery(newPassword: String) async throws
    func resendVerificationEmail(to email: String) async throws
    func currentUser() async throws -> AuthUser?
    func restoreSession() async throws -> AuthUser?
    func fetchOrCreateProfile(for user: AuthUser) async throws -> UserProfile
    /// Call right before handing an incoming `safemind://` URL to Supabase, so the manager
    /// knows how to interpret the auth event that results from it.
    func prepareForAuthLink(_ link: PendingAuthLink?)
    /// Emits every auth lifecycle change (initial session restore, sign-in, sign-out,
    /// password-recovery link opened) so the UI can react without manual polling.
    func authEvents() -> AsyncStream<AuthLifecycleEvent>
}

/// Supabase email/password authentication coordinator.
/// The SDK persists sessions in Keychain; `restoreSession()` validates the stored session at launch.
final class AuthManager: AuthManaging, @unchecked Sendable {
    private let client: SupabaseClient
    private let userManager: UserManaging

    /// Set by `prepareForAuthLink(_:)` right before the app exchanges an incoming email-link
    /// URL for a session. Consumed by the very next relevant event on `authEvents()` so that
    /// event can be reinterpreted correctly (e.g. a plain `.signedIn` becomes `.emailConfirmed`).
    private var pendingAuthLink: PendingAuthLink?

    init(client: SupabaseClient, userManager: UserManaging) {
        self.client = client
        self.userManager = userManager
    }

    func prepareForAuthLink(_ link: PendingAuthLink?) {
        pendingAuthLink = link
    }

    /// Creates an auth user, triggers Supabase email confirmation, then inserts `profiles`.
    func signUp(email: String, password: String, name: String) async throws -> AuthUser {
        let email = try validatedEmail(email)
        try validate(password: password)
        do {
            let response = try await client.auth.signUp(
                email: email,
                password: password,
                data: ["name": .string(name.trimmingCharacters(in: .whitespacesAndNewlines))],
                redirectTo: URL(string: "safemind://login-callback")
            )
            let user = authUser(from: response)
            // Profile row is created server-side by the `on_auth_user_created` DB trigger,
            // so we don't insert it here — avoids the RLS race before email verification.
            return try makeAuthUser(user)
        } catch let error as AuthManagerError {
            throw error
        } catch {
            throw map(error)
        }
    }

    /// Authenticates a verified user and returns their application profile.
    func signIn(email: String, password: String) async throws -> UserProfile {
        let email = try validatedEmail(email)
        guard !password.isEmpty else { throw AuthManagerError.invalidPassword }
        do {
            _ = try await client.auth.signIn(email: email, password: password)
            let user = try await client.auth.user()
            guard user.emailConfirmedAt != nil else {
                try? await client.auth.signOut()
                throw AuthManagerError.emailNotVerified
            }
            return try await userManager.fetchProfile(userID: user.id)
        } catch let error as AuthManagerError {
            throw error
        } catch {
            throw map(error)
        }
    }

    /// Signs in (or up, on first use) via a Sign in with Apple identity token obtained natively
    /// through `ASAuthorizationController`. Apple-verified accounts arrive already email-confirmed.
    func signInWithApple(idToken: String, rawNonce: String) async throws -> UserProfile {
        do {
            try await client.auth.signInWithIdToken(
                credentials: OpenIDConnectCredentials(provider: .apple, idToken: idToken, nonce: rawNonce)
            )
            guard let sessionUser = client.auth.currentUser else { throw AuthManagerError.missingSession }
            let authUser = try makeAuthUser(sessionUser)
            return try await fetchOrCreateProfile(for: authUser)
        } catch let error as AuthManagerError {
            throw error
        } catch {
            throw map(error)
        }
    }

    /// Signs in (or up, on first use) via Google using Supabase's hosted OAuth flow, presented
    /// in a system `ASWebAuthenticationSession` sheet. Google-verified accounts arrive already
    /// email-confirmed.
    func signInWithGoogle() async throws -> UserProfile {
        do {
            try await client.auth.signInWithOAuth(
                provider: .google,
                redirectTo: URL(string: "safemind://login-callback")
            )
            guard let sessionUser = client.auth.currentUser else { throw AuthManagerError.missingSession }
            let authUser = try makeAuthUser(sessionUser)
            return try await fetchOrCreateProfile(for: authUser)
        } catch let error as AuthManagerError {
            throw error
        } catch {
            throw map(error)
        }
    }

    func signOut() async throws {
        do { try await client.auth.signOut() } catch { throw map(error) }
    }

    func sendPasswordReset(to email: String) async throws {
        do {
            try await client.auth.resetPasswordForEmail(
                try validatedEmail(email),
                // Deliberately a DIFFERENT host than the signup-confirmation /
                // OAuth redirect ("login-callback"). Supabase's PKCE flow (the
                // default on Swift) does not forward a `type` query parameter on
                // the final redirect — only `?code=...` — so `type` alone can't
                // distinguish a password-reset link from a signup-confirmation
                // link when they share a URL. Giving reset its own host lets
                // SafeMindApp tell them apart from the URL itself.
                redirectTo: URL(string: "safemind://reset-password-callback")
            )
        }
        catch let error as AuthManagerError { throw error }
        catch { throw map(error) }
    }

    /// Verifies the user's old password by signing in with it, then updates to the new password.
    func resetPassword(email: String, oldPassword: String, newPassword: String) async throws {
        let email = try validatedEmail(email)
        try validate(password: newPassword)

        // Step 1: confirm identity by signing in with the old password.
        do {
            _ = try await client.auth.signIn(email: email, password: oldPassword)
        } catch {
            throw AuthManagerError.incorrectOldPassword
        }

        // Step 2: old password confirmed — set the new one.
        do {
            try await client.auth.update(user: UserAttributes(password: newPassword))
        } catch let error as AuthManagerError {
            throw error
        } catch {
            throw map(error)
        }
    }

    /// Sets a new password on an already-authenticated recovery session (from a password-reset link).
    /// No old password is needed — the recovery link itself is the proof of identity.
    func updatePasswordAfterRecovery(newPassword: String) async throws {
        try validate(password: newPassword)
        do {
            try await client.auth.update(user: UserAttributes(password: newPassword))
        } catch let error as AuthManagerError {
            throw error
        } catch {
            throw map(error)
        }
    }

    func resendVerificationEmail(to email: String) async throws {
        do { try await client.auth.resend(email: try validatedEmail(email), type: .signup) }
        catch let error as AuthManagerError { throw error }
        catch { throw map(error) }
    }

    /// Looks up the app-owned `profiles` row for a user. Normally this row already exists
    /// (created by the `on_auth_user_created` DB trigger during sign up); if it's missing —
    /// e.g. the trigger hadn't finished yet — this creates it so the user isn't stuck.
    func fetchOrCreateProfile(for user: AuthUser) async throws -> UserProfile {
        do {
            return try await userManager.fetchProfile(userID: user.id)
        } catch {
            let fallbackName = user.email.components(separatedBy: "@").first ?? "Member"
            return try await userManager.createProfile(userID: user.id, name: fallbackName, email: user.email)
        }
    }

    func authEvents() -> AsyncStream<AuthLifecycleEvent> {
        AsyncStream { continuation in
            let task = Task {
                for await (event, session) in client.auth.authStateChanges {
                    switch event {
                    case .passwordRecovery:
                        // Not link-related bookkeeping needed here — the SDK's native
                        // `.passwordRecovery` event is already unambiguous. Still clear any
                        // stale pending link so it can't leak into a later, unrelated event.
                        self.pendingAuthLink = nil
                        if let sessionUser = session?.user, let authUser = try? self.makeAuthUser(sessionUser) {
                            continuation.yield(.passwordRecovery(authUser))
                        }
                    case .signedIn:
                        // Only `.signedIn` can actually result from exchanging an email link,
                        // so only `.signedIn` is allowed to consume `pendingAuthLink`. Events
                        // like `.initialSession` (fired independently at startup/cold-launch,
                        // often racing a link tap) or `.tokenRefreshed` must never consume it —
                        // otherwise the real link-triggered event can arrive afterwards with
                        // the flag already cleared and silently fall through to plain sign-in.
                        let pendingLink = self.pendingAuthLink
                        self.pendingAuthLink = nil

                        // A signup-confirmation link produces a normal `.signedIn` event under
                        // both PKCE and implicit flow — reinterpret it as `.emailConfirmed` and
                        // drop the session, so tapping the link never lands the user in Home.
                        if pendingLink == .signupConfirmation {
                            continuation.yield(.emailConfirmed)
                            Task { try? await self.client.auth.signOut() }
                            continue
                        }
                        // A password-reset link may only surface as `.signedIn` under PKCE
                        // (no native `.passwordRecovery` event in that flow) — force it through
                        // the recovery path so ResetPasswordView is shown either way.
                        if pendingLink == .passwordRecovery,
                           let sessionUser = session?.user, let authUser = try? self.makeAuthUser(sessionUser) {
                            continuation.yield(.passwordRecovery(authUser))
                            continue
                        }
                        if let sessionUser = session?.user, let authUser = try? self.makeAuthUser(sessionUser) {
                            continuation.yield(.signedIn(authUser))
                        } else {
                            continuation.yield(.signedOut)
                        }
                    case .initialSession, .tokenRefreshed, .userUpdated:
                        // Deliberately does NOT touch `pendingAuthLink` — these events aren't
                        // produced by exchanging an email link, so they must never consume a
                        // flag meant for the `.signedIn`/`.passwordRecovery` event that follows.
                        if let sessionUser = session?.user, let authUser = try? self.makeAuthUser(sessionUser) {
                            continuation.yield(.signedIn(authUser))
                        } else {
                            continuation.yield(.signedOut)
                        }
                    case .signedOut, .userDeleted:
                        continuation.yield(.signedOut)
                    default:
                        break
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    func currentUser() async throws -> AuthUser? {
        guard client.auth.currentSession != nil else { return nil }
        do {
            let user: User
            if let cached = client.auth.currentUser {
                user = cached
            } else {
                user = try await client.auth.user()
            }
            return try makeAuthUser(user)
        }
        catch { throw map(error) }
    }

    func restoreSession() async throws -> AuthUser? {
        guard client.auth.currentSession != nil else { return nil }
        do {
            _ = try await client.auth.session
            return try await currentUser()
        } catch { throw map(error) }
    }

    private func authUser(from response: AuthResponse) -> User {
        switch response {
        case let .session(session): return session.user
        case let .user(user): return user
        }
    }

    private func makeAuthUser(_ user: User) throws -> AuthUser {
        guard let email = user.email else { throw AuthManagerError.missingEmail }
        return AuthUser(id: user.id, email: email, isEmailVerified: user.emailConfirmedAt != nil)
    }

    private func validatedEmail(_ value: String) throws -> String {
        let email = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard email.contains("@"), email.contains(".") else { throw AuthManagerError.invalidEmail }
        return email
    }

    private func validate(password: String) throws {
        guard password.count >= 8,
              password.contains(where: { $0.isUppercase }),
              password.contains(where: { $0.isNumber }),
              password.contains(where: { "!@#$%^&*()_+-=[]{}|;:'\",.<>?/`~\\".contains($0) })
        else {
            throw AuthManagerError.invalidPassword
        }
    }

    private func map(_ error: Error) -> AuthManagerError {
        let message = error.localizedDescription
        if message.localizedCaseInsensitiveContains("invalid login credentials") { return .invalidCredentials }
        if message.localizedCaseInsensitiveContains("session") && message.localizedCaseInsensitiveContains("missing") { return .missingSession }
        return .requestFailed(message)
    }
}
