//
//  LoginView.swift
//  Irene
//
//  Created by Anshuman Nitnaware on 22/03/26.
//

import SwiftUI

struct LoginView: View {
    
    @EnvironmentObject var authVM: AuthViewModel
    @Binding var path: NavigationPath
    
    @State private var errorMsg: String? = nil
    @State private var isSocialLoading = false
    
    @State private var email: String = ""
    @State private var password: String = ""
    
    var body: some View {
            ZStack {
                
                LoginBackground()
                
                VStack(spacing: 0) {
                    
                    // Center Content — fixed from top, scrolls if keyboard needs room
                    ScrollView {
                        VStack(spacing: 25) {
                            
                            // Title
                            Text("LOGIN")
                                .font(.largeTitle.bold())
                                .foregroundColor(.primary)

                            // Info Message (e.g. "Email verified — please log in") — reserved
                            // height so it doesn't shift layout. Never shown as a dialog.
                            Text(authVM.infoMessage ?? " ")
                                .foregroundColor(.green)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                                .opacity(authVM.infoMessage == nil ? 0 : 1)
                            
                            // Input Fields
                            VStack(spacing: 15) {
                                
                                // Email
                                HStack {
                                    Image(systemName: "envelope.fill")
                                        .foregroundColor(.primary)
                                    
                                    TextField("Enter Email", text: $email)
                                        .foregroundColor(.primary)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color(.secondarySystemBackground))
                                )
                                
                                // Password
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.primary)
                                    
                                    SecureField("Enter Password", text: $password)
                                        .foregroundColor(.primary)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color(.secondarySystemBackground))
                                )
                            }
                            
                            // Error Message — reserved height so it doesn't shift layout
                            Text(errorMsg ?? authVM.errorMessage ?? " ")
                                .foregroundColor(.red)
                                .font(.caption)
                                .opacity(errorMsg == nil && authVM.errorMessage == nil ? 0 : 1)
                            
                            TimelineView(.periodic(from: .now, by: 1)) { _ in
                                let seconds = authVM.resendSeconds(email: email)
                                Button(seconds > 0 ? "Resend verification in \(seconds)s" : "Resend verification email") {
                                    Task {
                                        do {
                                            try await authVM.resendVerification(email: email)
                                            authVM.infoMessage = "If verification is pending, check your email."
                                        } catch { errorMsg = error.localizedDescription }
                                    }
                                }
                                .disabled(email.isEmpty || seconds > 0)
                            }

                            // Buttons
                            VStack(spacing: 15) {
                                
                                // Email Login
                                GradientButton(title: "Login", icon: "arrow.right") {
                                    
                                    guard !authVM.isLoading else { return }
                                    if email.isEmpty || password.isEmpty {
                                        errorMsg = "Please fill all fields"
                                    } else {
                                        errorMsg = nil
                                        
                                        Task {
                                            let success = await authVM.signIn(
                                                email: email,
                                                password: password
                                            )
                                            
                                            if !success {
                                                errorMsg = authVM.errorMessage ?? "Login failed"
                                            }
                                        }
                                    }
                                }
                                
                                // Forgot Password
                                HStack {
                                    Text("Forget your password?")
                                        .foregroundColor(.secondary)
                                    
                                    Button("Click Here") {
                                        path.append(AuthRoute.forgotPassword)
                                    }
                                    .foregroundColor(.primary)
                                }
                                
                            }

                            OrDivider()

                            // Social Sign-In
                            VStack(spacing: 12) {
                                AuthButton(text: "Continue with Apple", systemIcon: "apple.logo") {
                                    signInWithApple()
                                }
                                AuthButton(text: "Continue with Google", assetIcon: "Google") {
                                    signInWithGoogle()
                                }
                            }
                            .disabled(isSocialLoading)
                            .opacity(isSocialLoading ? 0.6 : 1)
                        }
                        .padding(.horizontal)
                        .padding(.top, 80)
                        .padding(.bottom, 20)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .scrollBounceBehavior(.basedOnSize)
                    
                    // Bottom Fixed Sign Up Row
                    HStack {
                        Text("Not a member?")
                            .foregroundColor(.secondary)
                            .font(.system(size: 15, weight: .medium))
                        
                        Spacer()
                        
                        Button {
                            path.append(AuthRoute.signUp)
                        } label: {
                            Text("Sign Up")
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
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Social Sign-In

    private func signInWithApple() {
        guard !isSocialLoading else { return }
        errorMsg = nil
        isSocialLoading = true
        Task {
            do {
                let result = try await AppleSignInCoordinator().start()
                let success = await authVM.signInWithApple(idToken: result.idToken, rawNonce: result.rawNonce)
                if !success { errorMsg = authVM.errorMessage ?? "Apple sign-in failed" }
            } catch {
                errorMsg = error.localizedDescription
            }
            isSocialLoading = false
        }
    }

    private func signInWithGoogle() {
        guard !isSocialLoading else { return }
        errorMsg = nil
        isSocialLoading = true
        Task {
            let success = await authVM.signInWithGoogle()
            if !success { errorMsg = authVM.errorMessage ?? "Google sign-in failed" }
            isSocialLoading = false
        }
    }
}

/// Reusable "Continue with ..." button — pass either a SF Symbol (`systemIcon`) or an asset
/// image name (`assetIcon`).
struct AuthButton: View {
    var text: String
    var systemIcon: String? = nil
    var assetIcon: String? = nil
    var onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 12) {
                if let systemIcon {
                    Image(systemName: systemIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                } else if let assetIcon {
                    Image(assetIcon)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                }

                Text(text)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(14)
        }
    }
}

/// "── OR ──" separator used between the email form and social sign-in buttons.
struct OrDivider: View {
    var body: some View {
        HStack(spacing: 10) {
            Rectangle().fill(Color.primary.opacity(0.15)).frame(height: 1)
            Text("OR")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            Rectangle().fill(Color.primary.opacity(0.15)).frame(height: 1)
        }
    }
}

#Preview {
    LoginView(path: .constant(NavigationPath()))
        .environmentObject(AuthViewModel())
}

