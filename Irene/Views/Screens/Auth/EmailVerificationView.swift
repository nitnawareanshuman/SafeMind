//
//  EmailVerificationView.swift
//  Irene
//
//  Created by Anshuman Nitnaware on 31/03/26.
//

import SwiftUI

struct EmailVerificationView: View {
    
    let email: String

    @EnvironmentObject var authVM: AuthViewModel

    @State private var message: String? = nil
    @State private var isSending = false


    var body: some View {
        ZStack {

            // Keep same background
            LoginBackground()

            VStack {

                ScrollView (showsIndicators: false) {
                    
                    VStack(spacing: 28) {

                        // Title
                        Text("VERIFY EMAIL")
                            .font(.largeTitle.bold())
                            .foregroundColor(.primary)

                        // Description with email visible
                        VStack(spacing: 8) {
                            Text("We've sent an email to")
                                .foregroundColor(.secondary)
                                .font(.subheadline)

                            Text(email)
                                .font(.headline)
                                .foregroundColor(.primary)

                            Text("Open the link on this device to verify your email, then log in. If you verified elsewhere, return to Login.")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal)

                        // Resend Email Button
                        Button {
                            guard !isSending, authVM.resendSeconds(email: email) == 0 else { return }
                            isSending = true
                            Task {
                                defer { isSending = false }
                                do {
                                    try await authVM.resendVerification(email: email)
                                    message = "Verification email sent"
                                } catch {
                                    message = error.localizedDescription
                                }
                            }
                        } label: {
                            TimelineView(.periodic(from: .now, by: 1)) { _ in
                                let seconds = authVM.resendSeconds(email: email)
                                Text(isSending ? "Sending…" : seconds > 0 ? "Resend in \(seconds)s" : "Resend Email")
                            }
                                .foregroundColor(.white)
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 55)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.blue)
                                )
                        }

                        .disabled(isSending)

                        // Status Message — reserved height so it doesn't shift layout
                        Text(message ?? " ")
                            .foregroundColor(.primary)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .opacity(message == nil ? 0 : 1)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 100)

                    Spacer()

                    // Bottom Login Button (keep existing component)
                    HStack {
                        Text("Already verified?")
                            .foregroundColor(.secondary)
                            .font(.system(size: 15, weight: .medium))

                        Spacer()

                        Button(action: {
                            authVM.signOut()
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
                            .stroke(Color.primary.opacity(0.15), lineWidth: 1)
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .ignoresSafeArea(.keyboard, edges: .bottom)
                }
        }

    }
}
