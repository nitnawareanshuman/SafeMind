//
//  ForgetPasswordMain.swift
//  Irene
//
//  Created by Anshuman Nitnaware on 15/04/26.
//


import SwiftUI

struct ForgetPasswordView: View {
    
    @EnvironmentObject var authVM: AuthViewModel
    @Binding var path: NavigationPath
    
    @State private var email: String = ""
    @State private var isEmailSent = false
    @State private var errorMsg: String? = nil
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            LoginBackground()
            
            VStack(spacing: 0) {
                
                HStack {
                    BackButton {
                        if !path.isEmpty { path.removeLast() }
                    }
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                ScrollView {
                    VStack(spacing: 25) {
                        
                        // Title
                        Text("FORGOT PASSWORD")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        
                        if !isEmailSent {
                    
                    // 📝 Step 1: Enter Email
                    
                    Text("Enter your email and we'll send a password reset link.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.75))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.gray)
                        
                        TextField("Enter Email", text: $email)
                            .foregroundColor(.black)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(.white)
                    )
                    
                            // Error — reserved height so it doesn't shift layout
                            Text(errorMsg ?? " ")
                                .foregroundColor(.red)
                                .font(.caption)
                                .opacity(errorMsg == nil ? 0 : 1)
                            
                            // Submit
                            GradientButton(title: isLoading ? "Sending..." : "Send Reset Link") {
                                
                                if email.isEmpty {
                                    errorMsg = "Please enter email"
                                    return
                                }
                                
                                errorMsg = nil
                                isLoading = true
                                
                                Task {
                                    do {
                                        try await authVM.sendPasswordReset(email: email)
                                        
                                        // ✅ Switch UI state
                                        isEmailSent = true
                                        
                                    } catch {
                                        errorMsg = error.localizedDescription
                                    }
                                    
                                    isLoading = false
                                }
                            }
                            
                        } else {
                            
                            // ✅ Step 2: Email Sent UI
                            
                            Image(systemName: "envelope.open.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.white)
                            
                            Text("Check your email 📩")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            Text("We’ve sent a password reset link to:\n\(email)")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                            
                            Text("Tap the link on this device — Irene will open so you can set a new password.")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                                .multilineTextAlignment(.center)
                            
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                }
                .scrollDismissesKeyboard(.interactively)
                .scrollBounceBehavior(.basedOnSize)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
    }
}
#Preview {
    ForgetPasswordView(path: .constant(NavigationPath()))
        .environmentObject(AuthViewModel())
}
