//
//  LoginView.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 22/03/26.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    
    @EnvironmentObject var authVM: AuthViewModel
    
    @State private var errorMsg: String? = nil
    @State private var goToSignUp = false
    
    @State private var email: String = ""
    @State private var password: String = ""
    
    @State private var goToForgotPassword = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                LoginBackground()
                
                VStack {
                    
                    Spacer()
                    
                    // Center Content
                    VStack(spacing: 25) {
                        
                        // Title
                        Text("LOGIN")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        
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
                        
                        // Error Message
                        if let error = errorMsg {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                        
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
                                    goToForgotPassword = true
                                }
                                .foregroundColor(.white)
                            }
                            
                            Text("OR")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                            
                            // Google Sign In
                            AuthButton(
                                text: "Continue with Google",
                                icon: "Google"
                            ) {
                                authVM.signInWithGoogle()
                            }
                            
                            // Apple Sign In
                            SignInWithAppleButton(
                                .signIn,
                                onRequest: { request in
                                    authVM.signInWithAppleRequest(request)
                                },
                                onCompletion: { result in
                                    authVM.handleSignInWithAppleCompletion(result)
                                }
                            )
                            .signInWithAppleButtonStyle(.white)
                            .frame(height: 50)
                            .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Bottom Fixed Sign Up Row
                    HStack {
                        Text("Not a member?")
                            .foregroundColor(.white.opacity(0.8))
                            .font(.system(size: 15, weight: .medium))
                        
                        Spacer()
                        
                        Button {
                            goToSignUp = true
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
                .ignoresSafeArea(.keyboard)
            }
            .navigationBarBackButtonHidden(true)
            .navigationDestination(isPresented: $goToSignUp) {
                SignUpView()
            }
            .navigationDestination(isPresented: $goToForgotPassword) {
                ForgetPasswordView()
            }
        }
    }
}

struct AuthButton: View {
    var text: String
    var icon: String
    var onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 12) {
                
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                
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

#Preview {
    LoginView()
}
