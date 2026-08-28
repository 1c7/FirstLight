import Foundation

// Mirrors the Flutter reference app's lib/daily_progress_store.dart:
// a dict of date-string (YYYY-MM-DD, local timezone) -> accumulated
// effective minutes for that day, persisted as one small local JSON
// blob. Purely local, no network calls, no telemetry -- matching the
// reference project's privacy stance (see its doc/0-项目背景.md).
final class DailyProgressStore {
    private let fileURL: URL

    init() {
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fm.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        let dir = appSupport.appendingPathComponent("FirstLight", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("daily_effective_minutes.json")
    }

    static func dateKey(_ date: Date, calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func loadAll() -> [String: Double] {
        guard let data = try? Data(contentsOf: fileURL) else { return [:] }
        guard let decoded = try? JSONDecoder().decode([String: Double].self, from: data) else { return [:] }
        return decoded
    }

    private func saveAll(_ all: [String: Double]) {
        guard let data = try? JSONEncoder().encode(all) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }

    /// Accumulated minutes for the given day. 0 if there's no record yet.
    func minutes(for date: Date) -> Double {
        let all = loadAll()
        return all[Self.dateKey(date)] ?? 0.0
    }

    /// Adds `delta` effective minutes to the given day's total and
    /// returns the new running total for that day.
    @discardableResult
    func addEffectiveMinutes(_ delta: Double, for date: Date) -> Double {
        var all = loadAll()
        let key = Self.dateKey(date)
        let updated = (all[key] ?? 0.0) + delta
        all[key] = updated
        saveAll(all)
        return updated
    }
}
