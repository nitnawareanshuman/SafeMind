//
//  MusicListView.swift
//  SafeMind
//
//  Created by Anshuman Nitnaware on 15/04/26.
//

import SwiftUI

struct MusicListView: View {
    let mood: String
    @StateObject private var playerVM = AudioPlayerViewModel()
    
    // All tracks combined from all moods
    var allTracks: [(mood: String, tracks: [Track])] {
        [
            ("Focus", MusicLibrary.focus),
            ("Calm", MusicLibrary.calm),
            ("Sleep", MusicLibrary.sleep)
        ]
    }
    
    var body: some View {
        ZStack {
            BlurBackground()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Show all moods with their tracks
                    ForEach(allTracks, id: \.mood) { moodSection in
                        VStack(alignment: .leading, spacing: 12) {
                            // Mood header
                            HStack {
                                Image(systemName: iconForMood(moodSection.mood))
                                    .foregroundColor(colorForMood(moodSection.mood))
                                Text(moodSection.mood)
                                    .font(.title2.bold())
                                Spacer()
                                Text("\(moodSection.tracks.count) tracks")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 4)
                            
                            // Tracks for this mood
                            ForEach(moodSection.tracks) { track in
                                NavigationLink {
                                    FocusView(selectedTrack: track, mood: moodSection.mood)
                                } label: {
                                    MusicCard(track: track, mood: moodSection.mood)
                                }
                            }
                        }
                        
                        // Divider between moods
                        if moodSection.mood != allTracks.last?.mood {
                            Divider()
                                .background(Color.secondary.opacity(0.3))
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("All Music")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func iconForMood(_ mood: String) -> String {
        switch mood {
        case "Focus": return "brain.head.profile"
        case "Calm": return "leaf.fill"
        case "Sleep": return "moon.stars.fill"
        default: return "music.note"
        }
    }
    
    private func colorForMood(_ mood: String) -> Color {
        switch mood {
        case "Focus": return .blue
        case "Calm": return .green
        case "Sleep": return .purple
        default: return .blue
        }
    }
}

struct MusicCard: View {
    let track: Track
    let mood: String
    
    var body: some View {
        HStack(spacing: 16) {
            // Music icon with mood-based color
            ZStack {
                Circle()
                    .fill(colorForMood(mood).opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: iconForMood(mood))
                    .font(.title2)
                    .foregroundColor(colorForMood(mood))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 8))
                    Text(mood)
                        .font(.caption)
                }
                .foregroundColor(colorForMood(mood))
            }
            
            Spacer()
            
            Image(systemName: "play.circle.fill")
                .font(.title2)
                .foregroundColor(colorForMood(mood))
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
    }
    
    private func iconForMood(_ mood: String) -> String {
        switch mood {
        case "Focus": return "brain.head.profile"
        case "Calm": return "leaf.fill"
        case "Sleep": return "moon.stars.fill"
        default: return "music.note"
        }
    }
    
    private func colorForMood(_ mood: String) -> Color {
        switch mood {
        case "Focus": return .blue
        case "Calm": return .green
        case "Sleep": return .purple
        default: return .blue
        }
    }
}

#Preview {
    NavigationStack {
        MusicListView(mood: "All")
    }
}
