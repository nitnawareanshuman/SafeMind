//
//  MoodQuestion.swift
//  Irene
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
                MoodOption(imageName: "calm_face", label: "Calm",        color: Color(hex: "#6FE3C2"), impact: .init(stress: 1,  energy: 6, focus: 7, calmness: 9, tension: 1)),
                MoodOption(imageName: "happy_face", label: "Happy",       color: Color(hex: "#F3A6C8"), impact: .init(stress: 3,  energy: 6, focus: 6, calmness: 7, tension: 2)),
                MoodOption(imageName: "sad_face", label: "Sad",         color: Color(hex: "#7BA7F8"), impact: .init(stress: 6,  energy: 4, focus: 4, calmness: 3, tension: 5)),
                MoodOption(imageName: "angry_face", label: "Angry",       color: Color(hex: "#F79A5B"), impact: .init(stress: 7,  energy: 5, focus: 3, calmness: 2, tension: 7)),
                MoodOption(imageName: "overwhelmed_face", label: "Overwhelmed", color: Color(hex: "#E45A5A"), impact: .init(stress: 10, energy: 3, focus: 2, calmness: 1, tension: 8)),
            ],
            weight: .init(stress: 3, energy: 1, focus: 1, calmness: 3, tension: 1),
            style: .emojiFace
        ),

        // Q2 — what's on their mind. Colorful 2x2 grid.
        MoodQuestion(
            text: "What's worrying you?",
            options: [
                MoodOption(imageName: "sleepy", label: "Sleepiness", color: Color(hex: "#8A7CF3"), impact: .init(stress: 4, energy: 1, focus: 2, calmness: 4, tension: 3)),
                MoodOption(imageName: "sad", label: "Sadness",    color: Color(hex: "#63B6F5"), impact: .init(stress: 5, energy: 3, focus: 3, calmness: 3, tension: 4)),
                MoodOption(imageName: "anxity", label: "Anxiety",    color: Color(hex: "#FFD54A"), impact: .init(stress: 8, energy: 4, focus: 3, calmness: 1, tension: 8)),
                MoodOption(imageName: "stress", label: "Stress",     color: Color(hex: "#F36C6C"), impact: .init(stress: 9, energy: 4, focus: 2, calmness: 1, tension: 7)),
            ],
            weight: .init(stress: 3, energy: 1, focus: 1, calmness: 1, tension: 2),
            style: .colorGrid
        ),

        // Q3 — energy level. Vertical slider, top = highest energy.
        MoodQuestion(
            text: "How is your energy level?",
            options: [
                MoodOption(emoji: "⚡", label: "Very High", color: Color(hex: "#FFD54A"), impact: .init(stress: 4, energy: 10, focus: 7, calmness: 5, tension: 3)),
                MoodOption(emoji: "🙂", label: "Normal", color: Color(hex: "#6FD08C"), impact: .init(stress: 3, energy: 7, focus: 6, calmness: 6, tension: 2)),
                MoodOption(emoji: "😴", label: "Low", color: Color(hex: "#7BA7F8"), impact: .init(stress: 4, energy: 3, focus: 4, calmness: 5, tension: 3)),
                MoodOption(emoji: "🥱", label: "Exhausted", color: Color(hex: "#8A7CF3"), impact: .init(stress: 6, energy: 1, focus: 2, calmness: 3, tension: 5)),
            ],
            weight: .init(stress: 1, energy: 3, focus: 1, calmness: 1, tension: 1),
            style: .verticalSlider
        ),

        // Q4 — focus. Mostly moves focus.
        MoodQuestion(
            text: "How well can you focus right now?",
            options: [
                MoodOption(imageName: "excellent", label: "Excellent", color: Color(hex: "#43C47A"), impact: .init(stress: 2, energy: 7, focus: 10, calmness: 7, tension: 2)),
                MoodOption(imageName: "okay", label: "Okay", color: Color(hex: "#63B6F5"), impact: .init(stress: 4, energy: 5, focus: 6, calmness: 5, tension: 3)),
                MoodOption(imageName: "sad_focus", label: "Poor", color: Color(hex: "#FFB15A"), impact: .init(stress: 6, energy: 4, focus: 3, calmness: 4, tension: 5)),
                MoodOption(imageName: "can't_focus", label: "I can't focus", color: Color(hex: "#F36C6C"), impact: .init(stress: 8, energy: 3, focus: 1, calmness: 2, tension: 6)),
            ],
            weight: .init(stress: 1, energy: 1, focus: 3, calmness: 1, tension: 1)
        ),

        // Q5 — physical tension. Mostly moves tension.
        MoodQuestion(
            text: "Have you felt physically tense today?",
            options: [
                MoodOption(imageName: "no", label: "No", color: Color(hex: "#6FE3C2"), impact: .init(stress: 2, energy: 6, focus: 6, calmness: 8, tension: 1)),
                MoodOption(imageName: "a_little", label: "A little", color: Color(hex: "#F8D96B"), impact: .init(stress: 4, energy: 5, focus: 5, calmness: 6, tension: 4)),
                MoodOption(imageName: "a_lot", label: "Quite a lot", color: Color(hex: "#F79A5B"), impact: .init(stress: 7, energy: 4, focus: 4, calmness: 3, tension: 7)),
                MoodOption(imageName: "very", label: "Very tense", color: Color(hex: "#E45A5A"), impact: .init(stress: 9, energy: 3, focus: 3, calmness: 1, tension: 10)),
            ],
            weight: .init(stress: 2, energy: 1, focus: 1, calmness: 1, tension: 3)
        ),

        // Q6 — sleep. Moves energy, stress and focus together.
        MoodQuestion(
            text: "How has your sleep been?",
            options: [
                MoodOption(imageName: "very_good_sleep", label: "Very good", color: Color(hex: "#74E1B5"), impact: .init(stress: 2, energy: 9, focus: 8, calmness: 7, tension: 2)),
                MoodOption(imageName: "okay_sleep", label: "Okay", color: Color(hex: "#7CB9F8"), impact: .init(stress: 4, energy: 6, focus: 6, calmness: 5, tension: 3)),
                MoodOption(imageName: "poor_sleep", label: "Poor", color: Color(hex: "#A98AF8"), impact: .init(stress: 6, energy: 3, focus: 4, calmness: 4, tension: 5)),
                MoodOption(imageName: "very_poor_sleep", label: "Very poor", color: Color(hex: "#7263D8"), impact: .init(stress: 8, energy: 1, focus: 2, calmness: 2, tension: 7)),
            ],
            weight: .init(stress: 2, energy: 2, focus: 2, calmness: 1, tension: 1)
        ),

        // Q7 — stated need. A light-touch signal across all five scores.
        MoodQuestion(
            text: "What would help you most right now?",
            options: [
                MoodOption(
                    imageName: "relax",
                    label: "Relax",
                    color: Color(hex: "#6FD08C"),
                    impact: .init(stress: 6, energy: 5, focus: 5, calmness: 3, tension: 6)
                ),
                MoodOption(
                    imageName: "focus",
                    label: "Focus",
                    color: Color(hex: "#63B6F5"),
                    impact: .init(stress: 5, energy: 5, focus: 3, calmness: 5, tension: 4)
                ),
                MoodOption(
                    imageName: "feel_calmer",
                    label: "Feel calmer",
                    color: Color(hex: "#A98AF8"),
                    impact: .init(stress: 7, energy: 5, focus: 4, calmness: 3, tension: 6)
                ),
                MoodOption(
                    imageName: "idk",
                    label: "I don't know",
                    color: Color(hex: "#B8BDC9"),
                    impact: .init(stress: 5, energy: 5, focus: 5, calmness: 5, tension: 5)
                ),
            ],
            weight: .init(stress: 1, energy: 1, focus: 1, calmness: 1, tension: 1)
        ),
    ]
}
