import SwiftUI

struct CategoryListView: View {

    @State private var categories: [Category] = []
    @State private var loading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Group {
                if loading {
                    ProgressView("Lade Kategorien…")
                } else if let errorMessage {
                    VStack(spacing: 12) {
                        Text("Fehler")
                            .font(.headline)
                        Text(errorMessage)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Neu laden") {
                            Task { await load() }
                        }
                    }
                    .padding()
                } else {
                    List(categories) { category in
                        NavigationLink(category.name) {
                            RecipeListView(category: category)
                        }
                    }
                }
            }
            .navigationTitle("Kategorien")
        }
        .task { await load() }
    }

    @MainActor
    private func load() async {
        loading = true
        errorMessage = nil
        do {
            categories = try await WordPressAPI.fetchCategories()
        } catch {
            errorMessage = error.localizedDescription
        }
        loading = false
    }
}
