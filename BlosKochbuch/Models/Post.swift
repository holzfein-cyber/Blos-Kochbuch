import Foundation

struct Post: Identifiable, Decodable {
    let id: Int
    let title: Rendered
    let content: Rendered
    let embedded: Embedded?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case embedded = "_embedded"
    }

    struct Rendered: Decodable {
        let rendered: String
    }

    struct Embedded: Decodable {
        let featuredMedia: [FeaturedMedia]?

        enum CodingKeys: String, CodingKey {
            case featuredMedia = "wp:featuredmedia"
        }
    }

    struct FeaturedMedia: Decodable {
        let sourceUrl: String?

        enum CodingKeys: String, CodingKey {
            case sourceUrl = "source_url"
        }
    }

    /// Bequemer Zugriff
    var featuredImageUrl: String? {
        embedded?.featuredMedia?.first?.sourceUrl
    }
}

