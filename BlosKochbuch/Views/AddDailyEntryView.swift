import SwiftUI

struct AddDailyEntryView: View {

    let day: Date
    let onAdded: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var title: String = ""
    @State private var kcal: Int = 0
    @State private var p: Int = 0
    @State private var c: Int = 0
    @State private var f: Int = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("Eintrag") {
                    TextField("Name (z.B. Frühstück / Snack)", text: $title)
                    Stepper("Kalorien: \(kcal) kcal", value: $kcal, in: 0...5000, step: 10)
                }

                Section("Makros (optional)") {
                    Stepper("Protein: \(p) g", value: $p, in: 0...300, step: 1)
                    Stepper("Kohlenhydrate: \(c) g", value: $c, in: 0...600, step: 1)
                    Stepper("Fett: \(f) g", value: $f, in: 0...300, step: 1)
                }

                Section {
                    Text("Tipp: Makros sind optional. Du kannst auch nur Kalorien tracken.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Hinzufügen")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") {
                        let entry = DailyEntry(
                            title: title.isEmpty ? "Eintrag" : title,
                            calories: kcal,
                            proteinG: p,
                            carbsG: c,
                            fatG: f,
                            date: day
                        )
                        DailyTrackerStore.shared.add(entry)
                        onAdded()
                        dismiss()
                    }
                    .disabled(title.isEmpty && kcal == 0)
                }
            }
        }
    }
}
