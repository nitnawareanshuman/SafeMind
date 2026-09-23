import SwiftUI

struct NowPlayingView: View {
    @ObservedObject var viewModel: MusicViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            backgroundLayer

            VStack {
                topBar
                Spacer()
                VStack {
                    songInfo
                    progressSlider
                    controls
                }
                .padding(.vertical, 24)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28))
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 24)
        }
    }

    // MARK: - Background

    @ViewBuilder
    private var backgroundLayer: some View {
        if let url = viewModel.currentSong?.backgroundVideoURL {
            // Pausing the song now also pauses this looping video instead of
            // letting it keep playing silently in the background.
            LoopingVideoPlayer(url: url, isPlaying: viewModel.isPlaying)
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.35).ignoresSafeArea())
        } else if let coverURL = viewModel.currentSong?.coverImageURL {
            AsyncImage(url: coverURL) { phase in
                if case .success(let image) = phase {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else {
                    BlurBackground()
                }
            }
            .ignoresSafeArea()
            .overlay(Color.black.opacity(0.45).ignoresSafeArea())
        } else {
            BlurBackground()
        }
    }

    // MARK: - Sections

    private var topBar: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.down")
                    .font(.title3)
                    .foregroundColor(.primary)
                    .padding(12)
                    .background(.ultraThinMaterial, in: Circle())
            }
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var songInfo: some View {
        VStack(spacing: 6) {
            Text(viewModel.currentSong?.title ?? "")
                .font(.title2).fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            if let artist = viewModel.currentSong?.artist {
                Text(artist)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 32)
    }

    private var progressSlider: some View {
        VStack(spacing: 4) {
            Slider(
                value: Binding(
                    get: { viewModel.progress },
                    set: { viewModel.seek(toFraction: $0) }
                )
            )
            .tint(.primary)

            HStack {
                Text(formatted(viewModel.elapsedSeconds))
                Spacer()
                Text(formatted(viewModel.durationSeconds))
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal, 32)
        .padding(.top, 28)
    }

    private var controls: some View {
        HStack(spacing: 40) {
            Button { viewModel.toggleLoop() } label: {
                Image(systemName: "repeat")
                    .font(.title3)
                    .foregroundColor(viewModel.isLooping ? .primary : .secondary)
            }
            Button { viewModel.playPrevious() } label: {
                Image(systemName: "backward.fill").font(.title2)
            }
            Button { viewModel.togglePlayPause() } label: {
                Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 60))
            }
            Button { viewModel.playNext() } label: {
                Image(systemName: "forward.fill").font(.title2)
            }
            // Symmetry spacer so the repeat icon on the left doesn't visually
            // unbalance the transport controls, which are otherwise centered.
            Image(systemName: "repeat")
                .font(.title3)
                .opacity(0)
        }
        .foregroundColor(.primary)
        .padding(.top, 20)
    }

    private func formatted(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "0:00" }
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
