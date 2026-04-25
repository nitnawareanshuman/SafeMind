//
//  AudioPlayerViewModel.swift
//  SafeMind
//

import Foundation
import AVFoundation
import Combine

class AudioPlayerViewModel: ObservableObject {

    private var player: AVPlayer?
    private var timeObserver: Any?

    @Published var currentTrack: String = "Focus Music"
    @Published var isPlaying = false

    func playTrack(track: Track) {
        guard let url = URL(string: track.url) else { return }
        
        // Stop any existing playback
        stop()
        
        player = AVPlayer(url: url)
        player?.play()
        
        currentTrack = track.title
        isPlaying = true
        
        // Add observer for track completion
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { [weak self] _ in
            self?.isPlaying = false
            self?.player?.seek(to: .zero)
        }
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func stop() {
        player?.pause()
        player?.seek(to: .zero)
        isPlaying = false
        
        // Remove notification observer
        NotificationCenter.default.removeObserver(self, name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)
    }
    
    deinit {
        stop()
    }
}

struct MusicLibrary {
    
    static let calm: [Track] = [
        Track(title: "Rain Calm", url: "https://freesound.org/people/1jmorrisoncafe291/sounds/161869/"),
        Track(title: "Ocean Waves", url: "https://freesound.org/people/YevgVerh/sounds/827530/")
    ]
    
    static let focus: [Track] = [
        Track(title: "Deep Focus", url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3"),
        Track(title: "Study Beats", url: "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3")
    ]
    
    static let sleep: [Track] = [
        Track(title: "Sleep Ambient", url: "https://freesound.org/people/DJScreechingPossum/sounds/611608/")
    ]
}
