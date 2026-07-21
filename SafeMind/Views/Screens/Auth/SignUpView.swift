//
//  SignUpView.swift
//  SafeMind
//

import SwiftUI

struct SignUpView: View {

    @EnvironmentObject var authVM: AuthViewModel

    @State private var errorMsg: String? = nil
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var goToLogin = false
    @State private var goToEmailVerification = false
    @State private var isLoading = false

    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }

    var body: some View {
        ZStack {
            LoginBackground()

            VStack {
                
                Spacer()

                // Center Content
                VStack(spacing: 25) {

                    // Title
                    Text("SIGN UP")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)

                    // Input Fields
                    VStack(spacing: 15) {

                        inputField(
                            icon: "person.fill",
                            placeholder: "First Name",
                            text: $firstName
                        )

                        inputField(
                            icon: "person.fill",
                            placeholder: "Last Name",
                            text: $lastName
                        )

                        inputField(
                            icon: "envelope.fill",
                            placeholder: "Email",
                            text: $email,
                            keyboard: .emailAddress
                        )

                        secureField(
                            icon: "lock.fill",
                            placeholder: "Password",
                            text: $password
                        )

                        Text("8+ chars · 1 number · 1 uppercase · 1 special character")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.65))
                            .multilineTextAlignment(.center)
                    }

                    // Error
                    if let error = errorMsg {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                    }

                    // Sign Up Button
                    GradientButton(
                        title: isLoading ? "Creating account…" : "Sign Up",
                        icon: "arrow.right"
                    ) {
                        guard !isLoading else { return }

                        if firstName.isEmpty ||
                            lastName.isEmpty ||
                            email.isEmpty ||
                            password.isEmpty {
                            errorMsg = "Please fill all fields"
                            return
                        }

                        errorMsg = nil
                        isLoading = true

                        Task {
                            let success = await authVM.signUp(
                                email: email,
                                password: password,
                                name: fullName
                            )

                            isLoading = false

                            if success {
                                goToEmailVerification = true
                            } else {
                                errorMsg = authVM.errorMessage ?? "Sign up failed"
                            }
                        }
                    }

                    // Terms
                    VStack(spacing: 4) {
                        Text("By signing up you agree to our")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.caption)

                        HStack(spacing: 4) {
                            Button("Terms & Conditions") {}
                                .foregroundColor(.white)

                            Text("and")
                                .foregroundColor(.white.opacity(0.7))

                            Button("Privacy Policy") {}
                                .foregroundColor(.white)
                        }
                        .font(.caption)
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Bottom Fixed Login Row
                HStack {
                    Text("Have an account?")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.system(size: 15, weight: .medium))

                    Spacer()

                    Button {
                        goToLogin = true
                    } label: {
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
            .ignoresSafeArea(.keyboard)
        }
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $goToLogin) {
            LoginView()
        }
        .navigationDestination(isPresented: $goToEmailVerification) {
            EmailVerificationView()
        }
    }

    // MARK: - Reusable field builders

    private func inputField(
        icon: String,
        placeholder: String,
        text: Binding<String>,
        keyboard: UIKeyboardType = .default
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.black)

            TextField(placeholder, text: text)
                .foregroundColor(.black)
                .keyboardType(keyboard)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(.white)
        )
    }

    private func secureField(
        icon: String,
        placeholder: String,
        text: Binding<String>
    ) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.black)

            SecureField(placeholder, text: text)
                .foregroundColor(.black)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(.white)
        )
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthViewModel())
}
