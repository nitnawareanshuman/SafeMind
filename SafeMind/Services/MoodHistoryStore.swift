//
//  MoodHistoryStore.swift
//  SafeMind
//
//  Part of the Safe Circle feature.
//
//  `MoodCheckInStore` only ever keeps *today's* result. This store keeps a
//  short rolling history (one entry per calendar day) so we can answer
//  "has the user been stressed for the past few days?" — the trigger for the
//  Safe Circle stress alert.
//
//  UserDefaults-only for now; future extensibility: swap for a
//  Supabase-backed `mood_history` table to power real mood trend charts.
//

import Foundation

struct MoodHistoryEntry: Codable {
    let date: Date
    /// 0–10 stress score, same scale as `MoodAssessment.stress`.
    let stress: Double
}

struct MoodHistoryStore {

    /// A day counts as "stressed" once its score crosses this.
    private let stressThreshold: Double = 6.0
    /// Only look at the most recent N calendar days when checking the trend.
    private let lookbackDays = 4
    /// Need at least this many stressed days within the lookback window.
    private let minStressedDays = 3
    /// Keep a bit more than the lookback window so short history gaps don't
    /// break things, without growing UserDefaults unbounded.
    private let maxStoredEntries = 14

    private let defaults: UserDefaults
    private let historyKey = "moodHistory.entries"
    private let lastAlertShownKey = "moodHistory.lastStressAlertShownDate"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// Records (or overwrites) today's stress score. Safe to call multiple
    /// times a day — only the latest value for "today" is kept.
    func recordToday(stress: Double) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var entries = allEntries()
        entries.removeAll { calendar.isDate($0.date, inSameDayAs: today) }
        entries.append(MoodHistoryEntry(date: today, stress: stress))
        entries.sort { $0.date < $1.date }
        if entries.count > maxStoredEntries {
            entries = Array(entries.suffix(maxStoredEntries))
        }

        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: historyKey)
        }
    }

    func allEntries() -> [MoodHistoryEntry] {
        guard let data = defaults.data(forKey: historyKey),
              let decoded = try? JSONDecoder().decode([MoodHistoryEntry].self, from: data) else {
            return []
        }
        return decoded
    }

    /// True when at least `minStressedDays` of the last `lookbackDays`
    /// calendar days recorded a stress score at/above `stressThreshold` —
    /// i.e. "stressed for the past 3-4 days".
    func isRecentlyStressed() -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let recentEntries = allEntries().filter { entry in
            let daysAgo = calendar.dateComponents([.day], from: entry.date, to: today).day ?? Int.max
            return daysAgo >= 0 && daysAgo < lookbackDays
        }

        let stressedDays = recentEntries.filter { $0.stress >= stressThreshold }.count
        return stressedDays >= minStressedDays
    }

    /// The stress alert should nag at most once per day even if the app is
    /// reopened repeatedly — but it's allowed to resurface the next day if
    /// the trend is still there.
    func hasShownAlertToday() -> Bool {
        guard let lastDate = defaults.object(forKey: lastAlertShownKey) as? Date else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }

    func markAlertShownToday() {
        defaults.set(Date(), forKey: lastAlertShownKey)
    }
}
