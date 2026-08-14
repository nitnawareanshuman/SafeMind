//
//  JournalViewModel.swift
//  Irene
//
//  Part of the Journaling feature.
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class JournalViewModel: ObservableObject {

    /// All entries bucketed by calendar day, most recent day first.
    @Published private(set) var groupedEntries: [(day: Date, entries: [JournalEntry])] = []

    private let store = JournalStore()

    init() {
        load()
    }

    func load() {
        groupedEntries = store.entriesGroupedByDay()
    }

    func addEntry(mood: JournalMood, title: String, description: String, date: Date) {
        let entry = JournalEntry(date: date, mood: mood, title: title, description: description)
        store.save(entry)
        load()
        ActivityStore.shared.record(type: "journaling", date: date)
    }

    func delete(_ entry: JournalEntry) {
        store.delete(entry)
        load()
    }

    var isEmpty: Bool { groupedEntries.isEmpty }

    /// Up to the last 14 calendar days that have an entry, oldest first —
    /// used to plot the mood trend graph. When a day has multiple entries,
    /// the most recently written one represents that day.
    var moodTrend: [(date: Date, mood: JournalMood)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let cutoff = calendar.date(byAdding: .day, value: -13, to: today) ?? today

        return groupedEntries
            .filter { $0.day >= cutoff }
            .compactMap { group -> (date: Date, mood: JournalMood)? in
                guard let latest = group.entries.first else { return nil }
                return (group.day, latest.mood)
            }
            .sorted { $0.date < $1.date }
    }
}
