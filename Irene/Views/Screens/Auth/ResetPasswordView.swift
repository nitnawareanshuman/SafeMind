//
//  ResetPasswordView.swift
//  Irene
//
//  Created by Anshuman Nitnaware on 30/07/26.
//


//
//  ResetPasswordView.swift
//  Irene
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
    @State private var passwordSaved = false

    var body: some View {
        ZStack {
            LoginBackground()

            ScrollView {
                VStack(spacing: 25) {

                    Text("NEW PASSWORD")
                        .font(.largeTitle.bold())
                        .foregroundColor(.primary)

                    Text("Choose a new password for\n\(authVM.user?.email ?? "your account")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 15) {
                        secureField(placeholder: "New Password", text: $newPassword)
                        secureField(placeholder: "Confirm Password", text: $confirmPassword)

                        Text("8+ characters, including an uppercase letter, a number, and a special character.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Error — reserved height so it doesn't shift layout
                    Text(errorMsg ?? " ")
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .opacity(errorMsg == nil ? 0 : 1)

                    GradientButton(
                        title: isLoading ? "Please wait…" : passwordSaved ? "Back to Login" : "Update Password",
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
                                if !passwordSaved {
                                    try await authVM.updatePasswordAfterRecovery(newPassword: newPassword)
                                    passwordSaved = true
                                }
                                try await authVM.finishRecovery()
                            } catch {
                                errorMsg = error.localizedDescription
                            }
                            isLoading = false
                        }
                    }
                    Button("Cancel and return to Login") { authVM.signOut() }
                        .disabled(isLoading)
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
                .foregroundColor(.primary)

            SecureField(placeholder, text: text)
                .foregroundColor(.primary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    ResetPasswordView()
        .environmentObject(AuthViewModel())
}

