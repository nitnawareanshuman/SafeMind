//
//  ActivityEntry.swift
//  Irene
//
//  Created by Anshuman Nitnaware on 05/08/26.
//


//
//  ActivityStore.swift
//  Irene
//
//  On-device record of everything the user does inside Irene — mood
//  check-ins, breathing/acupressure sessions, journaling — so the Activity
//  screen and the daily streak both work reliably offline, without waiting
//  on a Supabase round-trip. `ActivityLogger`/`ProfileManager` still write to
//  Supabase for cross-device sync where that's already wired up; this store
//  is the local source of truth the UI reads from.
//
//  UserDefaults-only, matching `MoodHistoryStore` / `MoodCheckInStore`.
//

import Foundation

struct ActivityEntry: Codable, Identifiable {
    let id: String
    /// "breathing", "acupressure", "journaling", "moodCheckIn", "music"
    let type: String
    let date: Date
    /// Seconds, when the activity has a meaningful duration.
    let duration: Int?

    init(id: String = UUID().uuidString, type: String, date: Date = .now, duration: Int? = nil) {
        self.id = id
        self.type = type
        self.date = date
        self.duration = duration
    }
}

final class ActivityStore {

    static let shared = ActivityStore()

    private let defaults: UserDefaults
    private let entriesKey = "activityStore.entries"
    private let maxEntries = 300

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - Recording

    func record(type: String, duration: Int? = nil, date: Date = .now) {
        var entries = allEntries()
        entries.append(ActivityEntry(type: type, date: date, duration: duration))
        entries.sort { $0.date < $1.date }
        if entries.count > maxEntries {
            entries = Array(entries.suffix(maxEntries))
        }
        save(entries)
    }

    // MARK: - Reading

    func allEntries() -> [ActivityEntry] {
        guard let data = defaults.data(forKey: entriesKey),
              let decoded = try? JSONDecoder().decode([ActivityEntry].self, from: data) else {
            return []
        }
        return decoded
    }

    /// Entries within the last `days` calendar days, inclusive of today, most recent first.
    func entries(lastDays days: Int) -> [ActivityEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let cutoff = calendar.date(byAdding: .day, value: -(days - 1), to: today) ?? today
        return allEntries()
            .filter { $0.date >= cutoff }
            .sorted { $0.date > $1.date }
    }

    /// Count of activities, grouped by type, optionally limited to the last N days.
    func counts(lastDays days: Int? = nil) -> [String: Int] {
        let source = days.map { entries(lastDays: $0) } ?? allEntries()
        return Dictionary(grouping: source, by: { $0.type }).mapValues { $0.count }
    }

    /// Total logged duration in seconds, optionally limited to the last N days.
    func totalDuration(lastDays days: Int? = nil) -> Int {
        let source = days.map { entries(lastDays: $0) } ?? allEntries()
        return source.compactMap { $0.duration }.reduce(0, +)
    }

    var totalActivities: Int { allEntries().count }

    // MARK: - Streak

    /// The distinct calendar days (as `DateComponents`) that have at least one activity.
    private var activeDayComponents: Set<DateComponents> {
        let calendar = Calendar.current
        let days = allEntries().map { calendar.dateComponents([.year, .month, .day], from: $0.date) }
        return Set(days)
    }

    /// Consecutive-day streak, ending today. Today is allowed to still be
    /// "empty" without breaking the streak (so it doesn't reset to 0 the
    /// instant midnight passes, before the user has opened the app) — it
    /// only breaks once a full calendar day is skipped entirely.
    var currentStreak: Int {
        let calendar = Calendar.current
        let days = activeDayComponents
        guard !days.isEmpty else { return 0 }

        var cursor = calendar.startOfDay(for: Date())
        if !days.contains(calendar.dateComponents([.year, .month, .day], from: cursor)) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
        }

        var streak = 0
        while days.contains(calendar.dateComponents([.year, .month, .day], from: cursor)) {
            streak += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = prev
        }
        return streak
    }

    /// The longest consecutive-day streak ever recorded.
    var longestStreak: Int {
        let calendar = Calendar.current
        let sortedDays = activeDayComponents.compactMap { calendar.date(from: $0) }.sorted()
        guard !sortedDays.isEmpty else { return 0 }

        var longest = 1
        var current = 1
        for i in 1..<sortedDays.count {
            let diff = calendar.dateComponents([.day], from: sortedDays[i - 1], to: sortedDays[i]).day ?? 0
            if diff == 1 {
                current += 1
            } else if diff > 1 {
                current = 1
            }
            longest = max(longest, current)
        }
        return max(longest, current)
    }

    /// True once any activity has been logged today — used to show
    /// "today's streak is secured" style messaging.
    var hasActivityToday: Bool {
        let calendar = Calendar.current
        return activeDayComponents.contains(calendar.dateComponents([.year, .month, .day], from: Date()))
    }

    /// Last 7 calendar days (oldest first), each flagged for whether it has
    /// an activity — drives the little week strip on the Streak screen.
    func last7DaysActivity() -> [(date: Date, active: Bool)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let days = activeDayComponents
        return (0..<7).reversed().compactMap { offset -> (Date, Bool)? in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let comps = calendar.dateComponents([.year, .month, .day], from: day)
            return (day, days.contains(comps))
        }
    }

    private func save(_ entries: [ActivityEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: entriesKey)
        }
    }
}

// MARK: - Display helpers

extension ActivityEntry {
    var displayTitle: String {
        switch type {
        case "breathing":   return "Breathing Session"
        case "acupressure": return "Acupressure"
        case "journaling":  return "Journal Entry"
        case "moodCheckIn": return "Mood Check-In"
        case "music":       return "Music Session"
        default:            return type.capitalized
        }
    }

    var icon: String {
        switch type {
        case "breathing":   return "wind"
        case "acupressure": return "hand.point.up.left"
        case "journaling":  return "book.fill"
        case "moodCheckIn": return "face.smiling"
        case "music":       return "headphones"
        default:            return "checkmark.circle"
        }
    }

    var colorHex: String {
        switch type {
        case "breathing":   return "#7FB2F0"
        case "acupressure": return "#F0A860"
        case "journaling":  return "#B58CE8"
        case "moodCheckIn": return "#7FE0C9"
        case "music":       return "#8FD17A"
        default:            return "#A0A0A0"
        }
    }
}
