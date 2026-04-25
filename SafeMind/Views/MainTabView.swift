//
//  MainTabView.swift
//  SafeMind
//

import SwiftUI

struct MainTabView: View {

    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }

            ExploreView()
                .tabItem { Label("Explore", systemImage: "square.grid.2x2.fill") }

            // ✅ Pass the real uid from the logged-in user
            ProfileView(uid: authVM.user?.uid ?? "")
                .tabItem { Label("Profile", systemImage: "person.fill") }
        }
        .environmentObject(authVM)
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel())
}
