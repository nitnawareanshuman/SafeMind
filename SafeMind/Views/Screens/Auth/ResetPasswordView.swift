//
//  ResetPasswordView.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 30/07/26.
//


//
//  ResetPasswordView.swift
//  SafeMind
//
//  Shown when authVM.isPasswordRecovery is true — i.e. the user tapped the
//  "reset password" link from their email and the app opened into a recovery
//  session. Completes: Tap Reset Link → Open App → Enter New Password → Login.
//

import SwiftUI

struct ResetPasswordView: View {

    @EnvironmentObject var authVM: AuthViewModel

    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var errorMsg: String? = nil
    @State private var isLoading = false

    var body: some View {
        ZStack {
            LoginBackground()

            ScrollView {
                VStack(spacing: 25) {

                    Text("NEW PASSWORD")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    Text("Choose a new password for\n\(authVM.user?.email ?? "your account")")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)

                    VStack(spacing: 15) {
                        secureField(placeholder: "New Password", text: $newPassword)
                        secureField(placeholder: "Confirm Password", text: $confirmPassword)

                        Text("8+ characters")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.65))
                    }

                    // Error — reserved height so it doesn't shift layout
                    Text(errorMsg ?? " ")
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .opacity(errorMsg == nil ? 0 : 1)

                    GradientButton(
                        title: isLoading ? "Updating…" : "Update Password",
                        icon: "checkmark"
                    ) {
                        guard !isLoading else { return }

                        guard newPassword.count >= 8 else {
                            errorMsg = "Password must be at least 8 characters"
                            return
                        }
                        guard newPassword == confirmPassword else {
                            errorMsg = "Passwords don't match"
                            return
                        }

                        errorMsg = nil
                        isLoading = true

                        Task {
                            do {
                                try await authVM.updatePasswordAfterRecovery(newPassword: newPassword)
                                // Password set — sign out of the recovery session so the
                                // user logs back in fresh with their new password.
                                authVM.signOut()
                            } catch {
                                errorMsg = error.localizedDescription
                            }
                            isLoading = false
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 100)
                .padding(.bottom, 20)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollBounceBehavior(.basedOnSize)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    private func secureField(placeholder: String, text: Binding<String>) -> some View {
        HStack {
            Image(systemName: "lock.fill")
                .foregroundColor(.black)

            SecureField(placeholder, text: text)
                .foregroundColor(.black)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white)
        )
    }
}

#Preview {
    ResetPasswordView()
        .environmentObject(AuthViewModel())
}