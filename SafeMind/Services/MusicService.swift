import Foundation
import Supabase

final class MusicService {
    static let shared = MusicService()
    private init() {}

    // `supabase` is the project's existing global client (see Supabase.swift).
    // `SupabaseManager.shared.client` doesn't exist anywhere in the project,
    // so this used to fail to compile.
    private let client = supabase

    func fetchSongs(genre: String? = nil) async throws -> [Song] {
        if let genre {
            let songs: [Song] = try await client
                .from("songs")
                .select()
                .eq("genre", value: genre)
                .order("sort_order", ascending: true)
                .execute()
                .value
            return songs
        } else {
            let songs: [Song] = try await client
                .from("songs")
                .select()
                .order("sort_order", ascending: true)
                .execute()
                .value
            return songs
        }
    }
}
