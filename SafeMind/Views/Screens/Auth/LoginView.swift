//
//  LoginView.swift
//  SafeMind
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
                                .foregroundColor(.white)

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
                                        .foregroundColor(.black)
                                    
                                    TextField("Enter Email", text: $email)
                                        .foregroundColor(.black)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.white)
                                )
                                
                                // Password
                                HStack {
                                    Image(systemName: "lock.fill")
                                        .foregroundColor(.black)
                                    
                                    SecureField("Enter Password", text: $password)
                                        .foregroundColor(.black)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color.white)
                                )
                            }
                            
                            // Error Message — reserved height so it doesn't shift layout
                            Text(errorMsg ?? " ")
                                .foregroundColor(.red)
                                .font(.caption)
                                .opacity(errorMsg == nil ? 0 : 1)
                            
                            // Buttons
                            VStack(spacing: 15) {
                                
                                // Email Login
                                GradientButton(title: "Login", icon: "arrow.right") {
                                    
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
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Button("Click Here") {
                                        path.append(AuthRoute.forgotPassword)
                                    }
                                    .foregroundColor(.white)
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
                            .foregroundColor(.white.opacity(0.8))
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
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
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
            .foregroundColor(.black)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.white)
            .cornerRadius(14)
        }
    }
}

/// "── OR ──" separator used between the email form and social sign-in buttons.
struct OrDivider: View {
    var body: some View {
        HStack(spacing: 10) {
            Rectangle().fill(Color.white.opacity(0.25)).frame(height: 1)
            Text("OR")
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.6))
            Rectangle().fill(Color.white.opacity(0.25)).frame(height: 1)
        }
    }
}

#Preview {
    LoginView(path: .constant(NavigationPath()))
        .environmentObject(AuthViewModel())
}
