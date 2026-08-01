//
//  ContentView.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 04/03/26.
//
//  Top-level state machine:
//
//  Splash → Authenticated? → No  → Login / Sign Up / Forgot Password (AuthFlowView)
//                          → Yes → Email Verified? → No  → Verify Email
//                                                  → Yes → Profile Exists? → No  → (create it, briefly) Loading
//                                                                          → Yes → Home
//
//  A password-reset deep link can arrive at any point, so it's checked first and
//  overrides everything else while active.
//

import SwiftUI

struct ContentView: View {

    @EnvironmentObject var authVM: AuthViewModel
    @State private var minimumSplashElapsed = false

    /// Computed once, synchronously, at view creation — true when today's mood
    /// check-in hasn't happened yet, so the gate should show before Home.
    @State private var showMoodCheckIn = !MoodCheckInViewModel.hasCompletedToday()

    /// Keep the splash up for a small minimum duration *and* until the first auth
    /// event resolves, so we never flash the Login screen before a saved session restores.
    private var showSplash: Bool {
        !minimumSplashElapsed || authVM.isInitializing
    }

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if authVM.isPasswordRecovery {
                ResetPasswordView()
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else if authVM.user == nil {
                AuthFlowView()
                    .transition(.opacity)
            } else if !authVM.isEmailVerified {
                EmailVerificationView()
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
            } else if authVM.profileCheckFailed {
                ProfileErrorView()
                    .transition(.opacity)
            } else if authVM.profile == nil {
                ProfileLoadingView()
                    .transition(.opacity)
            } else if showMoodCheckIn {
                // Daily AI Mood Check-In gate — shown once per day, right after auth,
                // before the user lands on Home.
                NavigationStack {
                    MoodCheckInChatView(onComplete: { showMoodCheckIn = false })
                }
                .transition(.opacity)
            } else {
                HomeView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: showSplash)
        .animation(.easeInOut(duration: 0.35), value: authVM.isPasswordRecovery)
        .animation(.easeInOut(duration: 0.35), value: authVM.user)
        .animation(.easeInOut(duration: 0.35), value: authVM.isEmailVerified)
        .animation(.easeInOut(duration: 0.35), value: authVM.profile)
        .animation(.easeInOut(duration: 0.35), value: authVM.profileCheckFailed)
        .animation(.easeInOut(duration: 0.35), value: showMoodCheckIn)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                minimumSplashElapsed = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthViewModel())
}
