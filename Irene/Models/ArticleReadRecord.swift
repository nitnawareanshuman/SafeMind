//
//  ArticleReadRecord.swift
//  Irene
//
//  Part of the Mindful Reads (Articles) feature.
//
//  One row per reading session, written to the "article_reads" table.
//  Kept append-only (not upserted per-article) so the future streak
//  feature can count distinct calendar days the user read something,
//  not just the last time they opened each article.
//

import Foundation

struct ArticleReadRecord: Codable {
    let userID: UUID
    let articleID: UUID
    let secondsRead: Int
    /// True once the user scrolled to the end of the article.
    let completed: Bool
    let readAt: Date

    enum CodingKeys: String, CodingKey {
        case userID = "user_id"
        case articleID = "article_id"
        case secondsRead = "seconds_read"
        case completed
        case readAt = "read_at"
    }
}
