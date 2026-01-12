import SwiftUI

struct DailyTrackerView: View {

    @State private var selectedDate: Date = Date()
    @State private var entries: [DailyEntry] = []
    @State private var showAddEntry = false
    @State private var goalKcal: Int = DailyTrackerStore.shared.goalKcal

    // MARK: - Berechnungen
    private var totalCalories: Int {
        entries.reduce(0) { $0 + $1.calories }
    }

    private var remainingCalories: Int {
        goalKcal - totalCalories
    }

    private var totalProtein: Int {
        entries.reduce(0) { $0 + $1.proteinG }
    }

    private var totalCarbs: Int {
        entries.reduce(0) { $0 + $1.carbsG }
    }

    private var totalFat: Int {
        entries.reduce(0) { $0 + $1.fatG }
    }

    // MARK: - View
    var body: some View {
        NavigationStack {
            List {

                // 📅 Datumsauswahl
                Section {
                    HStack {
                        Button {
                            changeDay(by: -1)
                        } label: {
                            Image(systemName: "chevron.left")
                        }

                        Spacer()

                        Text(selectedDate, style: .date)
                            .font(.headline)

                        Spacer()

                        Button {
                            changeDay(by: 1)
                        } label: {
                            Image(systemName: "chevron.right")
                        }
                    }
                }

                // 🎯 Tagesziel
                Section("Tagesziel") {
                    Stepper(
                        "Ziel: \(goalKcal) kcal",
                        value: $goalKcal,
                        in: 1200...4500,
                        step: 50
                    )
                }

                // 📊 Übersicht
                Section("Übersicht") {
                    infoRow(title: "Gegessen", value: "\(totalCalories) kcal")
                    infoRow(
                        title: remainingCalories >= 0 ? "Übrig" : "Drüber",
                        value: "\(abs(remainingCalories)) kcal",
                        highlight: remainingCalories < 0
                    )
                    infoRow(
                        title: "Makros",
                        value: "P \(totalProtein)g • KH \(totalCarbs)g • F \(totalFat)g",
                        secondary: true
                    )
                }

                // 📝 Einträge
                Section("Einträge") {
                    if entries.isEmpty {
                        Text("Noch keine Einträge.")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(entries) { entry in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.title)
                                    .font(.body)
                                    .bold()

                                Text("\(entry.calories) kcal • P \(entry.proteinG)g • KH \(entry.carbsG)g • F \(entry.fatG)g")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onDelete(perform: deleteEntry)
                    }
                }
            }
            .navigationTitle("Tagestrecker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showAddEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddEntry) {
                AddDailyEntryView(day: selectedDate) {
                    loadEntries()
                }
            }
            .onAppear {
                loadEntries()
            }
            .onChange(of: goalKcal) { newValue in
                DailyTrackerStore.shared.goalKcal = newValue
            }
        }
    }

    // MARK: - Helper Views
    private func infoRow(
        title: String,
        value: String,
        highlight: Bool = false,
        secondary: Bool = false
    ) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .fontWeight(secondary ? .regular : .bold)
                .foregroundColor(
                    highlight ? .red : secondary ? .secondary : .primary
                )
        }
    }

    // MARK: - Actions
    private func loadEntries() {
        entries = DailyTrackerStore.shared.loadEntries(for: selectedDate)
    }

    private func deleteEntry(at offsets: IndexSet) {
        for index in offsets {
            DailyTrackerStore.shared.delete(entries[index].id)
        }
        loadEntries()
    }

    private func changeDay(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: value, to: selectedDate) {
            selectedDate = newDate
            loadEntries()
        }
    }
}
