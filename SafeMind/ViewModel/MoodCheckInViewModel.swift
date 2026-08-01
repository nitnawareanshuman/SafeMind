//
//  MoodCheckInViewModel.swift
//  SafeMind
//
//  Part of the AI Mood Check-In feature.
//

import SwiftUI
import Combine

/// Drives the redesigned AI Mood Check-In flow: one full-screen question
/// "card" at a time (the exact card layout comes from `MoodQuestion.style`),
/// with an explicit tap-to-select + Skip/Next per card rather than an
/// auto-advancing chat. Once every question is answered (or skipped), it asks
/// `MoodAssessmentService` + `RecommendationEngine` to turn the answers into a
/// `MoodAssessment` and a single recommended activity.
///
/// Future extensibility: swap `questions` for a dynamically generated set
/// (e.g. LLM-driven, or personalized from history) without touching the View —
/// it only ever talks to `currentQuestion` / `select(_:)` / `advance()` / `skip()`.
@MainActor
final class MoodCheckInViewModel: ObservableObject {

    // MARK: - Published UI state

    @Published private(set) var currentQuestion: MoodQuestion?
    /// The option the user has tapped for the question currently on screen,
    /// but not yet confirmed with "Next". Cleared on every question change.
    @Published var pendingOption: MoodOption?
    @Published private(set) var isAnalyzing = false
    @Published private(set) var assessment: MoodAssessment?
    @Published private(set) var recommendation: MoodRecommendation?
    @Published private(set) var questionIndex = 0 // how many questions have been answered so far

    let totalQuestions: Int

    // MARK: - Dependencies

    private let questions: [MoodQuestion]
    private let assessmentService: MoodAssessmentService
    private let recommendationEngine: RecommendationEngine
    private let store: MoodCheckInStore

    private var answers: [(question: MoodQuestion, option: MoodOption)] = []

    init(
        questions: [MoodQuestion] = MoodQuestion.dailyCheckInQuestions,
        assessmentService: MoodAssessmentService = MoodAssessmentService(),
        recommendationEngine: RecommendationEngine = RecommendationEngine(),
        store: MoodCheckInStore = MoodCheckInStore()
    ) {
        self.questions = questions
        self.totalQuestions = questions.count
        self.assessmentService = assessmentService
        self.recommendationEngine = recommendationEngine
        self.store = store
    }

    // MARK: - Flow

    /// Shows the first card. Safe to call multiple times (e.g. `onAppear`
    /// firing again) — it no-ops once the flow has already started.
    func start() {
        guard currentQuestion == nil, assessment == nil, questionIndex == 0 else { return }
        currentQuestion = questions.first
    }

    /// Restarts the whole flow from scratch (used by "Start over").
    func reset() {
        currentQuestion = questions.first
        pendingOption = nil
        isAnalyzing = false
        assessment = nil
        recommendation = nil
        questionIndex = 0
        answers = []
    }

    /// Taps an option on the current card — just highlights it, doesn't advance.
    func select(_ option: MoodOption) {
        pendingOption = option
    }

    /// "Next" — commits whatever's selected (defaulting to the middle, most
    /// neutral option if nothing was tapped) and moves to the following card.
    func advance() {
        guard let question = currentQuestion else { return }
        let chosen = pendingOption ?? neutralOption(for: question)
        recordAnswer(question: question, option: chosen)
    }

    /// "Skip" — records the neutral/default option for this question (so it
    /// still contributes a mild, non-skewing signal) and moves on.
    func skip() {
        guard let question = currentQuestion else { return }
        recordAnswer(question: question, option: neutralOption(for: question))
    }

    private func neutralOption(for question: MoodQuestion) -> MoodOption {
        question.options[question.options.count / 2]
    }

    private func recordAnswer(question: MoodQuestion, option: MoodOption) {
        answers.append((question, option))
        pendingOption = nil
        questionIndex += 1
        askNextQuestion()
    }

    private func askNextQuestion() {
        guard questionIndex < questions.count else {
            currentQuestion = nil
            Task { await finish() }
            return
        }
        currentQuestion = questions[questionIndex]
    }

    private func finish() async {
        isAnalyzing = true

        // "Analyzing your responses…" gets a couple of seconds to breathe before revealing the result.
        try? await Task.sleep(nanoseconds: 1_600_000_000)

        let result = assessmentService.computeAssessment(from: answers)
        let rec = recommendationEngine.recommend(for: result)

        assessment = result
        recommendation = rec
        isAnalyzing = false

        store.saveTodaysResult(assessment: result, recommendation: rec)
    }

    // MARK: - Daily gate

    /// Whether today's check-in was already completed (checked once, up front,
    /// by whoever decides whether to present this flow at all — see `ContentView`).
    static func hasCompletedToday(store: MoodCheckInStore = MoodCheckInStore()) -> Bool {
        store.hasCompletedToday()
    }
}
