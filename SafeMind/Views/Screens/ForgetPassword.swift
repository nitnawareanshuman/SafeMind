//
//  ForgetPasswordMain.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 15/04/26.
//


import SwiftUI

struct ForgetPasswordView: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State private var email: String = ""
    @State private var isEmailSent = false
    @State private var errorMsg: String? = nil
    @State private var isLoading = false
    
    var body: some View {
        ZStack {
            LoginBackground()
            
            VStack(spacing: 25) {
                
                // 🔙 Back Button
                HStack {
                    BackButton {
                        dismiss()
                    }
                    Spacer()
                }
                .padding(.top, 10)
                
                Spacer()
                
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
                    
                    // Error
                    if let errorMsg = errorMsg {
                        Text(errorMsg)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    
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
                                try await AuthenticationManager.shared.resetPassword(email: email)
                                
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
                    
                    Text("Follow the link in the email to reset your password.")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                    
                    // Back to Login
                    Button("Back to Login") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.blue)
                    .cornerRadius(12)
                    .padding(.top)
                }
                
                Spacer()
            }
            .padding()
        }
    }
}
#Preview {
    ForgetPasswordView()
}
