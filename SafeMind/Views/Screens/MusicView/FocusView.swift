//
//  FocusView.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 16/04/26.
//

import SwiftUI
import AVFoundation

struct FocusView: View {
    let selectedTrack: Track
    let mood: String
    
    @StateObject private var playerVM = AudioPlayerViewModel()
    @State private var isAnimating = false
    @EnvironmentObject var authVM: AuthViewModel
    
    var body: some View {
        ZStack {
            BlurBackground()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Animated Music Visualizer Box
                ZStack {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(.ultraThinMaterial)
                        .frame(width: 250, height: 250)
                        .shadow(color: .blue.opacity(0.3), radius: 20)
                    
                    VStack(spacing: 20) {
                        // Animated bars
                        HStack(alignment: .center, spacing: 8) {
                            ForEach(0..<5) { index in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.blue)
                                    .frame(width: 8, height: playerVM.isPlaying ? CGFloat.random(in: 30...80) : 20)
                                    .animation(
                                        playerVM.isPlaying ?
                                        Animation.easeInOut(duration: 0.5)
                                            .repeatForever(autoreverses: true)
                                            .delay(Double(index) * 0.1)
                                        : .default,
                                        value: playerVM.isPlaying
                                    )
                            }
                        }
                        
                        Image(systemName: "headphones")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .foregroundColor(.blue)
                            .scaleEffect(isAnimating ? 1.1 : 1.0)
                            .animation(
                                playerVM.isPlaying ?
                                Animation.easeInOut(duration: 1.0)
                                    .repeatForever(autoreverses: true)
                                : .default,
                                value: isAnimating
                            )
                    }
                }
                .onChange(of: playerVM.isPlaying) { newValue in
                    isAnimating = newValue
                }
                
                // Track info
                VStack(spacing: 6) {
                    Text(mood)
                        .font(.title.bold())
                    Text(playerVM.currentTrack)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Improve concentration with ambient music")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Controls
                HStack(spacing: 50) {
                    // Play/Pause toggle
                    controlButton(
                        icon: playerVM.isPlaying ? "pause.circle.fill" : "play.circle.fill",
                        color: .blue,
                        size: 65
                    ) {
                        if playerVM.isPlaying {
                            playerVM.pause()

                            Task {
                                guard let uid = authVM.user?.uid else { return }

                                let session = Session(
                                    id: UUID().uuidString,
                                    type: "focus",
                                    duration: 300,
                                    date: Date()
                                )

                                do {
                                    try await ProfileManager.shared.saveSession(uid: uid, session: session)
                                    print("✅ Session saved")
                                } catch {
                                    print("❌ Failed to save session:", error.localizedDescription)
                                }
                            }

                        } else {
                            playerVM.playTrack(track: selectedTrack)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .navigationTitle(mood)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Auto-play when view appears
            playerVM.playTrack(track: selectedTrack)
        }
        .onDisappear {
            // Stop playback when leaving the view
            playerVM.stop()
        }
    }
    
    private func controlButton(icon: String, color: Color, size: CGFloat = 50, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size))
                .foregroundColor(color)
        }
    }
}

#Preview {
    NavigationStack {
        FocusView(
            selectedTrack: Track(
                title: "Deep Forest Rain",
                url: "forest_rain"
            ),
            mood: "Focus"
        )
        .environmentObject(AuthViewModel())
    }
}
