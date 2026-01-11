import SwiftUI

struct RecipeListView: View {

    let category: Category

    @State private var posts: [Post] = []
    @State private var loading = true
    @State private var errorMessage: String?

    // 3.1 ✅ Filter-States
    @State private var excludedAllergens: Set<Allergen> = []
    @State private var showFilter = false

    // 3.2 ✅ Gefilterte Posts
    private var filteredPosts: [Post] {
        posts.filter { post in
            for allergen in excludedAllergens {
                if AllergenDetector.contains(allergen, in: post) {
                    return false
                }
            }
            return true
        }
    }

    var body: some View {
        Group {
            if loading {
                ProgressView("Lade Rezepte…")
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
                // 3.4 ✅ List(posts) -> List(filteredPosts)
                List(filteredPosts) { post in
                    NavigationLink {
                        RecipeDetailView(post: post)
                    } label: {
                        HStack(spacing: 12) {
                            RecipeThumbView(post: post)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(RecipeCardBlocksParser.stripHtml(post.title.rendered))
                                    .lineLimit(2)
                                    .font(.body)

                                // Optional: kleine Anzeige, wie viele Filter aktiv sind
                                if !excludedAllergens.isEmpty {
                                    Text("Filter aktiv: \(excludedAllergens.count)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(category.name)

        // 3.3 ✅ Toolbar + Sheet
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showFilter = true
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                }
                .accessibilityLabel("Allergen-Filter")
            }
        }
        .sheet(isPresented: $showFilter) {
            AllergenFilterView(excludedAllergens: $excludedAllergens)
        }

        .task {
            await load()
        }
    }

    @MainActor
    private func load() async {
        loading = true
        errorMessage = nil

        do {
            posts = try await WordPressAPI.fetchPosts(categoryId: category.id)
        } catch {
            errorMessage = error.localizedDescription
        }

        loading = false
    }
}

// MARK: - Thumbnail View (Featured Image first, else first image from content)

private struct RecipeThumbView: View {
    let post: Post

    var body: some View {
        let urlString = featuredOrFirstContentImageURL(for: post)

        return Group {
            if let urlString, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.2))
                            ProgressView()
                        }
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.gray.opacity(0.2))
                            Image(systemName: "photo")
                                .imageScale(.large)
                                .foregroundStyle(.secondary)
                        }
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                    Image(systemName: "photo")
                        .imageScale(.large)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func featuredOrFirstContentImageURL(for post: Post) -> String? {
        // 1) Featured image via _embedded
        if let featured = post.featuredImageUrl, !featured.isEmpty {
            return featured
        }

        // 2) Fallback: first <img ... src="..."> from post content HTML
        let html = post.content.rendered
        let pattern = #"<img[^>]+src=["']([^"']+)["']"#
        guard let re = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { return nil }
        let ns = html as NSString
        let range = NSRange(location: 0, length: ns.length)

        if let match = re.firstMatch(in: html, range: range),
           match.numberOfRanges > 1 {
            let r = match.range(at: 1)
            if r.location != NSNotFound {
                return ns.substring(with: r)
            }
        }
        return nil
    }
}
