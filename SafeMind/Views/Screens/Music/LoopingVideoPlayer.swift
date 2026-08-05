import SwiftUI
import AVFoundation

/// UIKit-backed view that seamlessly loops a muted video — used as the
/// animated cover behind the Now Playing screen.
///
/// Fix: this now downloads the video once via VideoCacheManager and plays
/// it from local disk instead of streaming it directly from the remote URL.
/// Streaming a large remote .mp4 in real time (especially in the Simulator,
/// which has no hardware video decode) was the cause of the lag/stutter.
///
/// Fix: the video now tracks the song's play/pause state (`shouldPlay`) —
/// previously it kept looping in the background even after the user tapped
/// pause on the song itself.
final class LoopingPlayerUIView: UIView {
    private var queuePlayer: AVQueuePlayer?
    private var playerLooper: AVPlayerLooper?
    private var playerLayer: AVPlayerLayer?
    private var currentRemoteURL: URL?
    private var loadTask: Task<Void, Never>?
    private var shouldPlay: Bool = true

    func load(remoteURL: URL, shouldPlay: Bool) {
        self.shouldPlay = shouldPlay

        guard remoteURL != currentRemoteURL else {
            setPlaying(shouldPlay)
            return
        }
        currentRemoteURL = remoteURL
        loadTask?.cancel()

        loadTask = Task { [weak self] in
            guard let self else { return }
            do {
                let localURL = try await VideoCacheManager.shared.localFile(for: remoteURL)
                guard !Task.isCancelled, self.currentRemoteURL == remoteURL else { return }
                await MainActor.run { self.configure(with: localURL) }
            } catch {
                // Offline / download failed — fall back to direct streaming
                // rather than showing nothing.
                guard !Task.isCancelled, self.currentRemoteURL == remoteURL else { return }
                await MainActor.run { self.configure(with: remoteURL) }
            }
        }
    }

    /// Updates play/pause without reloading or reconfiguring the player —
    /// called whenever only `shouldPlay` changes (e.g. the user hits pause).
    func setPlaying(_ playing: Bool) {
        shouldPlay = playing
        if playing {
            queuePlayer?.play()
        } else {
            queuePlayer?.pause()
        }
    }

    private func configure(with url: URL) {
        tearDown()

        let asset = AVURLAsset(url: url)
        let item = AVPlayerItem(asset: asset)
        item.preferredForwardBufferDuration = 2

        let player = AVQueuePlayer()
        player.isMuted = true
        player.actionAtItemEnd = .none
        // We're playing a fully-downloaded local file (or intentionally
        // falling back to streaming), so don't let the player hold off
        // waiting to "minimize stalling" — that extra caution was adding
        // visible startup delay/stutter for no benefit on a local file.
        player.automaticallyWaitsToMinimizeStalling = false

        let looper = AVPlayerLooper(player: player, templateItem: item)

        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = .resizeAspectFill
        layer.frame = bounds
        self.layer.addSublayer(layer)

        queuePlayer = player
        playerLooper = looper
        playerLayer = layer

        if shouldPlay {
            player.play()
        }
    }

    func pause() { queuePlayer?.pause() }
    func resume() { queuePlayer?.play() }

    override func layoutSubviews() {
        super.layoutSubviews()
        playerLayer?.frame = bounds
    }

    private func tearDown() {
        playerLayer?.removeFromSuperlayer()
        queuePlayer?.pause()
        playerLooper = nil
        queuePlayer = nil
        playerLayer = nil
    }

    deinit {
        loadTask?.cancel()
        tearDown()
    }
}

struct LoopingVideoPlayer: UIViewRepresentable {
    let url: URL
    /// Mirrors the song's play/pause state so the background video pauses
    /// exactly when the audio does.
    var isPlaying: Bool = true

    func makeUIView(context: Context) -> LoopingPlayerUIView {
        let view = LoopingPlayerUIView()
        view.load(remoteURL: url, shouldPlay: isPlaying)
        return view
    }

    func updateUIView(_ uiView: LoopingPlayerUIView, context: Context) {
        uiView.load(remoteURL: url, shouldPlay: isPlaying)
        uiView.setPlaying(isPlaying)
    }
}
