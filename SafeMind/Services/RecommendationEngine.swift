//
//  RecommendationEngine.swift
//  SafeMind
//
//  Part of the AI Mood Check-In feature.
//

import Foundation

/// Pure decision logic that maps a computed `MoodAssessment` to the single best
/// next activity in SafeMind. Rules are evaluated top-to-bottom — the first
/// match wins, mirroring a clinician's triage order (address acute stress /
/// tension first, then low energy or focus, then general low mood).
struct RecommendationEngine {

    func recommend(for assessment: MoodAssessment) -> MoodRecommendation {
        if assessment.stress >= 7 {
            return .breathing
        }
        if assessment.tension >= 7 {
            return .accupressure
        }
        if assessment.energy <= 2 {
            return .music(genre: "Sleep")
        }
        if assessment.energy <= 3 {
            return .music(genre: "Calm")
        }
        if assessment.focus <= 3 {
            return .music(genre: "Focus")
        }
        if assessment.stress >= 6 && assessment.focus <= 4 {
            return .cbt
        }
        return .home
    }
}
