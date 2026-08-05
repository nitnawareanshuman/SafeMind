//
//  MoodOption.swift
//  SafeMind
//
//  Part of the AI Mood Check-In feature.
//

import Foundation
import SwiftUI

/// Raw 0–10 contribution a single answer makes toward each of the five wellness
/// dimensions SafeMind tracks. These are blended with a question's `weight`
/// (see `MoodQuestion`) inside `MoodAssessmentService` to produce the final
/// `MoodAssessment`.
struct MoodImpact {
    let stress: Double
    let energy: Double
    let focus: Double
    let calmness: Double
    let tension: Double
}

/// A single selectable answer for a mood check-in question.
struct MoodOption: Identifiable, Hashable {
    let id = UUID()
    let emoji: String?
    let imageName: String?
    let label: String
    let impact: MoodImpact
    /// Accent color used by the redesigned check-in cards (emoji face circle,
    /// the "What's worrying you?" grid, selected pill fills, etc). Falls back
    /// to `.accentColor`-ish blue/purple when a question doesn't specify one.
    let color: Color?

    init(emoji: String? = nil, imageName: String? = nil, label: String, color: Color? = nil, impact: MoodImpact) {
        self.emoji = emoji
        self.imageName = imageName
        self.label = label
        self.color = color
        self.impact = impact
    }

    /// What the user sees on the option button — emoji + label if present, otherwise just the label.
    var displayText: String {
        if let imageName { return "\(imageName) \(label)" }
        return label
    }

    static func == (lhs: MoodOption, rhs: MoodOption) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
