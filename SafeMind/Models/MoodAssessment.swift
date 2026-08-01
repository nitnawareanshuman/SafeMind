//
//  MoodAssessment.swift
//  SafeMind
//
//  Part of the AI Mood Check-In feature.
//

import Foundation

/// The final computed wellness snapshot from a completed check-in.
/// Every score is normalized to a 0–10 scale (higher = more of that quality).
struct MoodAssessment: Codable, Equatable {
    let stress: Double
    let energy: Double
    let focus: Double
    let calmness: Double
    let tension: Double

    init(stress: Double, energy: Double, focus: Double, calmness: Double, tension: Double) {
        self.stress = stress
        self.energy = energy
        self.focus = focus
        self.calmness = calmness
        self.tension = tension
    }
}
