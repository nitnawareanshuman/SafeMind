//
//  ContentView.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 04/03/26.
//

import SwiftUI
import FirebaseAuth

struct ContentView: View {

    @EnvironmentObject var authVM: AuthViewModel
    @State private var showSplash = true

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
            } else {
                if authVM.user != nil {
                    if authVM.isEmailVerified {
                        HomeView()
                    } else {
                        EmailVerificationView()
                    }
                } else {
                    LoginView()
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showSplash = false
            }
        }
    }

    
    func userIsVerified() -> Bool {
        return Auth.auth().currentUser?.isEmailVerified ?? false
    }
}

#Preview {
    ContentView()
}
