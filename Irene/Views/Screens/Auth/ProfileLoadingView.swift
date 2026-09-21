//
//  ProfileLoadingView.swift
//  Irene
//
//  Created by Anshuman Nitnaware on 30/07/26.
//


//
//  ProfileStatusViews.swift
//  Irene
//
//  Brief in-between states for the "Profile Exists?" step of the auth flow.
//  This almost never lingers — the `profiles` row is created by a DB trigger
//  during sign up — but it covers the rare race where the trigger hasn't run yet.
//

import SwiftUI

struct ProfileLoadingView: View {
    var body: some View {
        ZStack {
            BlurBackground()
            ProgressView()
                .scaleEffect(1.3)
                .tint(.primary)
        }
    }
}

struct ProfileErrorView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        ZStack {
            LoginBackground()

            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.primary)

                Text("We couldn't set up your profile")
                    .font(.title3.bold())
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)

                Text(authVM.errorMessage ?? "Something went wrong. Please try again.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                GradientButton(title: "Try Again") {
                    Task { await authVM.ensureProfile() }
                }

                Button("Sign Out") {
                    authVM.signOut()
                }
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 32)
        }
    }
}
