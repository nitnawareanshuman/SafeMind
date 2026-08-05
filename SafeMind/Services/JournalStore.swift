//
//  JournalStore.swift
//  SafeMind
//
//  Part of the Journaling feature.
//
//  UserDefaults-only for now, matching `MoodHistoryStore` / `MoodCheckInStore`.
//  Future extensibility: swap for a Supabase-backed `journal_entries` table
//  to sync entries across devices.
//

import Foundation

struct JournalStore {

    private let defaults: UserDefaults
    private let entriesKey = "journal.entries"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// All entries, most recent first.
    func allEntries() -> [JournalEntry] {
        guard let data = defaults.data(forKey: entriesKey),
              let decoded = try? JSONDecoder().decode([JournalEntry].self, from: data) else {
            return []
        }
        return decoded.sorted { $0.date > $1.date }
    }

    /// Adds a new entry, or overwrites an existing one with the same id.
    @discardableResult
    func save(_ entry: JournalEntry) -> [JournalEntry] {
        var entries = allEntries()
        entries.removeAll { $0.id == entry.id }
        entries.append(entry)
        persist(entries)
        return allEntries()
    }

    @discardableResult
    func delete(_ entry: JournalEntry) -> [JournalEntry] {
        var entries = allEntries()
        entries.removeAll { $0.id == entry.id }
        persist(entries)
        return allEntries()
    }

    /// Entries logged on a given calendar day, most recent first.
    func entries(on date: Date) -> [JournalEntry] {
        let calendar = Calendar.current
        return allEntries().filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    /// All entries bucketed by calendar day, most recent day first, entries
    /// within a day most recent first.
    func entriesGroupedByDay() -> [(day: Date, entries: [JournalEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: allEntries()) { calendar.startOfDay(for: $0.date) }
        return grouped.keys.sorted(by: >).map { day in
            (day: day, entries: (grouped[day] ?? []).sorted { $0.date > $1.date })
        }
    }

    private func persist(_ entries: [JournalEntry]) {
        if let data = try? JSONEncoder().encode(entries) {
            defaults.set(data, forKey: entriesKey)
        }
    }
}
