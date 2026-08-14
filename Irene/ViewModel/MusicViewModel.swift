//
//  MusicViewModel.swift
//  Irene
//
//  Drives the Supabase-backed Music feature (MusicListView, NowPlayingView,
//  MiniPlayerBar). This file was missing from the project, which meant the
//  new Music screens couldn't compile at all — every symbol below is
//  referenced by those views.
//

import Foundation
import AVFoundation
import Combine

@MainActor
final class MusicViewModel: ObservableObject {

    // MARK: - Published state

    @Published var songs: [Song] = []
    @Published var currentSong: Song?
    @Published var isPlaying = false
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var elapsedSeconds: Double = 0
    @Published var durationSeconds: Double = 0

    /// When true, the current song repeats itself on completion instead of
    /// advancing to the next track in `songs`.
    @Published var isLooping = false

    /// 0...1 fraction used by the NowPlayingView slider.
    var progress: Double {
        guard durationSeconds > 0 else { return 0 }
        return min(max(elapsedSeconds / durationSeconds, 0), 1)
    }

    // MARK: - Playback internals

    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var endObserver: NSObjectProtocol?
    private var mood: String?

    // MARK: - Loading songs

    /// Loads songs from Supabase, optionally filtered to a single genre/mood
    /// (e.g. "Focus", "Calm", "Sleep") so a mood recommendation or the Home
    /// quick-start card can jump straight into a themed playlist.
    func loadSongs(mood: String? = nil) async {
        self.mood = mood
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            songs = try await MusicService.shared.fetchSongs(genre: mood)
        } catch {
            errorMessage = "Couldn't load songs. Please try again."
            songs = []
        }
    }

    // MARK: - Transport controls

    func play(_ song: Song) {
        guard let url = song.audioURL else {
            errorMessage = "This track is missing an audio file."
            return
        }

        // Re-tapping the song that's already loaded just toggles play/pause
        // instead of restarting playback from zero.
        if currentSong?.id == song.id, player != nil {
            togglePlayPause()
            return
        }

        tearDownPlayer()

        currentSong = song
        durationSeconds = Double(song.durationSeconds ?? 0)
        elapsedSeconds = 0

        let item = AVPlayerItem(url: url)
        let newPlayer = AVPlayer(playerItem: item)
        player = newPlayer

        addTimeObserver(to: newPlayer)
        addEndObserver(for: item)

        // If duration wasn't supplied by Supabase, read it off the asset once loaded.
        if song.durationSeconds == nil {
            Task {
                if let loadedDuration = try? await item.asset.load(.duration) {
                    let seconds = CMTimeGetSeconds(loadedDuration)
                    if seconds.isFinite {
                        self.durationSeconds = seconds
                    }
                }
            }
        }

        newPlayer.play()
        isPlaying = true

        // Local source of truth for Streak/Activity — one entry per fresh
        // track start (pause/resume toggles above don't re-record).
        ActivityStore.shared.record(type: "music")
    }

    func togglePlayPause() {
        guard let player else { return }
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }

    func seek(toFraction fraction: Double) {
        guard let player, durationSeconds > 0 else { return }
        let target = fraction * durationSeconds
        let time = CMTime(seconds: target, preferredTimescale: 600)
        player.seek(to: time)
        elapsedSeconds = target
    }

    func playNext() {
        advance(by: 1)
    }

    func playPrevious() {
        advance(by: -1)
    }

    /// Flips loop mode for the current track. While looping, the song
    /// restarts itself on completion instead of advancing to the next one.
    func toggleLoop() {
        isLooping.toggle()
    }

    /// Restarts the current track from the beginning without tearing down
    /// and rebuilding the player (keeps playback gapless).
    private func replayCurrentSong() {
        guard let player else { return }
        player.seek(to: .zero)
        elapsedSeconds = 0
        player.play()
        isPlaying = true
    }

    private func advance(by offset: Int) {
        guard !songs.isEmpty, let currentSong,
              let currentIndex = songs.firstIndex(where: { $0.id == currentSong.id }) else { return }
        let newIndex = (currentIndex + offset + songs.count) % songs.count
        play(songs[newIndex])
    }

    // MARK: - Observers

    private func addTimeObserver(to player: AVPlayer) {
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self else { return }
            let seconds = CMTimeGetSeconds(time)
            if seconds.isFinite {
                self.elapsedSeconds = seconds
            }
        }
    }

    private func addEndObserver(for item: AVPlayerItem) {
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            if self.isLooping {
                self.replayCurrentSong()
            } else if self.songs.count > 1 {
                self.playNext()
            } else {
                self.isPlaying = false
                self.player?.seek(to: .zero)
                self.elapsedSeconds = 0
            }
        }
    }

    private func tearDownPlayer() {
        if let timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
        }
        timeObserverToken = nil

        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        endObserver = nil

        player?.pause()
        player = nil
    }

    deinit {
        if let timeObserverToken {
            player?.removeTimeObserver(timeObserverToken)
        }
        if let endObserver {
            NotificationCenter.default.removeObserver(endObserver)
        }
        player?.pause()
    }
}
