//
//  SettingsView.swift
//  SafeMind
//

import SwiftUI

struct SettingsView: View {

    @EnvironmentObject var authVM: AuthViewModel   // ✅ use shared VM, not raw Auth
    @Environment(\.dismiss) var dismiss

    @State private var notificationsEnabled = true
    @State private var selectedLanguage = "English"

    let languages = ["English", "Hindi"]

    var body: some View {
        ZStack {
            BlurBackground().ignoresSafeArea()

            VStack(spacing: 20) {

                // Notifications
                HStack {
                    Label("Notifications", systemImage: "bell.fill")
                    Spacer()
                    Toggle("", isOn: $notificationsEnabled).labelsHidden()
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)

                // Language
                VStack(alignment: .leading, spacing: 8) {
                    Label("Language", systemImage: "globe")
                        .font(.headline)

                    Picker("Language", selection: $selectedLanguage) {
                        ForEach(languages, id: \.self) { Text($0) }
                    }
                    .pickerStyle(.segmented)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                
                // Profile Section
                NavigationLink {
                    if let uid = authVM.user?.uid {
                        ProfileView(uid: uid)
                            .environmentObject(authVM)
                    }
                } label: {
                    HStack {
                        Image(systemName: "person.circle.fill")
                        Text("My Profile")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                }
                
                NavigationLink {
                    SessionHistoryView()
                        .environmentObject(authVM)
                } label: {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("Session History")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                }

                Spacer()

                // ✅ Logout now calls authVM.signOut() so ContentView/NavigationStack updates
                Button(action: {
                    authVM.signOut()
                }) {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle("Settings")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AuthViewModel())
    }
}
