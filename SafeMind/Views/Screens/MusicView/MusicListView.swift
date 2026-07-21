//
//  MusicListView.swift
//  SafeMind
//

import SwiftUI

// MARK: - Genre Model
struct MusicGenre {
    let name: String
    let symbol: String
    let gradient: [Color]
    let tracks: [Track]
    let tagline: String
}

let allGenres: [MusicGenre] = [
    MusicGenre(
        name: "Focus",
        symbol: "brain.head.profile",
        gradient: [Color(hex: "#1A1AFF"), Color(hex: "#00C2FF")],
        tracks: MusicLibrary.focus,
        tagline: "Deep work mode"
    ),
    MusicGenre(
        name: "Calm",
        symbol: "leaf.fill",
        gradient: [Color(hex: "#11998E"), Color(hex: "#38EF7D")],
        tracks: MusicLibrary.calm,
        tagline: "Breathe & unwind"
    ),
    MusicGenre(
        name: "Sleep",
        symbol: "moon.stars.fill",
        gradient: [Color(hex: "#4B0082"), Color(hex: "#9B59B6")],
        tracks: MusicLibrary.sleep,
        tagline: "Drift into rest"
    ),
    MusicGenre(
        name: "Energy",
        symbol: "bolt.fill",
        gradient: [Color(hex: "#FF4E50"), Color(hex: "#FF9A00")],
        tracks: MusicLibrary.focus, // swap with MusicLibrary.energy when available
        tagline: "Rise & ignite"
    )
]

// MARK: - Genre Grid (Full Screen)
struct MusicListView: View {
    let mood: String

    var body: some View {
        GeometryReader { geo in
            let half = geo.size.height / 2
            let halfW = geo.size.width / 2

            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        GenreTile(genre: allGenres[0], size: CGSize(width: halfW, height: half))
                        GenreTile(genre: allGenres[1], size: CGSize(width: halfW, height: half))
                    }
                    HStack(spacing: 0) {
                        GenreTile(genre: allGenres[2], size: CGSize(width: halfW, height: half))
                        GenreTile(genre: allGenres[3], size: CGSize(width: halfW, height: half))
                    }
                }
            }
        }
        .ignoresSafeArea()
        .navigationTitle("Music")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Genre Tile
struct GenreTile: View {
    let genre: MusicGenre
    let size: CGSize
    @State private var pressed = false

    var body: some View {
        NavigationLink(destination: GenreTrackListView(genre: genre)) {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: genre.gradient,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                // Subtle noise overlay
                Rectangle()
                    .fill(.black.opacity(0.15))

                // Content
                VStack(spacing: 12) {
                    Image(systemName: genre.symbol)
                        .font(.system(size: 44, weight: .medium))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 8, y: 4)

                    Text(genre.name)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(genre.tagline)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.75))
                        .tracking(1.2)
                        .textCase(.uppercase)

                    Text("\(genre.tracks.count) tracks")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.55))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .frame(width: size.width, height: size.height)
            .scaleEffect(pressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: pressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in pressed = true }
                .onEnded { _ in pressed = false }
        )
    }
}

// MARK: - Track List for Genre
struct GenreTrackListView: View {
    let genre: MusicGenre

    var body: some View {
        ZStack {
            // Background matching genre
            LinearGradient(
                colors: [genre.gradient[0].opacity(0.25), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    GenreHeader(genre: genre)
                        .padding(.bottom, 8)

                    // Track list
                    LazyVStack(spacing: 12) {
                        ForEach(Array(genre.tracks.enumerated()), id: \.element.id) { index, track in
                            NavigationLink(destination: FocusView(selectedTrack: track, mood: genre.name)) {
                                TrackRow(track: track, index: index + 1, genre: genre)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle(genre.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Genre Header
struct GenreHeader: View {
    let genre: MusicGenre

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: genre.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: genre.gradient[0].opacity(0.5), radius: 20, y: 8)

                Image(systemName: genre.symbol)
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(.white)
            }

            VStack(spacing: 6) {
                Text(genre.name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(genre.tagline)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .tracking(1.5)
                    .textCase(.uppercase)
            }
        }
        .padding(.top, 24)
        .padding(.bottom, 16)
    }
}

// MARK: - Track Row
struct TrackRow: View {
    let track: Track
    let index: Int
    let genre: MusicGenre
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 16) {
            // Index
            Text(String(format: "%02d", index))
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(genre.gradient[1].opacity(0.8))
                .frame(width: 28)

            // Artwork placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(colors: genre.gradient.map { $0.opacity(0.4) },
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: genre.symbol)
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.9))
            }

            // Title & mood
            VStack(alignment: .leading, spacing: 4) {
                Text(track.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(genre.name)
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            // Play button
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: genre.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 36, height: 36)

                Image(systemName: "play.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .offset(x: 1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}

// MARK: - MusicCard (kept for backward compat if used elsewhere)
struct MusicCard: View {
    let track: Track
    let mood: String

    private func iconForMood(_ mood: String) -> String {
        switch mood {
        case "Focus": return "brain.head.profile"
        case "Calm": return "leaf.fill"
        case "Sleep": return "moon.stars.fill"
        default: return "bolt.fill"
        }
    }

    private func colorForMood(_ mood: String) -> Color {
        switch mood {
        case "Focus": return .blue
        case "Calm": return .green
        case "Sleep": return .purple
        default: return .orange
        }
    }

    var body: some View {
        HStack(spacing: 16) {
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
                    Image(systemName: "tag.fill").font(.system(size: 8))
                    Text(mood).font(.caption)
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
}

#Preview {
    NavigationStack {
        MusicListView(mood: "All")
    }
}
