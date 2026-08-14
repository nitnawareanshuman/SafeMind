//
//  MoodAIEngineProtocol.swift
//  Irene
//
//  Created by Anshuman Nitnaware on 21/07/26.
//


import FoundationModels

protocol MoodAIEngineProtocol {
    func checkAvailability() -> ModelAvailability
    func nextQuestion(history: [MoodQA]) async throws -> LLMMoodQuestion
    func analyze(history: [MoodQA]) async throws -> MoodAnalysis
}

enum ModelAvailability {
    case ready
    case notEnabled      // Apple Intelligence off in Settings
    case notEligible     // device doesn't support it
    case downloading     // model assets not ready yet
}

final class MoodAIEngine: MoodAIEngineProtocol {

    private let session: LanguageModelSession

    init() {
        session = LanguageModelSession(instructions: """
        You are a gentle wellness companion inside a meditation app called Irene.
        Your job is to ask short, caring check-in questions to understand how the user
        is feeling right now — physically and emotionally — then recommend one of these
        app destinations: boxBreathing, breathing478, acupressure, musicCalm, musicFocus,
        musicSleep, musicEnergy.

        Guidelines:
        - anxious/stressed/overwhelmed -> boxBreathing or breathing478
        - restless/tense body -> acupressure
        - sad/low -> musicCalm
        - tired -> musicSleep
        - needs focus -> musicFocus
        - low energy but wants to feel active -> musicEnergy
        - calm/energetic already -> musicEnergy or musicFocus

        Keep every question short, kind, and non-clinical. Never repeat a question already asked.
        """)
    }

    func checkAvailability() -> ModelAvailability {
        switch SystemLanguageModel.default.availability {
        case .available:
            return .ready
        case .unavailable(.appleIntelligenceNotEnabled):
            return .notEnabled
        case .unavailable(.deviceNotEligible):
            return .notEligible
        case .unavailable(.modelNotReady):
            return .downloading
        case .unavailable:
            return .notEligible
        }
    }

    func nextQuestion(history: [MoodQA]) async throws -> LLMMoodQuestion {
        let context = history.isEmpty
            ? "Ask the first check-in question."
            : "So far: " + history.map { "Q: \($0.question) A: \($0.answer)" }.joined(separator: " | ")
              + " Ask the next, different check-in question."

        let response = try await session.respond(to: context, generating: LLMMoodQuestion.self)
        return response.content
    }

    func analyze(history: [MoodQA]) async throws -> MoodAnalysis {
        let context = "Full check-in: " + history.map { "Q: \($0.question) A: \($0.answer)" }.joined(separator: " | ")
            + " Based on this, give final mood and destination recommendation."

        let response = try await session.respond(to: context, generating: MoodAnalysis.self)
        return response.content
    }
}

final class MockMoodAIEngine: MoodAIEngineProtocol {
    func checkAvailability() -> ModelAvailability { .ready }

    func nextQuestion(history: [MoodQA]) async throws -> LLMMoodQuestion {
        try await Task.sleep(nanoseconds: 400_000_000)
        let bank: [LLMMoodQuestion] = [
            LLMMoodQuestion(question: "How's your energy right now?", options: ["Wired", "Drained", "Steady", "Restless"]),
            LLMMoodQuestion(question: "What's on your mind most?", options: ["Deadlines", "Nothing much", "Someone", "Everything"])
        ]
        return bank[min(history.count, bank.count - 1)]
    }

    func analyze(history: [MoodQA]) async throws -> MoodAnalysis {
        try await Task.sleep(nanoseconds: 400_000_000)
        return MoodAnalysis(mood: .stressed, destination: .boxBreathing, reasoning: "You sound wound up — a few rounds of box breathing should help you settle.")
    }
}
