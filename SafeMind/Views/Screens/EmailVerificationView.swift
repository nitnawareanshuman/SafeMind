//
//  EmailVerificationView.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 31/03/26.
//

import SwiftUI
import FirebaseAuth
import Combine

struct EmailVerificationView: View {

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var authVM: AuthViewModel

    @State private var message: String? = nil

    // Auto check every 3 seconds
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {

            // Keep same background
            LoginBackground()

            VStack {

                Spacer()

                VStack(spacing: 22) {

                    // Title
                    Text("VERIFY EMAIL")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    // Description with email visible
                    VStack(spacing: 8) {
                        Text("We've sent an email to")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.subheadline)

                        Text(Auth.auth().currentUser?.email ?? "your@email.com")
                            .font(.headline)
                            .foregroundColor(.white)

                        Text("Continue account creation using the link via email.")
                            .foregroundColor(.white.opacity(0.75))
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)

                    // Resend Email Button
                    Button {
                        Task {
                            do {
                                try await AuthenticationManager.shared.sendEmailVerification()
                                message = "Verification email sent"
                            } catch {
                                message = error.localizedDescription
                            }
                        }
                    } label: {
                        Text("Resend Email")
                            .foregroundColor(.white)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 55)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.blue)
                            )
                    }

                    // Status Message
                    if let message = message {
                        Text(message)
                            .foregroundColor(.white)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()

                // Bottom Login Button (keep existing component)
                HStack {
                    Text("Have an account?")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.system(size: 15, weight: .medium))

                    Spacer()

                    Button(action: {
                        dismiss()
                    }) {
                        Text("Login")
                            .foregroundColor(.white)
                            .font(.system(size: 15, weight: .semibold))
                            .frame(width: 110, height: 40)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(0.9))
                            )
                    }
                }
                .padding(.horizontal, 20)
                .frame(height: 55)
                .background(
                    Capsule()
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }

        // Auto-check when screen appears
        .onAppear {
            Task {
                await checkVerificationStatus()
            }
        }

        // Auto-check every 3 seconds
        .onReceive(timer) { _ in
            Task {
                await checkVerificationStatus()
            }
        }
    }

    // MARK: - Auto Check Verification

    private func checkVerificationStatus() async {
        await authVM.reloadVerificationStatus()

        if authVM.isEmailVerified {
            if let firebaseUser = Auth.auth().currentUser {
                authVM.user = AuthDataResultModel(user: firebaseUser)
            }

            message = "Email verified successfully ✅"
        }
    }
}

#Preview {
    EmailVerificationView()
        .environmentObject(AuthViewModel())
}
