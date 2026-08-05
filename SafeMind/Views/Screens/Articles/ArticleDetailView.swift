//
//  ArticleDetailView.swift
//  SafeMind
//
//  Part of the Mindful Reads (Articles) feature.
//
//  Uses the same BlurBackground + ultraThinMaterial card language, standard
//  navigation bar, and adaptive (light/dark) text colors as ArticlesListView
//  and the rest of the app, so pushing into an article doesn't feel like a
//  different screen style — just a continuation of the same one.
//
//  Tracks how long the user spends on screen and whether they scrolled to
//  the end, then logs that as one `article_reads` row on the way out —
//  the raw signal the future streak-completion feature will read.
//

import SwiftUI

struct ArticleDetailView: View {
    let article: Article

    @State private var startTime = Date()
    @State private var reachedEnd = false

    var body: some View {
        ZStack {
            BlurBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    coverImage

                    VStack(alignment: .leading, spacing: 16) {
                        Text(article.title)
                            .font(.title2.bold())
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(article.content)
                            .font(.body)
                            .lineSpacing(6)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)

                    // Invisible sentinel — reaching it means the user scrolled
                    // through the whole article.
                    Color.clear
                        .frame(height: 1)
                        .onAppear { reachedEnd = true }
                }
                .padding()
            }
        }
        .navigationTitle(article.category ?? "Mindful Reads")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { startTime = Date() }
        .onDisappear { logReadingSession() }
    }

    // MARK: - Sections

    private var coverImage: some View {
        AsyncImage(url: article.coverImageURL) { phase in
            switch phase {
            case .success(let image):
                image.resizable().aspectRatio(contentMode: .fill)
            case .empty:
                ProgressView()
                    .frame(maxWidth: .infinity)
            default:
                Color.clear
            }
        }
        .frame(height: 220)
        .frame(maxWidth: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Read tracking

    private func logReadingSession() {
        let seconds = Int(Date().timeIntervalSince(startTime))
        let completed = reachedEnd
        Task {
            await ArticleService.shared.logRead(articleID: article.id, secondsRead: seconds, completed: completed)
        }
    }
}

#Preview {
    NavigationStack {
        ArticleDetailView(
            article: Article(
                id: UUID(),
                title: "Kyoto Named World's Best City by Travel + Leisure Magazine",
                coverImagePath: nil,
                durationMinutes: 3,
                contentSource: "NHK Japan",
                sourceURL: nil,
                content: "Kyoto, Japan has been named the world's best city by Travel + Leisure magazine in its 2022 World's Best Awards. The award is based on a survey of the magazine's readers, who rate cities based on...",
                category: "Mindfulness",
                sortOrder: 0,
                createdAt: Date()
            )
        )
    }
}
