//
//  MoodModels.swift
//  Irene
//
//  Created by Anshuman Nitnaware on 21/07/26.
//

import FoundationModels
import Foundation

@Generable
struct LLMMoodQuestion {
    @Guide(description: "A short, warm question to gauge the user's current emotional/physical state, max 12 words, conversational tone")
    var question: String

    @Guide(description: "Exactly 4 short tappable answer options, each 1-4 words, mutually distinct")
    var options: [String]
}

@Generable
enum MoodCategory: String, CaseIterable, Sendable {
    case anxious
    case stressed
    case sad
    case tired
    case restless
    case overwhelmed
    case calm
    case energetic
}

@Generable
enum RecommendedDestination: String, Sendable {
    case boxBreathing
    case breathing478
    case acupressure
    case musicCalm
    case musicFocus
    case musicSleep
    case musicEnergy
}

@Generable
struct MoodAnalysis {
    @Guide(description: "The primary mood detected from the user's answers")
    var mood: MoodCategory

    @Guide(description: "The single best matching destination in the app for this mood")
    var destination: RecommendedDestination

    @Guide(description: "One warm sentence explaining the recommendation, max 20 words")
    var reasoning: String
}

struct MoodQA: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}
