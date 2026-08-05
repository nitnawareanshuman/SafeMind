//
//  Article.swift
//  SafeMind
//
//  Part of the Mindful Reads (Articles) feature.
//
//  A curated, short-form summary of a longer mental-wellness article —
//  content lives in the "articles" Supabase table, cover images in the
//  "article-covers" storage bucket (mirrors how `Song` uses "song-covers").
//

import Foundation

struct Article: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let coverImagePath: String?
    let durationMinutes: Int
    let contentSource: String?
    let sourceURL: String?
    let content: String
    let category: String?
    let sortOrder: Int?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id, title, content, category
        case coverImagePath = "cover_image_path"
        case durationMinutes = "duration_minutes"
        case contentSource = "content_source"
        case sourceURL = "source_url"
        case sortOrder = "sort_order"
        case createdAt = "created_at"
    }

    /// Public URL for the cover image in the "article-covers" bucket.
    var coverImageURL: URL? {
        guard let coverImagePath, !coverImagePath.isEmpty else { return nil }
        return SupabaseStorageHelper.publicURL(bucket: "article-covers", path: coverImagePath)
    }

    /// e.g. "3 min" — matches the reading-time label in the article header.
    var durationLabel: String { "\(durationMinutes) min" }

    /// e.g. "3 hrs ago" — matches the timestamp label in the article header.
    var relativeTimeLabel: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}
