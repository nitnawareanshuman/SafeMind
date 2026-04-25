//
//  SessionViewModel.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 24/04/26.
//


import Foundation
import Combine

@MainActor
class SessionViewModel: ObservableObject {
    
    @Published var sessions: [Session] = []
    @Published var isLoading = false
    
    func loadSessions(uid: String) {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                sessions = try await ProfileManager.shared.fetchSessions(uid: uid)
            } catch {
                print("❌ Failed to fetch sessions:", error.localizedDescription)
            }
        }
    }
}