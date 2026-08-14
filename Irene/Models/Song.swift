import Foundation

struct Song: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let artist: String?
    let audioPath: String
    let coverImagePath: String?
    let pexelsVideoUrl: String?
    let durationSeconds: Int?
    let sortOrder: Int?
    let genre: String?

    enum CodingKeys: String, CodingKey {
        case id, title, artist, genre
        case audioPath = "audio_path"
        case coverImagePath = "cover_image_path"
        case pexelsVideoUrl = "pexels_video_url"
        case durationSeconds = "duration_seconds"
        case sortOrder = "sort_order"
    }

    /// Public URL for the audio file in the "song-audio" bucket
    var audioURL: URL? {
        SupabaseStorageHelper.publicURL(bucket: "song-audio", path: audioPath)
    }

    /// Public URL for the cover image in the "song-covers" bucket
    var coverImageURL: URL? {
        guard let coverImagePath, !coverImagePath.isEmpty else { return nil }
        return SupabaseStorageHelper.publicURL(bucket: "song-covers", path: coverImagePath)
    }

    /// Direct Pexels mp4 URL used as a looping background while this song plays
    var backgroundVideoURL: URL? {
        guard let pexelsVideoUrl, let url = URL(string: pexelsVideoUrl) else { return nil }
        return url
    }
}
