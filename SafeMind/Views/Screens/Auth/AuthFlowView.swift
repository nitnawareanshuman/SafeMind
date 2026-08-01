//
//  AuthRoute.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 30/07/26.
//


//
//  AuthFlowView.swift
//  SafeMind
//
//  Hosts the pre-authentication screens (Login, Sign Up, Forgot Password) in a single
//  NavigationStack driven by one NavigationPath. Login is always the root.
//
//  Why this exists: previously each screen kept its own `@State` bool and pushed a brand
//  new instance of the destination view (e.g. tapping "Login" from Sign Up pushed a *new*
//  LoginView rather than popping back to the existing one). That stacked duplicate screens
//  and made the transition feel like one view overlapping another. Routing through a single
//  shared path means going to Sign Up is a push and coming back is a real pop — the same
//  smooth slide-in/slide-out both directions.
//

import SwiftUI

enum AuthRoute: Hashable {
    case signUp
    case forgotPassword
}

struct AuthFlowView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            LoginView(path: $path)
                .navigationDestination(for: AuthRoute.self) { route in
                    switch route {
                    case .signUp:
                        SignUpView(path: $path)
                    case .forgotPassword:
                        ForgetPasswordView(path: $path)
                    }
                }
        }
    }
}

#Preview {
    AuthFlowView()
        .environmentObject(AuthViewModel())
}