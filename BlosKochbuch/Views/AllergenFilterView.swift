import SwiftUI

struct AllergenFilterView: View {

    @Binding var excludedAllergens: Set<Allergen>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Allergene ausschließen") {
                    ForEach(Allergen.allCases) { allergen in
                        Toggle(allergen.rawValue, isOn: binding(for: allergen))
                    }
                }

                Section {
                    Button("Alle Filter zurücksetzen", role: .destructive) {
                        excludedAllergens.removeAll()
                    }
                }

                Section {
                    Text("⚠️ Allergene werden automatisch aus Zutaten/Text erkannt. Keine Garantie auf Vollständigkeit.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Filter")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }

    // ✅ Typechecker-freundlich: Binding ausgelagert
    private func binding(for allergen: Allergen) -> Binding<Bool> {
        Binding<Bool>(
            get: { excludedAllergens.contains(allergen) },
            set: { isOn in
                if isOn {
                    excludedAllergens.insert(allergen)
                } else {
                    excludedAllergens.remove(allergen)
                }
            }
        )
    }
}
    
