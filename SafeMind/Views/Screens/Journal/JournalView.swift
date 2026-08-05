//
//  JournalView.swift
//  SafeMind
//
//  Part of the Journaling feature.
//
//  Shows the user's saved journal entries grouped by day, a mood trend
//  graph built from each day's mood, and a bottom button that pushes
//  `CreateJournalView` to add a new entry.
//

import SwiftUI
import Charts

struct JournalView: View {

    @StateObject private var vm = JournalViewModel()
    @State private var showCreateJournal = false
    @State private var entryPendingDelete: JournalEntry?

    var body: some View {
        ZStack {
            BlurBackground()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {

                        if vm.moodTrend.count >= 2 {
                            moodGraphCard
                        }

                        if vm.isEmpty {
                            emptyState
                        } else {
                            ForEach(vm.groupedEntries, id: \.day) { group in
                                daySection(day: group.day, entries: group.entries)
                            }
                        }

                        // Space so content doesn't sit under the bottom button.
                        Color.clear.frame(height: 8)
                    }
                    .padding()
                }

                bottomButton
            }
        }
        .navigationTitle("Journal")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { vm.load() }
        .navigationDestination(isPresented: $showCreateJournal) {
            CreateJournalView { mood, title, description, date in
                vm.addEntry(mood: mood, title: title, description: description, date: date)
            }
        }
        .alert("Delete this entry?", isPresented: Binding(
            get: { entryPendingDelete != nil },
            set: { if !$0 { entryPendingDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let entry = entryPendingDelete {
                    vm.delete(entry)
                }
                entryPendingDelete = nil
            }
            Button("Cancel", role: .cancel) { entryPendingDelete = nil }
        }
    }

    // MARK: - Mood graph

    private var moodGraphCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Mood Trend")
                .font(.headline)

            Chart(vm.moodTrend, id: \.date) { point in
                LineMark(
                    x: .value("Day", point.date, unit: .day),
                    y: .value("Mood", point.mood.score)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.purple)

                PointMark(
                    x: .value("Day", point.date, unit: .day),
                    y: .value("Mood", point.mood.score)
                )
                .foregroundStyle(point.mood.color)
                .symbolSize(80)
            }
            .chartYScale(domain: 1...5)
            .chartYAxis {
                AxisMarks(values: [1, 2, 3, 4, 5]) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let raw = value.as(Int.self), let mood = JournalMood.allCases.first(where: { $0.score == raw }) {
                            Text(mood.emoji)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                }
            }
            .frame(height: 180)
        }
        .padding()
        .cornerRadius(20)
    }

    // MARK: - Day sections

    private func daySection(day: Date, entries: [JournalEntry]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(dayLabel(for: day))
                .font(.headline)
                .padding(.leading, 4)

            ForEach(entries) { entry in
                journalCard(entry)
            }
        }
    }

    private func journalCard(_ entry: JournalEntry) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(entry.mood.emoji)
                .font(.system(size: 30))
                .frame(width: 44, height: 44)
                .background(entry.mood.color.opacity(0.3))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.title.isEmpty ? "Untitled" : entry.title)
                        .font(.body.weight(.semibold))
                    Spacer()
                    Text(entry.date, style: .time)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Text(entry.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .contextMenu {
            Button(role: .destructive) {
                entryPendingDelete = entry
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "book.closed")
                .font(.system(size: 40))
                .foregroundColor(.secondary)
            Text("No journal entries yet")
                .font(.headline)
            Text("Tap \"New Entry\" below to write your first one.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }

    // MARK: - Bottom button

    private var bottomButton: some View {
        GradientButton(title: "New Journal Entry", icon: "square.and.pencil") {
            showCreateJournal = true
        }
        .padding(.horizontal)
        .padding(.bottom, 12)
        .padding(.top, 8)
        .background(.ultraThinMaterial)
    }

    // MARK: - Helpers

    private func dayLabel(for day: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.day().month(.abbreviated).year())
    }
}

#Preview {
    NavigationStack {
        JournalView()
    }
}
