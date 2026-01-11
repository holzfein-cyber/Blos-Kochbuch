import Foundation

class WordPressAPI {

    static let baseURL = "https://blos-gesunde-rezepte.de/wp-json/wp/v2"

    // MARK: - Kategorien laden
    static func fetchCategories() async throws -> [Category] {
        let url = URL(
            string: "\(baseURL)/categories?per_page=100&hide_empty=true"
        )!
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Category].self, from: data)
    }

    // MARK: - Posts je Kategorie (max. 100 Rezepte)
    static func fetchPosts(categoryId: Int) async throws -> [Post] {
        let url = URL(
            string: "\(baseURL)/posts?categories=\(categoryId)&per_page=100&_embed=1"
        )!
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Post].self, from: data)
    }
}

