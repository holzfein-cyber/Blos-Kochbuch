import SwiftUI

struct RecipeDetailView: View {
    let post: Post
    @State private var persons: Int = 2

    private var parsed: ParsedRecipe {
        RecipeCardBlocksParser.parseFromPostContent(post.content.rendered)
    }

    private var scaledIngredients: [IngredientLine] {
        let base = max(parsed.servings, 1)
        let factor = Double(persons) / Double(base)

        return parsed.ingredients.map { ing in
            guard let a = ing.amount else { return ing }
            return IngredientLine(amount: a * factor, unit: ing.unit, name: ing.name)
        }
    }

    private func fmt(_ amount: Double) -> String {
        let rounded = (amount * 100).rounded() / 100
        if rounded == rounded.rounded() { return "\(Int(rounded))" }
        return "\(rounded)".replacingOccurrences(of: ".", with: ",")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                Text(RecipeCardBlocksParser.stripHtml(post.title.rendered))
                    .font(.title)
                    .bold()

                Stepper("Personen: \(persons)", value: $persons, in: 1...12)

                Divider()

                Text("Einkaufsliste").font(.headline)

                if scaledIngredients.isEmpty {
                    Text("Keine Zutaten gefunden.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(scaledIngredients) { ing in
                        let amountStr = ing.amount == nil ? "" : "\(fmt(ing.amount!)) "
                        let unitStr = ing.unit == nil ? "" : "\(ing.unit!) "
                        Text("• \(amountStr)\(unitStr)\(ing.name)")
                    }
                }

                Divider()

                Text("Zubereitung").font(.headline)

                if parsed.steps.isEmpty {
                    Text("Keine Schritte gefunden.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(parsed.steps.enumerated()), id: \.offset) { idx, step in
                        HStack(alignment: .top) {
                            Text("\(idx + 1).").bold()
                            Text(step)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Rezept")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            persons = max(parsed.servings, 2) // Startwert aus Rezept (hier 3)
        }
    }
}
