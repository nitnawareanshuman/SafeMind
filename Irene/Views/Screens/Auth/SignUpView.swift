//
//  SignUpView.swift
//  Irene
//

import SwiftUI

struct SignUpView: View {

    @EnvironmentObject var authVM: AuthViewModel
    @Binding var path: NavigationPath

    @State private var errorMsg: String? = nil
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading = false
    @State private var isSocialLoading = false
    @State private var navigateToEmailVerification = false

    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
    }

    private let specialCharacters = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:'\",.<>?/`~\\")

    private var isPasswordValid: Bool {
        password.count >= 8
            && password.contains(where: { $0.isUppercase })
            && password.contains(where: { $0.isNumber })
            && password.unicodeScalars.contains(where: { specialCharacters.contains($0) })
    }

    var body: some View {
        ZStack {
            LoginBackground()

            VStack(spacing: 0) {

                // Center Content — fixed from top, scrolls if keyboard needs room
                ScrollView {
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
                                .foregroundColor(
                                    password.isEmpty ? .white.opacity(0.65)
                                    : (isPasswordValid ? .green : .red.opacity(0.85))
                                )
                                .multilineTextAlignment(.center)
                        }

                        // Error — reserved height so it doesn't shift layout
                        Text(errorMsg ?? " ")
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .opacity(errorMsg == nil ? 0 : 1)

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

                            guard isPasswordValid else {
                                errorMsg = "Password needs 8+ chars, 1 uppercase, 1 number & 1 special character"
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
                                    navigateToEmailVerification = true
                                } else {
                                    errorMsg = authVM.errorMessage ?? "Sign up failed"
                                }
                                // On success, ContentView reacts to authVM.user being set
                                // and transitions straight to the email-verification screen.
                            }
                        }

                        OrDivider()

                        // Social Sign-Up
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
                    .padding(.top, 30)
                    .padding(.bottom, 10)
                }
                .scrollDismissesKeyboard(.interactively)
                .scrollBounceBehavior(.basedOnSize)

                // Bottom Fixed Login Row
                HStack {
                    Text("Have an account?")
                        .foregroundColor(.white.opacity(0.8))
                        .font(.system(size: 15, weight: .medium))

                    Spacer()

                    Button {
                        if !path.isEmpty { path.removeLast() }
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
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $navigateToEmailVerification) {
            EmailVerificationView(email: email)
                .environmentObject(authVM)
        }
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
    SignUpView(path: .constant(NavigationPath()))
        .environmentObject(AuthViewModel())
}
