//
//  IreneApp.swift
//  Irene
//
//  Created by Anshuman Nitnaware on 04/03/26.
//

import SwiftUI
import Supabase
 
@main
struct IreneApp: App {
    @StateObject private var authViewModel: AuthViewModel
 
    init() {
        let users = UserManager(client: supabase)
        _authViewModel = StateObject(wrappedValue: AuthViewModel(authManager: AuthManager(client: supabase, userManager: users)))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .onOpenURL { url in
                    Task {
                        // Tell the auth manager how to interpret the event this URL is about
                        // to produce *before* exchanging it — see PendingAuthLink.
                        authViewModel.prepareForAuthLink(pendingAuthLink(for: url))
                        try? await supabase.auth.session(from: url)
                    }
                }
        }
    }

    /// Decides whether an incoming `Irene://` URL is a signup-confirmation link or a
    /// password-reset link.
    ///
    /// This is host-based, NOT based on the `type` query parameter. Supabase's PKCE flow
    /// (the default on Swift) only appends `?code=...` to the redirect URL — it does not
    /// forward `type` the way the implicit flow's fragment does. Since `signUp` and
    /// `resetPasswordForEmail` used to share the same `redirectTo` host, every link looked
    /// identical and always fell through to a plain sign-in (straight to Home). Password
    /// reset now uses its own dedicated host (`reset-password-callback`, set in
    /// `AuthManager.sendPasswordReset`) so the two can be told apart from the URL alone,
    /// regardless of flow type. `type` is kept as a fallback in case Supabase ever does
    /// include it (e.g. implicit flow).
    private func pendingAuthLink(for url: URL) -> PendingAuthLink? {
        switch url.host {
        case "reset-password-callback":
            return .passwordRecovery
        case "login-callback":
            if let type = emailLinkType(from: url) {
                return type == "recovery" ? .passwordRecovery : .signupConfirmation
            }
            // No `type` present (the normal PKCE case) — a `login-callback` link opened
            // from outside the app (Mail, Messages, etc.) is the signup-confirmation link.
            // Google/Apple sign-in never reach here: those complete inside the in-app
            // ASWebAuthenticationSession sheet, not via onOpenURL.
            return .signupConfirmation
        default:
            return nil
        }
    }

    /// Reads the `type` parameter Supabase appends in some flows (e.g. implicit flow's
    /// fragment). Checked as a fallback only — see `pendingAuthLink(for:)`.
    private func emailLinkType(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        if let value = components.queryItems?.first(where: { $0.name == "type" })?.value {
            return value
        }
        if let fragment = components.fragment,
           let fragmentComponents = URLComponents(string: "?\(fragment)") {
            return fragmentComponents.queryItems?.first(where: { $0.name == "type" })?.value
        }
        return nil
    }
}
