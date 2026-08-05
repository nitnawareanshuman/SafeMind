//
//  ArticleService.swift
//  SafeMind
//
//  Part of the Mindful Reads (Articles) feature.
//

import Foundation
import Supabase

final class ArticleService {
    static let shared = ArticleService()
    private init() {}

    // `supabase` is the project's existing global client (see Supabase.swift).
    private let client = supabase

    /// All published articles, newest-first within manual sort order —
    /// mirrors `MusicService.fetchSongs`.
    func fetchArticles() async throws -> [Article] {
        try await client
            .from("articles")
            .select()
            .eq("is_published", value: true)
            .order("sort_order", ascending: true)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func fetchArticle(id: UUID) async throws -> Article {
        try await client
            .from("articles")
            .select()
            .eq("id", value: id)
            .single()
            .execute()
            .value
    }

    /// Logs a single reading session — how long the user spent on this
    /// article and whether they scrolled to the end. Call this when the
    /// user leaves `ArticleDetailView`.
    ///
    /// Best-effort: a failed write here should never interrupt reading, so
    /// errors are swallowed (logged) rather than surfaced to the UI. Skips
    /// silently if the session was under a second (e.g. an accidental tap)
    /// or if there's no signed-in user.
    func logRead(articleID: UUID, secondsRead: Int, completed: Bool) async {
        guard secondsRead >= 1, let userID = supabase.auth.currentUser?.id else { return }

        let record = ArticleReadRecord(
            userID: userID,
            articleID: articleID,
            secondsRead: secondsRead,
            completed: completed,
            readAt: Date()
        )

        do {
            try await client.from("article_reads").insert(record).execute()
        } catch {
            print("ArticleService.logRead failed: \(error)")
        }
    }

    /// Every calendar date the signed-in user has a logged read — the raw
    /// signal the future streak-completion feature will build on.
    func fetchReadDates(userID: UUID) async throws -> [Date] {
        struct Row: Decodable { let read_at: Date }
        let rows: [Row] = try await client
            .from("article_reads")
            .select("read_at")
            .eq("user_id", value: userID)
            .execute()
            .value
        return rows.map { $0.read_at }
    }
}
