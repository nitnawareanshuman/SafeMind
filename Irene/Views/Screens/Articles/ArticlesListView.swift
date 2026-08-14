//
//  ArticlesListView.swift
//  Irene
//
//  Part of the Mindful Reads (Articles) feature.
//  Lists every published article; tapping one pushes ArticleDetailView.
//

import SwiftUI

struct ArticlesListView: View {

    @StateObject private var viewModel = ArticleViewModel()

    var body: some View {
        ZStack {
            BlurBackground()

            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.articles) { article in
                        NavigationLink {
                            ArticleDetailView(article: article)
                        } label: {
                            ArticleRowCard(article: article)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Mindful Reads")
        .task { await viewModel.loadArticles() }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            } else if viewModel.articles.isEmpty {
                Text("No articles yet")
                    .foregroundColor(.secondary)
            }
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

private struct ArticleRowCard: View {
    let article: Article

    var body: some View {
        HStack(spacing: 14) {
            AsyncImage(url: article.coverImageURL) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fill)
                case .empty:
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                default:
                    Image(systemName: "text.book.closed")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 88, height: 88)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .background(Color.gray.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 6) {
                Text(article.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let source = article.contentSource, !source.isEmpty {
                    Text(source)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

#Preview {
    NavigationStack {
        ArticlesListView()
    }
}
