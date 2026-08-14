import Foundation
import Supabase
import Combine

@MainActor
final class ExploreViewModel: ObservableObject {
    @Published var items: [ExploreItem] = []
    @Published var errorMessage: String?

    func fetchContent(category: String) {
        Task {
            do {
                let client = supabase
                items = try await client.from("explore_items").select().eq("category", value: category).execute().value
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
