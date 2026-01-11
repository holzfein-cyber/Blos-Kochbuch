import Foundation

enum Allergen: String, CaseIterable, Identifiable {
    case gluten = "Gluten"
    case laktose = "Laktose"
    case nuesse = "Nüsse"
    case ei = "Ei"
    case soja = "Soja"
    case fisch = "Fisch"
    case sellerie = "Sellerie"
    case senf = "Senf"
    case sesam = "Sesam"

    var id: String { rawValue }
}

struct AllergenDetector {

    static let keywords: [Allergen: [String]] = [
        .gluten: ["weizen", "mehl", "nudeln", "pasta", "dinkel", "roggen", "gerste", "seitan"],
        .laktose: ["milch", "käse", "butter", "sahne", "joghurt", "frischkäse"],
        .nuesse: ["mandel", "haselnuss", "walnuss", "cashew", "pistazie", "erdnuss"],
        .ei: ["ei", "eier", "eigelb", "eiweiß"],
        .soja: ["soja", "sojasauce", "tofu"],
        .fisch: ["fisch", "lachs", "thunfisch", "forelle"],
        .sellerie: ["sellerie"],
        .senf: ["senf"],
        .sesam: ["sesam"]
    ]

    static func contains(_ allergen: Allergen, in post: Post) -> Bool {
        let text = RecipeCardBlocksParser
            .stripHtml(post.content.rendered)
            .lowercased()

        return keywords[allergen]?.contains(where: { text.contains($0) }) ?? false
    }
}
