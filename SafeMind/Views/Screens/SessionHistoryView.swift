//
//  SessionHistoryView.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 24/04/26.
//


import SwiftUI

struct SessionHistoryView: View {
    
    @StateObject private var vm = SessionViewModel()
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        ZStack {
            BlurBackground()
            
            if vm.isLoading {
                ProgressView()
            } else if vm.sessions.isEmpty {
                Text("No sessions yet")
                    .foregroundColor(.secondary)
            } else {
                List(vm.sessions) { session in
                    sessionRow(session)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle("Session History")
        .onAppear {
            if let uid = authVM.user?.uid {
                vm.loadSessions(uid: uid)
            }
        }
    }
    
    // MARK: - Row UI
    
    private func sessionRow(_ session: Session) -> some View {
        HStack {
            
            Image(systemName: icon(for: session.type))
                .foregroundColor(color(for: session.type))
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(session.type.capitalized)
                    .font(.headline)
                
                Text(formatDate(session.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(session.duration)s")
                .font(.subheadline.bold())
        }
        .padding(.vertical, 6)
    }
    
    // MARK: - Helpers
    
    private func icon(for type: String) -> String {
        switch type {
        case "breathing": return "wind"
        case "cbt": return "brain.head.profile"
        case "focus": return "headphones"
        case "acupressure": return "hand.point.up.left"
        default: return "clock"
        }
    }
    
    private func color(for type: String) -> Color {
        switch type {
        case "breathing": return .blue
        case "cbt": return .purple
        case "focus": return .green
        case "acupressure": return .orange
        default: return .gray
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: date)
    }
}