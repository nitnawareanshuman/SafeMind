//
//  StreakView.swift
//  SafeMind
//
//  Shows the user's daily-activity streak, backed by `ActivityStore`
//  (on-device, UserDefaults — no network round-trip needed).
//

import SwiftUI

struct StreakView: View {

    private let store = ActivityStore.shared

    private var week: [(date: Date, active: Bool)] { store.last7DaysActivity() }

    var body: some View {
        ZStack {
            BlurBackground()

            ScrollView {
                VStack(spacing: 20) {
                    streakHeader
                    weekStrip
                    statsRow
                }
                .padding()
            }
        }
        .navigationTitle("Streak")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var streakHeader: some View {
        VStack(spacing: 8) {
            Image(systemName: "flame.fill")
                .font(.system(size: 44))
                .foregroundColor(.orange)

            Text("\(store.currentStreak) day\(store.currentStreak == 1 ? "" : "s")")
                .font(.system(size: 34, weight: .bold))

            Text(store.hasActivityToday
                 ? "Nice — today is already secured 🔥"
                 : "Do something mindful today to keep it alive")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }

    // MARK: - Week strip

    private var weekStrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Week")
                .font(.headline)

            HStack(spacing: 10) {
                ForEach(week, id: \.date) { day in
                    VStack(spacing: 8) {
                        Text(weekdayLabel(day.date))
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Circle()
                            .fill(day.active ? Color.orange : Color(.systemGray5))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: day.active ? "flame.fill" : "")
                                    .font(.caption2)
                                    .foregroundColor(.white)
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 14) {
            statCard(title: "Longest Streak", value: "\(store.longestStreak)", icon: "trophy.fill", color: .yellow)
            statCard(title: "Total Sessions", value: "\(store.totalActivities)", icon: "checkmark.seal.fill", color: .blue)
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(value)
                .font(.title2.bold())
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    private func weekdayLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date).prefix(1).uppercased()
    }
}

#Preview {
    NavigationStack { StreakView() }
}
