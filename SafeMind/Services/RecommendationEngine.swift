//
//  RecommendationEngine.swift
//  SafeMind
//
//  Part of the AI Mood Check-In feature.
//

import Foundation


struct RecommendationEngine {

    func recommend(for assessment: MoodAssessment) -> MoodRecommendation {
        // 😰 Stressed / 😡 Angry-Frustrated with real physical tension —
        // an active exercise helps more than passive listening.
        if assessment.stress >= 7 && assessment.tension >= 6 {
            return .breathing
        }
        if assessment.tension >= 7 {
            return .accupressure
        }

        // 😰 Stressed / 😟 Anxious / 🤯 Overthinking / 😡 Angry-Frustrated /
        // 😫 Burned Out — slow, calming sounds lower physiological arousal.
        if assessment.stress >= 6 || assessment.tension >= 6 {
            return .music(genre: "Calm")
        }

        // 🌙 Bedtime — very low energy with no real stress reads as winding
        // down for sleep, not needing a pick-me-up.
        if assessment.energy <= 2 && assessment.stress <= 5 {
            return .music(genre: "Sleep")
        }

        // 😴 Tired / 🥱 Sleepy / 🚀 Unmotivated — needs alertness and drive,
        // not more calm.
        if assessment.energy <= 4 {
            return .music(genre: "Energy")
        }

        // 🧠 Working / Studying / 📚 Exam prep / 😊 Happy & Productive —
        // needs sustained concentration.
        if assessment.focus <= 4 {
            return .music(genre: "Focus")
        }

        // 😔 Sad, tangled thoughts — untangling by writing helps more than
        // listening.
        if assessment.stress >= 5 && assessment.focus <= 5 {
            return .journaling
        }

        // 😌 Relaxed — already in a peaceful state, keep it that way.
        if assessment.calmness >= 7 {
            return .music(genre: "Calm")
        }

        return .home
    }
}
