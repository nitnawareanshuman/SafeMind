//
//  ActivityView.swift
//  SafeMind
//
//  Shows everything the user has done inside SafeMind — mood check-ins,
//  breathing/acupressure sessions, journaling, music — grouped by day.
//  Backed by `ActivityStore` (on-device, no network round-trip needed).
//

import SwiftUI

struct ActivityView: View {

    private let store = ActivityStore.shared

    private var groupedByDay: [(day: Date, entries: [ActivityEntry])] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: store.allEntries()) { calendar.startOfDay(for: $0.date) }
        return grouped.keys.sorted(by: >).map { day in
            (day: day, entries: (grouped[day] ?? []).sorted { $0.date > $1.date })
        }
    }

    var body: some View {
        ZStack {
            BlurBackground()

            if store.totalActivities == 0 {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        summaryRow
                        ForEach(groupedByDay, id: \.day) { group in
                            daySection(day: group.day, entries: group.entries)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Summary

    private var summaryRow: some View {
        HStack(spacing: 14) {
            summaryCard(title: "This Week", value: "\(store.entries(lastDays: 7).count)")
            summaryCard(title: "All Time", value: "\(store.totalActivities)")
        }
    }

    private func summaryCard(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    // MARK: - Day section

    private func daySection(day: Date, entries: [ActivityEntry]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(dayLabel(day))
                .font(.headline)
                .padding(.leading, 4)

            VStack(spacing: 10) {
                ForEach(entries) { entry in
                    activityRow(entry)
                }
            }
        }
    }

    private func activityRow(_ entry: ActivityEntry) -> some View {
        HStack(spacing: 14) {
            Image(systemName: entry.icon)
                .foregroundColor(Color(hex: entry.colorHex))
                .frame(width: 34, height: 34)
                .background(Color(hex: entry.colorHex).opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.displayTitle)
                    .font(.subheadline.weight(.semibold))
                Text(timeLabel(entry.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if let duration = entry.duration, duration > 0 {
                Text(durationLabel(duration))
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No activity yet")
                .font(.headline)
            Text("Try a breathing session or mood check-in to get started.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }

    // MARK: - Formatting

    private func dayLabel(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Today" }
        if Calendar.current.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        return f.string(from: date)
    }

    private func timeLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.timeStyle = .short
        return f.string(from: date)
    }

    private func durationLabel(_ seconds: Int) -> String {
        if seconds < 60 { return "\(seconds)s" }
        return "\(seconds / 60)m"
    }
}

#Preview {
    NavigationStack { ActivityView() }
}
