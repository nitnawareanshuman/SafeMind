import SwiftUI

struct MusicListView: View {
    /// Optional genre filter, e.g. "Focus", "Calm", "Sleep" — passed in from
    /// the AI mood recommendation flow. `nil` shows every song (used by the
    /// Home Quick Start "Music" card and Explore).
    var mood: String? = nil

    @StateObject private var viewModel = MusicViewModel()
    @State private var showPlayer = false

    private let columns = [GridItem(.adaptive(minimum: 150), spacing: 16)]

    /// Friendlier screen title than just echoing the raw genre string.
    private var displayTitle: String {
        switch mood {
        case "Focus": return "Focus Flow"
        case "Calm":  return "Calm Waves"
        case "Sleep": return "Sleep Sounds"
        case "Energy": return "Energy Boost"
        case .some(let other): return other
        case .none: return "Music"
        }
    }

    var body: some View {
        ZStack {
            BlurBackground()

            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(viewModel.songs) { song in
                        Button {
                            viewModel.play(song)
                            showPlayer = true
                        } label: {
                            SongCardView(
                                song: song,
                                isPlaying: viewModel.currentSong?.id == song.id && viewModel.isPlaying
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(displayTitle)
        .task { await viewModel.loadSongs(mood: mood) }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.songs.isEmpty {
                Text("No songs yet")
                    .foregroundColor(.secondary)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if viewModel.currentSong != nil {
                MiniPlayerBar(viewModel: viewModel) { showPlayer = true }
            }
        }
        .fullScreenCover(isPresented: $showPlayer) {
            NowPlayingView(viewModel: viewModel)
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

private struct SongCardView: View {
    let song: Song
    let isPlaying: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack(alignment: .bottomTrailing) {
                AsyncImage(url: song.coverImageURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    default:
                        Image(systemName: "music.note")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(height: 180)
                .frame(width: 180)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 18))

                if isPlaying {
                    Image(systemName: "waveform")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(.black.opacity(0.4), in: Circle())
                        .padding(8)
                }
            }

            Text(song.title)
                .font(.subheadline).fontWeight(.semibold)
                .lineLimit(1)
            if let artist = song.artist {
                Text(artist)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

private struct MiniPlayerBar: View {
    @ObservedObject var viewModel: MusicViewModel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                AsyncImage(url: viewModel.currentSong?.coverImageURL) { phase in
                    if case .success(let image) = phase {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle().fill(Color.gray.opacity(0.2))
                    }
                }
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.currentSong?.title ?? "")
                        .font(.subheadline).fontWeight(.semibold)
                        .lineLimit(1)
                    Text(viewModel.currentSong?.artist ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Button {
                    viewModel.togglePlayPause()
                } label: {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
            .padding(10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    MusicListView()
}
