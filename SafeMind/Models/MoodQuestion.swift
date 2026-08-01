//
//  MoodQuestion.swift
//  SafeMind
//
//  Part of the AI Mood Check-In feature.
//

import Foundation
import SwiftUI

/// A single multiple-choice question in the AI Mood Check-In flow.
///
/// `weight` says how strongly *this question* should count toward each of the
/// five wellness scores when `MoodAssessmentService` blends every answered
/// question together (e.g. the energy question should move the "energy" score
/// far more than it moves "focus"). `style` says which redesigned card layout
/// (`MoodQuestionStyle`) should render it.
struct MoodQuestion: Identifiable {
    let id = UUID()
    let text: String
    let options: [MoodOption]
    let weight: MoodImpact
    let style: MoodQuestionStyle

    init(text: String, options: [MoodOption], weight: MoodImpact, style: MoodQuestionStyle = .simpleList) {
        self.text = text
        self.options = options
        self.weight = weight
        self.style = style
    }
}

extension MoodQuestion {

    /// The questions asked during the daily check-in, in order.
    ///
    /// Future extensibility: this is the one place to swap in a dynamically
    /// generated (e.g. LLM-driven) question set — `MoodCheckInViewModel` only
    /// depends on `[MoodQuestion]`, never on this static bank directly.
    static let dailyCheckInQuestions: [MoodQuestion] = [

        // Q1 — overall feeling. Big emoji face + scrolling pill row.
        MoodQuestion(
            text: "How do you feel today?",
            options: [
                MoodOption(emoji: "😊", label: "Calm",        color: Color(hex: "#7FE0C9"), impact: .init(stress: 1,  energy: 6, focus: 7, calmness: 9, tension: 1)),
                MoodOption(emoji: "🙂", label: "Happy",       color: Color(hex: "#F3A6C8"), impact: .init(stress: 3,  energy: 6, focus: 6, calmness: 7, tension: 2)),
                MoodOption(emoji: "😟", label: "Sad",         color: Color(hex: "#8FB8E8"), impact: .init(stress: 6,  energy: 4, focus: 4, calmness: 3, tension: 5)),
                MoodOption(emoji: "😠", label: "Angry",       color: Color(hex: "#F0906B"), impact: .init(stress: 7,  energy: 5, focus: 3, calmness: 2, tension: 7)),
                MoodOption(emoji: "😣", label: "Overwhelmed", color: Color(hex: "#E88787"), impact: .init(stress: 10, energy: 3, focus: 2, calmness: 1, tension: 8)),
            ],
            weight: .init(stress: 3, energy: 1, focus: 1, calmness: 3, tension: 1),
            style: .emojiFace
        ),

        // Q2 — what's on their mind. Colorful 2x2 grid.
        MoodQuestion(
            text: "What's worrying you?",
            options: [
                MoodOption(emoji: "😴", label: "Sleepiness", color: Color(hex: "#7B6EF6"), impact: .init(stress: 4, energy: 1, focus: 2, calmness: 4, tension: 3)),
                MoodOption(emoji: "😢", label: "Sadness",    color: Color(hex: "#4E8FF5"), impact: .init(stress: 5, energy: 3, focus: 3, calmness: 3, tension: 4)),
                MoodOption(emoji: "😰", label: "Anxiety",    color: Color(hex: "#22C7D6"), impact: .init(stress: 8, energy: 4, focus: 3, calmness: 1, tension: 8)),
                MoodOption(emoji: "😫", label: "Stress",     color: Color(hex: "#FF8A5C"), impact: .init(stress: 9, energy: 4, focus: 2, calmness: 1, tension: 7)),
            ],
            weight: .init(stress: 3, energy: 1, focus: 1, calmness: 1, tension: 2),
            style: .colorGrid
        ),

        // Q3 — energy level. Vertical slider, top = highest energy.
        MoodQuestion(
            text: "How is your energy level?",
            options: [
                MoodOption(emoji: "⚡", label: "Very High", impact: .init(stress: 4, energy: 10, focus: 7, calmness: 5, tension: 3)),
                MoodOption(emoji: "🙂", label: "Normal",    impact: .init(stress: 3, energy: 7,  focus: 6, calmness: 6, tension: 2)),
                MoodOption(emoji: "😴", label: "Low",       impact: .init(stress: 4, energy: 3,  focus: 4, calmness: 5, tension: 3)),
                MoodOption(emoji: "🥱", label: "Exhausted", impact: .init(stress: 6, energy: 1,  focus: 2, calmness: 3, tension: 5)),
            ],
            weight: .init(stress: 1, energy: 3, focus: 1, calmness: 1, tension: 1),
            style: .verticalSlider
        ),

        // Q4 — focus. Mostly moves focus.
        MoodQuestion(
            text: "How well can you focus right now?",
            options: [
                MoodOption(label: "Excellent",     impact: .init(stress: 2, energy: 7, focus: 10, calmness: 7, tension: 2)),
                MoodOption(label: "Okay",          impact: .init(stress: 4, energy: 5, focus: 6,  calmness: 5, tension: 3)),
                MoodOption(label: "Poor",          impact: .init(stress: 6, energy: 4, focus: 3,  calmness: 4, tension: 5)),
                MoodOption(label: "I can't focus", impact: .init(stress: 8, energy: 3, focus: 1,  calmness: 2, tension: 6)),
            ],
            weight: .init(stress: 1, energy: 1, focus: 3, calmness: 1, tension: 1)
        ),

        // Q5 — physical tension. Mostly moves tension.
        MoodQuestion(
            text: "Have you felt physically tense today?",
            options: [
                MoodOption(label: "No",          impact: .init(stress: 2, energy: 6, focus: 6, calmness: 8, tension: 1)),
                MoodOption(label: "A little",    impact: .init(stress: 4, energy: 5, focus: 5, calmness: 6, tension: 4)),
                MoodOption(label: "Quite a lot", impact: .init(stress: 7, energy: 4, focus: 4, calmness: 3, tension: 7)),
                MoodOption(label: "Very tense",  impact: .init(stress: 9, energy: 3, focus: 3, calmness: 1, tension: 10)),
            ],
            weight: .init(stress: 2, energy: 1, focus: 1, calmness: 1, tension: 3)
        ),

        // Q6 — sleep. Moves energy, stress and focus together.
        MoodQuestion(
            text: "How has your sleep been?",
            options: [
                MoodOption(label: "Very good", impact: .init(stress: 2, energy: 9, focus: 8, calmness: 7, tension: 2)),
                MoodOption(label: "Okay",      impact: .init(stress: 4, energy: 6, focus: 6, calmness: 5, tension: 3)),
                MoodOption(label: "Poor",      impact: .init(stress: 6, energy: 3, focus: 4, calmness: 4, tension: 5)),
                MoodOption(label: "Very poor", impact: .init(stress: 8, energy: 1, focus: 2, calmness: 2, tension: 7)),
            ],
            weight: .init(stress: 2, energy: 2, focus: 2, calmness: 1, tension: 1)
        ),

        // Q7 — stated need. A light-touch signal across all five scores.
        MoodQuestion(
            text: "What would help you most right now?",
            options: [
                MoodOption(label: "Relax",        impact: .init(stress: 6, energy: 5, focus: 5, calmness: 3, tension: 6)),
                MoodOption(label: "Focus",        impact: .init(stress: 5, energy: 5, focus: 3, calmness: 5, tension: 4)),
                MoodOption(label: "Feel calmer",  impact: .init(stress: 7, energy: 5, focus: 4, calmness: 3, tension: 6)),
                MoodOption(label: "I don't know", impact: .init(stress: 5, energy: 5, focus: 5, calmness: 5, tension: 5)),
            ],
            weight: .init(stress: 1, energy: 1, focus: 1, calmness: 1, tension: 1)
        ),
    ]
}
