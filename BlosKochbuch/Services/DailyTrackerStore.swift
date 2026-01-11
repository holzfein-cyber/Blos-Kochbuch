import Foundation

struct DailyEntry: Identifiable, Codable {
    var id = UUID()
    var title: String
    var calories: Int
    var proteinG: Int
    var carbsG: Int
    var fatG: Int
    var date: Date
}

final class DailyTrackerStore {
    static let shared = DailyTrackerStore()
    private init() {}

    private let key = "daily.tracker.entries.v1"
    private let goalKey = "daily.tracker.goalKcal.v1"

    var goalKcal: Int {
        get {
            let v = UserDefaults.standard.integer(forKey: goalKey)
            return v == 0 ? 2000 : v
        }
        set { UserDefaults.standard.set(newValue, forKey: goalKey) }
    }

    func loadEntries(for day: Date) -> [DailyEntry] {
        let all = loadAll()
        return all
            .filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
            .sorted(by: { $0.date > $1.date })
    }

    func add(_ entry: DailyEntry) {
        var all = loadAll()
        all.append(entry)
        saveAll(all)
    }

    func delete(_ entryId: UUID) {
        var all = loadAll()
        all.removeAll { $0.id == entryId }
        saveAll(all)
    }

    private func loadAll() -> [DailyEntry] {
        guard let data = UserDefaults.standard.data(forKey: key) else { return [] }
        return (try? JSONDecoder().decode([DailyEntry].self, from: data)) ?? []
    }

    private func saveAll(_ entries: [DailyEntry]) {
        let data = try? JSONEncoder().encode(entries)
        UserDefaults.standard.set(data, forKey: key)
    }
}
