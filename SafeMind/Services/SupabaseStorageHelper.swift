import Foundation
import Supabase

/// Builds public Storage URLs for the "song-audio" / "song-covers" buckets
/// using the project's existing Supabase client (see Supabase.swift), so
/// there's a single source of truth for the project URL.
enum SupabaseStorageHelper {

    static func publicURL(bucket: String, path: String) -> URL? {
        guard !path.isEmpty else { return nil }
        return try? supabase.storage.from(bucket).getPublicURL(path: path)
    }
}
