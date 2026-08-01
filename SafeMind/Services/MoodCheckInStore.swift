//
//  MoodCheckInStore.swift
//  SafeMind
//
//  Part of the AI Mood Check-In feature.
//
//  Not in the original file list, but needed to satisfy the "only once per
//  day" persistence requirement without cramming storage logic into the
//  ViewModel. Kept tiny and UserDefaults-only for now.
//

import Foundation

/// Persists the day's check-in result and answers whether today's check-in
/// has already been completed.
///
/// Future extensibility: this is the seam to swap in a Supabase-backed store
/// (to sync `lastMoodAssessment` history across devices / power mood trends)
/// — `MoodCheckInViewModel` only ever talks to this struct's three methods.
struct MoodCheckInStore {

    private let defaults: UserDefaults
    private let dateKey = "moodCheckIn.lastAssessmentDate"
    private let assessmentKey = "moodCheckIn.lastMoodAssessment"
    private let recommendationKey = "moodCheckIn.recommendedActivity"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// True if a check-in was already completed at some point today.
    func hasCompletedToday() -> Bool {
        guard let lastDate = defaults.object(forKey: dateKey) as? Date else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }

    func saveTodaysResult(assessment: MoodAssessment, recommendation: MoodRecommendation) {
        defaults.set(Date(), forKey: dateKey)
        if let data = try? JSONEncoder().encode(assessment) {
            defaults.set(data, forKey: assessmentKey)
        }
        if let data = try? JSONEncoder().encode(recommendation) {
            defaults.set(data, forKey: recommendationKey)
        }
    }

    func lastAssessment() -> MoodAssessment? {
        guard let data = defaults.data(forKey: assessmentKey) else { return nil }
        return try? JSONDecoder().decode(MoodAssessment.self, from: data)
    }

    func lastRecommendation() -> MoodRecommendation? {
        guard let data = defaults.data(forKey: recommendationKey) else { return nil }
        return try? JSONDecoder().decode(MoodRecommendation.self, from: data)
    }
}
