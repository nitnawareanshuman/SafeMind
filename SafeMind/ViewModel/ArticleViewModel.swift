//
//  ArticleViewModel.swift
//  SafeMind
//
//  Part of the Mindful Reads (Articles) feature.
//

import Foundation
import Combine

@MainActor
final class ArticleViewModel: ObservableObject {

    @Published var articles: [Article] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let service: ArticleService

    init(service: ArticleService = .shared) {
        self.service = service
    }

    func loadArticles() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            articles = try await service.fetchArticles()
        } catch {
            errorMessage = "Couldn't load articles. Please try again."
            articles = []
        }
    }
}
