//
//  IreneApp.swift
//  Irene
//
//  Created by Anshuman Nitnaware on 04/03/26.
//

import SwiftUI
import Supabase
 
@main
struct IreneApp: App {
    @StateObject private var authViewModel: AuthViewModel
 
    init() {
        let users = UserManager(client: supabase)
        _authViewModel = StateObject(wrappedValue: AuthViewModel(authManager: AuthManager(client: supabase, userManager: users)))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .onOpenURL { url in
                    Task {
                        await authViewModel.handleAuthURL(url)
                    }
                }
        }
    }

}
